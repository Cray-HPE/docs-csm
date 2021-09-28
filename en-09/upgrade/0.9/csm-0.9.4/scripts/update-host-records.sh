#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

# Get list of ncn workers
ncn_workers=$(kubectl get nodes|grep "ncn-w"|awk '{ print $1 }')

# Get ip of nmn istio ingress
ip=$(dig api-gw-service-nmn.local +short)

# create entry for /etc/hosts
entry="$ip packages.local registry.local"

# Check for existing records and remove entries

for host in $ncn_workers; do
    # Check for existing records and remove entries
    packages_count=$(pdsh -w $host cat /etc/hosts | { grep packages.local || true; } | wc -l)
    registry_count=$(pdsh -w $host cat /etc/hosts | { grep registry.local || true; } | wc -l)
    if [[ "$packages_count" -gt "0" ]];then
        pdsh -w $host "sed -i '/packages.local/d' /etc/hosts"
    fi
    if [[ "$registry_count" -gt "0" ]]; then
        pdsh -w $host "sed -i '/registry.local/d' /etc/hosts"
    fi
    # Add host record
    pdsh -w $host "echo $entry >> /etc/hosts"
done
