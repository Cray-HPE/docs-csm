#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
set -euo pipefail
basedir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function main() {
    upload_worker_rebuild_template
    upload_worker_rebuild_hooks
    upload_storage_rebuild_template
    upload_iuf_install_template
}

function upload_iuf_install_template {
    kubectl -n argo delete configmap iuf-install-workflow-files || true
    kubectl -n argo create configmap iuf-install-workflow-files --from-file="${basedir}/../iuf"
    kubectl -n argo delete configmap iuf-install-workflow-stages-files || true
    kubectl -n argo create configmap iuf-install-workflow-stages-files --from-file="${basedir}/../iuf/stages.yaml"
    kubectl -n argo apply -f "${basedir}/../iuf/operations" --recursive
}

function upload_worker_rebuild_template {
    kubectl -n argo delete configmap worker-rebuild-workflow-files || true
    kubectl -n argo create configmap worker-rebuild-workflow-files --from-file="${basedir}/../ncn/worker"
}

function upload_worker_rebuild_hooks {
    kubectl -n argo apply -f "${basedir}/../ncn/hooks" --recursive
}

function upload_storage_rebuild_template {
    kubectl -n argo delete configmap storage-rebuild-workflow-files || true
    kubectl -n argo create configmap storage-rebuild-workflow-files --from-file="${basedir}/../ncn/storage"
}

main
# shellcheck disable=SC2046
kubectl -n argo annotate --overwrite pods \
    $(kubectl get pods -l app.kubernetes.io/name=cray-nls -n argo -o json | jq -r '.items[] | .metadata.name') updated="$(date +%s)"