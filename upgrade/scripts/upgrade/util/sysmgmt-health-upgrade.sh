#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2024 Hewlett Packard Enterprise Development LP
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

# Function to check cray-sysmgmt-health chart with app version 45.1 for kube-prometheus-stack and delete old PVCs.

function sysmgmt_health() {
  echo "Checking for chart version of cray-sysmgmt-health"
  version="45.1"
  if [ "$(helm ls -o json --namespace sysmgmt-health | jq -r --argjson version $version '.[] | select(.app_version | sub(".[0-9]$";"") | tonumber | . = $version).name')" ]; then
    prom0_pvc="prometheus-cray-sysmgmt-health-kube-p-prom-db-prometheus-cray-sysmgmt-health-kube-p-prom-0"
    prom1_pvc="prometheus-cray-sysmgmt-health-kube-p-prom-db-prometheus-cray-sysmgmt-health-kube-p-prom-1"
    prom0_shard_pvc="prometheus-cray-sysmgmt-health-kube-p-prom-db-prometheus-cray-sysmgmt-health-kube-p-prom-shard-1-0"
    prom1_shard_pvc="prometheus-cray-sysmgmt-health-kube-p-prom-db-prometheus-cray-sysmgmt-health-kube-p-prom-shard-1-1"
    alert_pvc="alertmanager-cray-sysmgmt-health-kube-p-alertmanager-db-alertmanager-cray-sysmgmt-health-kube-p-alertmanager-0"
    thanos_ruler_pvc="thanos-ruler-kube-prometheus-stack-thanos-ruler-data-thanos-ruler-kube-prometheus-stack-thanos-ruler-0"

    # Uninstall the cray-sysmgmt-health and delete PVCs
    helm ls -o json --namespace sysmgmt-health | jq -r --argjson version $version '.[] | select(.app_version | sub(".[0-9]$";"") | tonumber | . = $version).name' | xargs -L1 helm uninstall --namespace sysmgmt-health

    kubectl delete pvc/$prom0_pvc -n sysmgmt-health
    kubectl delete pvc/$prom1_pvc -n sysmgmt-health
    kubectl delete pvc/$prom0_shard_pvc -n sysmgmt-health
    kubectl delete pvc/$prom1_shard_pvc -n sysmgmt-health
    kubectl delete pvc/$alert_pvc -n sysmgmt-health
    kubectl delete pvc/$thanos_ruler_pvc -n sysmgmt-health

    # Remove the cray-sysmgmt-health-promet-kubelet service.
    echo "Deleting cray-sysmgmt-health-kube-p-kubelet service in kube-system namespace."
    kubectl delete service/cray-sysmgmt-health-kube-p-kubelet -n kube-system

    # Remove all the existing CRDs (ServiceMonitors, Podmonitors, etc.)
    echo "Deleting sysmgmt-health existing CRDs"
    for c in $(kubectl get crds -A -o jsonpath='{range .items[?(@.metadata.annotations.controller-gen\.kubebuilder\.io\/version=="v0.2.4")]}{.metadata.name}{"\n"}{end}'); do
      kubectl delete crd ${c}
    done
  fi
}

# sysmgmt_health function call
sysmgmt_health
