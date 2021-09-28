#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
# This script removes old kafka CRD versions from the storedVersions
# so that an upgrade of the CRDs will succeed.

trap 'delete_auth' EXIT

delete_auth() {
  kubectl delete --ignore-not-found clusterrolebinding crd-update-binding
  kubectl delete --ignore-not-found clusterrole crd-update-access
  kubectl delete --ignore-not-found serviceaccount crd-updater
}

e() {
  CERTS="--cacert /etc/kubernetes/pki/etcd/ca.crt"
  CERTS="${CERTS} --cert /etc/kubernetes/pki/etcd/peer.crt"
  CERTS="${CERTS} --key /etc/kubernetes/pki/etcd/peer.key"
  ETCDCTL_API=3 etcdctl ${CERTS} "$@"
}

fix_resource() {
  resource=$1

  echo "Updating apiVersion in ${resource} v1beta1 -> v1beta2"
  e get --print-value-only "${resource}" \
    | sed 's;kafka.strimzi.io/v1beta1;kafka.strimzi.io/v1beta2;' \
    | e put "${resource}"
}

fix_strimzi_resources_in_etcd() {
  echo
  echo "Fixing strimzi resource versions in etcd"
  echo
  KAFKAS=$(e get /registry/kafka.strimzi.io/kafkas --prefix --keys-only)
  KAFKATOPICS=$(e get /registry/kafka.strimzi.io/kafkatopics --prefix --keys-only)
  echo "KAFKAS=${KAFKAS}"
  echo "KAFKATOPICS=${KAFKATOPICS}"
  for key in ${KAFKAS} ${KAFKATOPICS}; do
    api_version=$(e get --print-value-only "${key}" | jq -r '.apiVersion')
    case "${api_version}" in
      kafka.strimzi.io/v1beta1)
        fix_resource "${key}"
        ;;
      kafka.strimzi.io/v1beta2)
        echo "Okay: ${key}"
        ;;
      *)
        echo "Unknown API version: ${key}: ${api_version}"
        ;;
    esac
  done
}

create_auth() {
  kubectl apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: crd-updater
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crd-update-access
rules:
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    verbs: ["get", "list", "watch","update","patch"]
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions/status"]
    verbs: ["get", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crd-update-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: crd-update-access
subjects:
  - kind: ServiceAccount
    name: crd-updater
    namespace: default
EOF
}

have_old_kakfa_crd() {
  have_old_crd_version=false

  for crd in $(kubectl get crds -l app=strimzi -o jsonpath='{.items[*].metadata.name}'); do
    if [ "${crd}" = kafkatopics.kafka.strimzi.io ] || [ "${crd}" = kafkausers.kafka.strimzi.io ]; then
      echo "${crd}: okay"
      continue
    fi

    stored_versions=$(kubectl get crd "${crd}" -o jsonpath='{.status.storedVersions[*]}')
    old_stored_versions=""
    for version in ${stored_versions}; do
      # Check if "v1alpha1" or "v1beta1" are present as part of storedVersions
      if [ "${version}" != "v1beta2" ]; then
        old_stored_versions="${old_stored_versions},${version}"
      fi
    done
    if [ "${old_stored_versions}" != "" ]; then
      echo "old version present in ${crd} storedVersions: ${old_stored_versions#,}"
      have_old_crd_version=true
    else
      echo "${crd}: okay"
    fi
  done
  if ${have_old_crd_version}; then
    return 0
  fi
  return 1
}

update_storage_fields() {
  echo
  echo "Updating storage fields for strimzi CRDs"
  echo
  strimzi_kafka_crd_list=$(kubectl get crds -l app=strimzi -o jsonpath='{.items[*].metadata.name}')

  # Update the "storage" fields to true for v1beta2 version and false to other versions
  # Update the "served" field to true for v1beta2
  for crd in ${strimzi_kafka_crd_list}; do
    crd_json=$(kubectl get crd "${crd}" -o json)
    modified_spec=$(echo "${crd_json}" | jq '
      (.spec.versions) |= map(
        if .name == "v1beta2" then
          .storage = true | .served = true
        else
          .storage = false
        end
      )
    ')
    echo "Replacing CRD ${crd}"
    if echo "${modified_spec}" | kubectl replace --raw "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/${crd}" -f - > /dev/null; then
      echo "Successfully replaced ${crd}"
    else
      echo "Failed to replace ${crd}"
    fi
  done
}

remove_old_crd_versions() {
  echo
  echo "Removing older versions from strimzi CRDs"
  echo
  strimzi_kafka_crd_list=$(kubectl get crds -l app=strimzi -o jsonpath='{.items[*].metadata.name}')

  # Grab the Kubernetes API server URL from your current kubeconfig
  apiserver=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
  echo "Using API Server: ${apiserver}"

  # Get the service account token from crd-updater
  secret_name=$(kubectl get sa crd-updater -n default -o jsonpath='{.secrets[0].name}')
  token=$(kubectl get secret "${secret_name}" -n default -o jsonpath='{.data.token}' | base64 -d)

  for crd in ${strimzi_kafka_crd_list}; do
    if [ "${crd}" = kafkatopics.kafka.strimzi.io ] || [ "${crd}" = kafkausers.kafka.strimzi.io ]; then
      echo "Skipping CRD: ${crd}"
      continue
    fi

    echo "Processing CRD: ${crd}"

    # Patch status.storedVersions to only include v1beta2
    echo "Patching CRD ${crd} status..."
    if ! curl -s -o /dev/null --cacert /etc/kubernetes/pki/ca.crt -X PATCH \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/merge-patch+json" \
      "${apiserver}/apis/apiextensions.k8s.io/v1/customresourcedefinitions/${crd}/status" \
      -d '{"status": {"storedVersions": ["v1beta2"]}}'; then
      echo "Failed to patch CRD ${crd} status"
    fi

    crd_json=$(kubectl get crd "${crd}" -o json)

    # Remove all versions except v1beta2 from spec.versions
    modified_spec=$(echo "${crd_json}" | jq '
      .spec.versions |= map(select(.name == "v1beta2"))
    ')

    # Replace the CRD spec
    echo "Replacing CRD ${crd}"
    if echo "${modified_spec}" | kubectl replace --raw "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/${crd}" -f - > /dev/null; then
      echo "CRD ${crd} updated successfully"
    else
      echo "Failed to update CRD ${crd}"
    fi
  done
}

cleanup() {
  # Remove last-applied-configuration in annotations and also preserveUnknownFields field in spec
  CRDS=$(kubectl get crds -lapp=strimzi -o jsonpath='{.items[*].metadata.name}')

  cat << EOF
Removing
    metadata.annotations.last-applied-configuration
    spec.preserveUnknownFields
from kafka CRDs
EOF

  for crd in ${CRDS}; do
    kubectl patch --type merge crd ${crd} -p '{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration": null}},"spec":{"preserveUnknownFields": null}}'
  done
}

echo "Checking for old versions in Strimzi kafka CRDs"
if have_old_kakfa_crd; then
  create_auth
  update_storage_fields
  fix_strimzi_resources_in_etcd
  remove_old_crd_versions
  cleanup
fi
