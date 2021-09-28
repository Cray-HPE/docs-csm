#!/bin/bash

# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# When upgrading from Istio 1.11.8 to 1.19.10 we need to rollout-restart because
# the istio-injection enabled namespaces doesn't get the latest image of istio.
#

set -x

# This part of script is to delete the pods on vault namespace which do not have proxyv2:1.19.10
# This is done because the vault is not updated in CSM1.6, this restart of vault may not be needed in future

NAMESPACE="vault"
CORRECT_VERSION="proxyv2:1.19.10"
pods_deleted=false

# Get all pods in the namespace
pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

# Loop through each pod
for pod in $pods; do
  echo "Checking pod: $pod"

  # Get the image version of proxyv2 container in the pod
  image=$(kubectl get pod "$pod" -n $NAMESPACE -o jsonpath='{.spec.containers[*].image}')

  # If the image version is not correct, delete the pod
  if [[ $image != *"$CORRECT_VERSION"* ]]; then
    echo "Deleting pod: $pod (Incorrect proxyv2 version: $image)"
    kubectl delete pod "$pod" -n "$NAMESPACE" --grace-period=0 --force
    pods_deleted=true
  else
    echo "Pod $pod has the correct proxyv2 version: $image"
  fi
done

# Wait for 2 minutes if any pods were deleted
if [ "$pods_deleted" = true ]; then
  echo "Waiting for 2 minutes for pods to restart..."
  sleep 120

  # Check the status of the pods after restart
  new_pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

  echo "Checking the status of new pods..."
  echo "$new_pods"

  # Check if all pods are in Running state and have the correct proxyv2 version
  all_correct=true
  for pod in $new_pods; do
    status=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    image=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].image}')

    if [[ $status != "Running" ]]; then
      echo "Pod $pod is not in Running state. Current state: $status"
      all_correct=false
    fi

    if [[ $image != *"$CORRECT_VERSION"* ]]; then
      echo "Pod $pod does not have the correct proxyv2 version. Current version: $image"
      all_correct=false
    fi
  done

  if [ "$all_correct" = true ]; then
    echo "All pods are running with the correct proxyv2 version."
  else
    echo "Some pods are not running or do not have the correct proxyv2 version."
  fi
else
  echo "No pods were deleted. Skipping wait."
fi

# The fuctionality of the script is:
# This script is to restart the vault pods separately.
# Because vault was not upgraded in this release that is why we need this script.
# Get all istio-injection=enabled namespaces.
# For each namespace we are keeping the record of the sts/deploys/ds which we need to restart by following way:
#   Get all the pods in the namespace, and check istio image version.
#   if image is not in 1.19.10 then
#       Keep the name of the corresponding ds/sts/deploy in a list.
#   Else move to another pod.
# After iterating over all the namespaces we will have the list of sts/ds/deploys that needs to be restarted.
# We will restart the resources from the list that we have made in above steps.
# We will wait for 2-3 mins and check the rollout status for the resources.

# Function to check if any container in a pod has the latest Istio image version
check_pod_istio_versions() {
  local namespace=$1
  local pod=$2
  local images
  images=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath="{.spec.containers[*].image}")

  # Check if any of the images is the latest Istio version
  if echo "$images" | grep -q -e "istio/pilot:1.19.10" -e "istio/proxyv2:1.19.10"; then
    return 0 # Pod has the latest Istio versions
  else
    return 1 # Pod does not have the latest Istio versions
  fi
}

# Function to determine the controlling resource of a pod
get_controlling_resource() {
  local namespace=$1
  local pod=$2
  owner_references=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath="{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}")
  echo "$owner_references"
}

# Function to check if a pod uses the Istio proxy
check_pod_uses_istio_proxy() {
  local namespace=$1
  local pod=$2
  local containers
  containers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath="{.spec.containers[*].name}")

  if echo "$containers" | grep -q "istio-proxy"; then
    return 0 # Pod uses Istio proxy
  else
    return 1 # Pod does not use Istio proxy
  fi
}

