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

. "${basedir}"/../../lib/lib.sh

trap libcleanup EXIT

JQFN=printjqoutputonok
JQTESTFAILFN=exitonjqtestfailure

function main() {
    upload_worker_rebuild_template
    upload_storage_rebuild_template

    #shellcheck disable=SC2086
    tmpfile=$(libtmpfile "$(basename $0)")
    kubectl get pods -l app.kubernetes.io/name=cray-nls -n argo -o json > "${tmpfile}"

    # More shellcheck nonsense about quotes for the variable that never go away
    # with quotes and isn't valid anyway.
    #shellcheck disable=SC2086
    # REVIEW: I presume we bail here from jq not reading things if it isn't json
    kubectl -n argo annotate --overwrite pods "$(jq -r '.items[] | .metadata.name' ${tmpfile})" \
            updated="$(date +%s)"
}

function upload_worker_rebuild_template {
    kubectl -n argo delete configmap worker-rebuild-workflow-files || true
    kubectl -n argo create configmap worker-rebuild-workflow-files --from-file="${basedir}/../ncn/worker"
}

function upload_storage_rebuild_template {
    kubectl -n argo delete configmap storage-rebuild-workflow-files || true
    kubectl -n argo create configmap storage-rebuild-workflow-files --from-file="${basedir}/../ncn/storage"
}

main
