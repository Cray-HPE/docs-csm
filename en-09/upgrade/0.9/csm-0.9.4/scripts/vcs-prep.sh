#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

DATA_CLAIM="gitea-vcs-data-claim"

DELETING=$(kubectl -n services get pvc $DATA_CLAIM -o json  | jq -r '.metadata.deletionTimestamp')
if [ $? -ne 0 ]; then
    echo "Error getting pvc status. If the pvc does not exist this step can be skipped."
    exit 1
fi

MODE=$(kubectl -n services get pvc $DATA_CLAIM -o json  | jq -r '.status.accessModes[0]')
if [ $MODE = "ReadWriteMany" ] && [ $DELETING = null ]; then
    echo "The pvc is already deployed correctly. No further action is needed for this step."
    exit 0
fi

echo "Terminating the current pvc."
kubectl -n services delete pvc $DATA_CLAIM --wait=false
kubectl -n services rollout restart deployment gitea-vcs
while kubectl -n services get pvc $DATA_CLAIM 2> /dev/null;
do
    echo "Waiting for pvc to be deleted."
    sleep 1;
done
echo "pvc has successfully been deleted."
