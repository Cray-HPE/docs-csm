#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
kubectl -n services cp ./vcs.tar ${POD}:vcs.tar
kubectl -n services exec ${POD} -- tar -xvf vcs.tar

PV=$(kubectl -n services get pvc gitea-vcs-data-claim -o json  | jq -r '.spec.volumeName')
kubectl patch pv $PV -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl -n services rollout restart deployment gitea-vcs
