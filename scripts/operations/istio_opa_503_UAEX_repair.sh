#!/bin/bash
#
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

# This script adjusts a few settings to work around 503 UAEX errors caused by OPA for CSM 1.4.x
set -euo pipefail

# Ensure istio ingressgateway HPA has minReplicas set to number of worker nodes (up to 8)
num_workers=$(kubectl get nodes | grep ncn-w | wc -l)
if [ $num_workers -lt 9 ]; then
  minIstioPods=$num_workers
else
  minIstioPods=8
fi
echo "Setting istio ingressgateway HPA minReplicas to $minIstioPods"
kubectl -n istio-system patch hpa istio-ingressgateway --patch '{"spec":{"maxReplicas":'$num_workers', "minReplicas":'$minIstioPods'}}'

# Ensure OPA ingressgateway memory limit is set to 800Mi
ORIG=$(kubectl get deployment cray-opa-ingressgateway -n opa -ojson | jq '.spec.template.spec.containers[0].resources.limits.memory')
echo "Original memory limit for cray-opa-ingressgateway deployment: $ORIG"
echo "Changing it to be 800Mi..."
kubectl patch deploy cray-opa-ingressgateway -n opa --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value":"800Mi"}]'
kubectl patch deploy cray-opa-ingressgateway -n opa --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value":"800Mi"}]'

# Ensure OPA ingressgateway pod runs on each worker node
num_opa=$(kubectl get pods -n opa -l app.kubernetes.io/name=cray-opa-ingressgateway | grep Running | wc -l)
if [ $num_opa -lt $num_workers ]; then
  echo "Number of OPA ingressgateway pods: $num_opa is less than number of worker nodes: $num_workers."
  echo "Scaling down and up OPA ingressgateway deployment to match number of worker nodes..."
  kubectl scale deployment cray-opa-ingressgateway -n opa --replicas=1
  sleep 5
  kubectl scale deployment cray-opa-ingressgateway -n opa --replicas=$num_workers
  sleep 5
  # Wait up to 30 seconds for all pods to be ready but ignore the failure as the check is not always reliable
  set +e
  kubectl wait --for=condition=ready pod -n opa -l app.kubernetes.io/name=cray-opa-ingressgateway --timeout=30s
  set -e
else
  echo "OPA ingressgateway pod is already running on each worker node."
fi

echo "Done."
