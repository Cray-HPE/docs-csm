#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
kubectl -n services exec ${POD} -- tar -cvf vcs.tar /data/
kubectl -n services cp ${POD}:vcs.tar ./vcs.tar
