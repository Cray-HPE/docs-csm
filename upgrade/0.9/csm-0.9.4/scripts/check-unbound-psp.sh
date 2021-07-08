#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -exo pipefail

# Check for manually create unbound PSP that is not managed by helm

echo "Checking for manually created cray-dns-unbound-psp"
unbound_psp="$(kubectl get ClusterRoleBinding -n services cray-dns-unbound-psp -o yaml |grep helm |wc -l)"||true
if [[ "$unbound_psp" -eq "0" ]]; then
    echo "Found ClusterRoleBinding cray-dns-unbound-psp NOT managed by helm"
    kubectl delete ClusterRoleBinding -n services cray-dns-unbound-psp
    echo "Delete ClusterRoleBinding cray-dns-unbound-psp"
fi
echo "cray-dns-unbound-psp check Done"
