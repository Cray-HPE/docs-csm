#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

echo "The following deployments/statefulsets are cephfs clients and will be unavailable during initial Ceph upgrade:"
echo ""

client_list=$(kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName=="ceph-cephfs-external") | .metadata.namespace, .metadata.name')
client_array=( $client_list )
array_length=${#client_array[@]}
while [[ "$cnt" -lt "$array_length" ]]; do
  ns="${client_array[$cnt]}"
  cnt=$((cnt+1))
  pvc_name="${client_array[$cnt]}"
  cnt=$((cnt+1))
  for deployment in $(kubectl get deployment -n $ns -o json | jq -r '.items[].metadata.name'); do
    kubectl get deployment -n $ns $deployment -o yaml | grep -q "claimName: $pvc_name"
    if [[ "$?" -eq 0 ]]; then
      echo "  Deployment: $deployment in $ns namespace (pvc: $pvc_name)"
    fi
  done
  for statefulset in $(kubectl get statefulset -n $ns -o json | jq -r '.items[].metadata.name'); do
    kubectl get statefulset -n $ns $statefulset -o yaml | grep -q "claimName: $pvc_name"
    if [[ "$?" -eq 0 ]]; then
      echo "  Statefulset: $statefulset in $ns namespace (pvc: $pvc_name)"
    fi
  done
done
echo ""
