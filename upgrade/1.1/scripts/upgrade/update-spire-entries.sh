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

if ! kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry show -spiffeID spiffe://shasta/storage/workload/cfs-state-reporter | grep -q "spiffe://shasta/storage/workload/cfs-state-reporter"; then
    echo "Adding spiffe://shasta/storage/workload/cfs-state-reporter"
    kubectl exec -n spire spire-server-0 --container spire-server -- ./bin/spire-server entry create \
        -parentID spiffe://shasta/storage \
        -spiffeID spiffe://shasta/storage/workload/cfs-state-reporter \
        -selector unix:uid:0 \
        -selector unix:gid:0 \
        -selector unix:path:/usr/bin/cfs-state-reporter-spire-agent
else
    echo "spiffe://shasta/storage/workload/cfs-state-reporter already exists. Not adding."

fi
