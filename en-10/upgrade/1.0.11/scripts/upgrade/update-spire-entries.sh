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