# Function to perform rollout restart and check status for a given resource
restart_and_check_status() {
  local namespace=$1
  shift
  local resources=("$@")

  resolve_deployment() {
    local resource_type=$1
    local resource_name=$2
    if [[ $resource_type == "ReplicaSet" ]]; then
      deployment=$(kubectl get replicasets "$resource_name" -n "$namespace" -o jsonpath="{.metadata.ownerReferences[0].name}")
      if [[ -n $deployment ]]; then
        resource_type="Deployment"
        resource_name=$deployment
      else
        echo "No corresponding Deployment found for ReplicaSet $resource_name"
        return 1
      fi
    fi
    echo "$resource_type/$resource_name"
  }

  for resource in "${resources[@]}"; do
    resource_type=$(echo "$resource" | cut -d'/' -f1)
    resource_name=$(echo "$resource" | cut -d'/' -f2)

    resolved_resource=$(resolve_deployment "$resource_type" "$resource_name")
    if [[ $? -eq 0 ]]; then
      echo "Rolling out restart for $resolved_resource in namespace: $namespace"
      kubectl rollout restart "$resolved_resource" -n "$namespace"
    fi
  done

  echo "Waiting for 3 minutes..."
  sleep 180

  for resource in "${resources[@]}"; do
    resource_type=$(echo "$resource" | cut -d'/' -f1)
    resource_name=$(echo "$resource" | cut -d'/' -f2)

    if [ "$resource_name" = "cray-dvs-mqtt-ss" ]; then
      # CASMTRIAGE-7260: skip it as its second replicaSet will stay in the "1/2 Running" state (instead of "2/2 Running")
      continue
    fi

    resolved_resource=$(resolve_deployment "$resource_type" "$resource_name")
    if [[ $? -eq 0 ]]; then
      echo "Checking rollout status for $resolved_resource in namespace: $namespace"
      kubectl rollout status "$resolved_resource" -n "$namespace"
    fi
  done
}

# Get all namespaces
namespaces=$(kubectl get namespaces -l istio-injection=enabled -o jsonpath="{.items[*].metadata.name}")

# Initialize an associative array to keep track of resources to restart
declare -A resources_to_restart

# Loop through each namespace
for ns in $namespaces; do
  echo "Checking namespace: $ns"
  pods=$(kubectl get pods -n "$ns" -o jsonpath="{.items[*].metadata.name}")

  for pod in $pods; do
    if ! check_pod_istio_versions "$ns" "$pod"; then
      echo "Pod $pod in namespace $ns does not have the latest Istio version. Checking its controlling resource..."
      controlling_resource=$(get_controlling_resource "$ns" "$pod")

      # Extract resource type and name from controlling_resource
      if [[ $controlling_resource =~ ^(Deployment|StatefulSet|DaemonSet|ReplicaSet)/(.+)$ ]]; then
        resource_type=${BASH_REMATCH[1]}
        resource_name=${BASH_REMATCH[2]}

        # Check if the resource uses Istio proxy
        if check_pod_uses_istio_proxy "$ns" "$pod"; then
          resource_key="$ns/$resource_type/$resource_name"
          resources_to_restart["$resource_key"]=$resource_type
        else
          echo "Pod $pod does not use Istio proxy. Skipping restart for its controlling resource."
        fi
      else
        echo "Skipping unknown or unhandled resource type: $controlling_resource for pod $pod"
      fi
    else
      echo "Pod $pod in namespace $ns already has the latest Istio image versions"
    fi
  done
done

# Print the list of resources to restart
echo "Resources to restart:"
for resource_key in "${!resources_to_restart[@]}"; do
  echo "$resource_key"
done

# Restart resources at the end
declare -A namespace_resources

for resource_key in "${!resources_to_restart[@]}"; do
  namespace=$(echo "$resource_key" | cut -d'/' -f1)
  resource_type=$(echo "$resource_key" | cut -d'/' -f2)
  resource_name=$(echo "$resource_key" | cut -d'/' -f3)

  namespace_resources["$namespace"]+="$resource_type/$resource_name "
done

for namespace in "${!namespace_resources[@]}"; do
  IFS=' ' read -r -a resources <<< "${namespace_resources[$namespace]}"
  restart_and_check_status "$namespace" "${resources[@]}"
done
