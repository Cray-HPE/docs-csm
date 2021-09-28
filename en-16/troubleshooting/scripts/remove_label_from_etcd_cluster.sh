#!/bin/sh
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

usage() {
  echo "
Usage:

$0 <namespace> <etcd-cluster>

    <namespace>    - The Kubernetes namespace the etcd cluster pods are running in.
                     Example, 'services'.
    <etcd-cluster> - The base name of the etcd cluster pods. Example, 'cray-hmnfd'.
"
}

# Print usage if there are less than two args
if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi

ns=$1
cluster=$2
ss_name="${cluster}-bitnami-etcd"
label_key="app.kubernetes.io/component"
label_value="etcd"
label="${label_key}=${label_value}"

if ! kubectl get endpoints ${cluster}-etcd-client -n ${ns} -o json > /dev/null 2>&1; then
  #
  # There is no old etcd-operator managed chart installed, let's see if this
  # is a fresh install or upgrade with new label.
  #
  has_label=$(kubectl get statefulsets.apps -n ${ns} -l ${label} --no-headers 2> /dev/null | awk "/${ss_name}/")
  if [ -z "$has_label" ]; then
    #
    # The new label has not been applied, so no need to delete label before rollback.
    #
    echo "The '${label}' label has already been removed from ${ss_name}, continue with rollback."
    exit 0
  fi

  #
  # The new label has been applied, so we need to remove the label from the pods and
  # the statefulset before rolling back.
  #
  members=$(kubectl get pod -n $ns -o wide -o=custom-columns=NAME:.metadata.name | awk "/${ss_name}/ && !/snapshotter|defrag/")
  if [ -n "$members" ]; then
    echo "Ensuring ${ss_name} members do not have '${label}' label for rollback to bitnami 8.x chart..."
    for member in ${members}; do
      echo "Removing '${label}' label from ${member}..."
      kubectl label pod -n ${ns} ${member} ${label_key}-
    done
    echo "Removing label '${label}' from statefulset for ${ss_name}"
    kubectl label statefulset -n ${ns} ${ss_name} ${label_key}-
    echo "Label '${label}' was removed from pods and '${ss_name}' statefulset. Continue with rollback."
  else
    echo "No installations detected requiring special handling, continue with rollback."
  fi
  exit 0
fi

echo "Nothing to do. Found ${cluster}-etcd-client, so an older version without the ${label} label is already running."
