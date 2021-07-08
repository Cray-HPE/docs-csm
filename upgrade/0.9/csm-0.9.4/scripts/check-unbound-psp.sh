#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -exo pipefail

# Check for manually create unbound PSP that is not managed by helm

echo "Checking for manually created cray-dns-unbound-psp"
unbound_psp_exist="$(kubectl get ClusterRoleBinding -n services |grep cray-dns-unbound-psp|wc -l)"||true
unbound_psp_helm_check="$(kubectl get ClusterRoleBinding -n services cray-dns-unbound-psp -o yaml |grep helm |wc -l)"||true
if [[ "$unbound_psp_helm_check" -eq "0" ]] && [[ "$unbound_psp_exist" -eq "1" ]]; then
    echo "Found ClusterRoleBinding cray-dns-unbound-psp NOT managed by helm"
    kubectl delete ClusterRoleBinding -n services cray-dns-unbound-psp
    echo "Delete ClusterRoleBinding cray-dns-unbound-psp"
fi
echo "cray-dns-unbound-psp check Done"