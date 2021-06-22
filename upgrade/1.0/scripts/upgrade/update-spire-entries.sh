#!/bin/bash
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
        -parentID spiffe://shasta/ncn \
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
        -parentID spiffe://shasta/ncn \
        -spiffeID spiffe://shasta/compute/workload/ckdump_helper \
        -selector unix:uid:0 \
        -selector unix:gid:0 \
        -selector unix:path:/usr/sbin/ckdump_helper
else
    echo "spiffe://shasta/compute/workload/ckdump_helper already exists. Not adding."
fi
