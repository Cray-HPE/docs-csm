#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

# Check vcs pvc state before restoring:
DELETING=$(kubectl -n services get pvc gitea-vcs-data-claim -o json  | jq -r '.metadata.deletionTimestamp')
if [ $? -ne 0 ]; then
    echo "Error getting pvc status."
    exit 1
fi
if [ $DELETING != null ]; then
    echo "Error: The pvc is still in a deleting state."
    exit 1
fi

MODE=$(kubectl -n services get pvc gitea-vcs-data-claim -o json  | jq -r '.status.accessModes[0]')
if [ $MODE != "ReadWriteMany" ]; then
    echo "Error: The pvc does not have the correct access mode."
    exit 1
fi
echo "The pvc is in the expected state."

# If the pvc is in the correct state, restore from the vcs.tar file
if [ ! -f ./vcs.tar ]; then
    echo "vcs.tar file not found!"
    exit 1
fi

POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
kubectl -n services cp ./vcs.tar ${POD}:vcs.tar
kubectl -n services exec ${POD} -- tar -xvf vcs.tar

PV=$(kubectl -n services get pvc gitea-vcs-data-claim -o json  | jq -r '.spec.volumeName')
kubectl patch pv $PV -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

kubectl -n services rollout restart deployment gitea-vcs
