#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
set -e

RETRY=0
MAX_RETRIES=30
RETRY_SECONDS=10

until kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server healthcheck | grep -q 'Server is healthy'; do
    if [[ "$RETRY" -lt "$MAX_RETRIES" ]]; then
        RETRY="$((RETRY + 1))"
        echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
    else
        echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
        exit 1
    fi
    sleep "$RETRY_SECONDS"
done

if ! kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID spiffe://shasta/ncn/workload/cpsmount_helper | grep -q "spiffe://shasta/ncn/workload/cpsmount_helper"; then
    echo "Adding spiffe://shasta/ncn/workload/cpsmount_helper"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
        -parentID spiffe://shasta/ncn \
        -spiffeID spiffe://shasta/ncn/workload/cpsmount_helper \
        -selector unix:uid:0 \
        -selector unix:gid:0 \
        -selector unix:path:/opt/cray/cps-utils/bin/cpsmount_helper
else
    echo "spiffe://shasta/ncn/workload/cpsmount_helper already exists. Not adding."

fi

if ! kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID spiffe://shasta/compute/workload/cpsmount_helper | grep -q "spiffe://shasta/compute/workload/cpsmount_helper"; then
    echo "Adding spiffe://shasta/compute/workload/cpsmount_helper"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
        -parentID spiffe://shasta/compute \
        -spiffeID spiffe://shasta/compute/workload/cpsmount_helper \
        -selector unix:uid:0 \
        -selector unix:gid:0 \
        -selector unix:path:/opt/cray/cps-utils/bin/cpsmount_helper
else
    echo "spiffe://shasta/compute/workload/cpsmount_helper already exists. Not adding."
fi

if ! kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "spiffe://shasta/compute/workload/ckdump_helper" | grep -q "spiffe://shasta/compute/workload/ckdump_helper"; then
    echo "Adding spiffe://shasta/compute/workload/ckdump_helper"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
        -parentID spiffe://shasta/compute \
        -spiffeID spiffe://shasta/compute/workload/ckdump_helper \
        -selector unix:uid:0 \
        -selector unix:gid:0 \
        -selector unix:path:/usr/sbin/ckdump_helper
else
    echo "spiffe://shasta/compute/workload/ckdump_helper already exists. Not adding."
fi

if kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "spiffe://shasta/compute/workload/dvs-get-comp" | grep -q "spiffe://shasta/compute/workload/dvs-get-comp"; then
    echo "Deleting spiffe://shasta/compute/workload/dvs-get-comp"
    entryid="$(kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID spiffe://shasta/compute/workload/dvs-get-comp | grep "Entry ID" | awk '{print $4}')"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry delete --entryID "$entryid"
else
  echo "spiffe://shasta/compute/workload/dvs-get-comp does not exist. Not deleting."
fi

if kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID "spiffe://shasta/ncn/workload/dvs-get-comp" | grep -q "spiffe://shasta/ncn/workload/dvs-get-comp"; then
    echo "Deleting spiffe://shasta/ncn/workload/dvs-get-comp"
    entryid="$(kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID spiffe://shasta/ncn/workload/dvs-get-comp | grep "Entry ID" | awk '{print $4}')"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry delete --entryID "$entryid"
else
  echo "spiffe://shasta/ncn/workload/dvs-get-comp does not exist. Not deleting."
fi
