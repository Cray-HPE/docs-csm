#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

echo "Reconfiguring cray-sysmgmt-health-promet-kubelet servicemonitor"
mfile=/tmp/cray-sysmgmt-health-promet-kubelet.yaml
kubectl get servicemonitors.monitoring.coreos.com -n sysmgmt-health cray-sysmgmt-health-promet-kubelet -o yaml > $mfile
yq w -i $mfile 'spec.endpoints.(path==/metrics/resource).port' 10255
yq w -i $mfile 'spec.endpoints.(path==/metrics/resource).scheme' http
sed -i 's/10255/"10255"/' $mfile
kubectl -n sysmgmt-health apply -f $mfile
