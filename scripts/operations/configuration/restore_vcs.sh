#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=./bash_lib/common.sh
. "${locOfScript}/bash_lib/common.sh"

# Inform ShellCheck about the file we are sourcing
# shellcheck source=./bash_lib/vcs.sh
. "${locOfScript}/bash_lib/vcs.sh"

set -uo pipefail

DUMPFILE=""
MANIFEST=""
TARFILE=""

function wait_for_pods_to_start {
  # Usage: wait_for_pods_to_start <argument to kubectl get pods -l flag> <# of pods expected>
  local num_pods
  [[ $# -ne 2 ]] && err_exit "$0: Function requires exactly 2 arguments but received $#. Invalid arguments: $*"
  [[ -z $1 ]] && err_exit "$0: First argument may not be blank"
  [[ -z $1 ]] && err_exit "$0: Second argument may not be blank"
  [[ ! $2 -gt 0 ]] && err_exit "$0: Second argument must be an integer greated than 0. Invalid second argument: $2"

  echo "Wait for $2 pod(s) to be running."
  num_pods=$(kubectl get pods -l "$1" -n services | grep Running | wc -l)
  while [[ ${num_pods} -lt $2 ]]; do
    echo "  ${num_pods} running; waiting for $2 pod(s) to be running"
    sleep 5
    num_pods=$(kubectl get pods -l "$1" -n services | grep Running | wc -l)
  done
}

function wait_for_pods_to_terminate {
  # Usage: wait_for_pods_to_terminate <argument to kubectl get pods -l flag>
  [[ $# -ne 1 ]] && err_exit "$0: Function requires exactly 1 argument but received $#. Invalid arguments: $*"
  [[ -z $1 ]] && err_exit "$0: Argument may not be blank"
  echo "Wait for pods to terminate ($1)"
  while kubectl get pods -n services -l "$1" | grep -qv NAME; do
    echo "  waiting for pods to terminate"
    sleep 5
  done
}

# It seems that shellcheck doesn't like that we defensively check to make sure the function
# did not accidentally get passed arguments. Sorry not sorry, shellcheck
#shellcheck disable=SC2120
function wait_for_postgres_cluster_running {
  # Takes no arguments
  local status
  [[ $# -ne 0 ]] && err_exit "$0: Function takes no arguments but received $#. Invalid arguments: $*"

  echo "Wait for the gitea-vcs-postgres Postgres cluster to start running."
  while true; do
    status=$(kubectl get postgresql gitea-vcs-postgres -n services -o json | jq -r '.status.PostgresClusterStatus')
    [[ ${status} == "Running" ]] && return
    echo "  waiting for postgresql to start running"
    sleep 5
  done
}

function restore_sql_and_secrets {
  local tmp_outfile postgres_cr_json postgres_cr_single_json

  echo "Scale VCS service to 0"
  run_cmd kubectl scale deployment gitea-vcs -n services --replicas=0

  wait_for_pods_to_terminate app.kubernetes.io/name=vcs

  echo "Delete VCS Postgres cluster"

  tmp_outfile=$(run_mktemp -p ~) || exit 1
  run_cmd kubectl get postgresql gitea-vcs-postgres -n services -o json > "${tmp_outfile}" || err_exit "Error creating ${tmp_outfile}"

  postgres_cr_json=$(run_mktemp -p ~ postgres-cr.XXX.json) || exit 1
  run_cmd jq 'del(.spec.selector) | del(.spec.template.metadata.labels."controller-uid") | del(.status)' "${tmp_outfile}" > "${postgres_cr_json}" || err_exit "Error creating ${postgres_cr_json}"

  run_cmd kubectl delete -f "${postgres_cr_json}"

  wait_for_pods_to_terminate application=spilo,cluster-name=gitea-vcs-postgres

  echo "Create a new single instance VCS Postgres cluster."
  postgres_cr_single_json=$(run_mktemp -p ~ postgres-cr-single.XXX.json) || exit 1

  run_cmd jq '.spec.numberOfInstances = 1' "${postgres_cr_json}" > "${postgres_cr_single_json}" || err_exit "Error creating ${postgres_cr_single_json}"

  run_cmd kubectl create -f "${postgres_cr_single_json}"

  wait_for_pods_to_start application=spilo,cluster-name=gitea-vcs-postgres 1

  wait_for_postgres_cluster_running

  echo "Restore the database from ${DUMPFILE}"
  run_cmd kubectl exec gitea-vcs-postgres-0 -c postgres -n services -it -- psql -U postgres < "${DUMPFILE}" || err_exit "Error reading from $DUMPFILE"

  echo "Delete the gitea-vcs-postgres secrets"
  run_cmd kubectl delete -f "${MANIFEST}"

  echo "Recreate the gitea-vcs-postgres secrets using the manifest (${MANIFEST})"
  run_cmd kubectl apply -f "${MANIFEST}"

  echo "Restart the Postgres cluster."
  run_cmd kubectl delete pod -n services gitea-vcs-postgres-0

  wait_for_pods_to_start application=spilo,cluster-name=gitea-vcs-postgres 1

  echo "Scale the Postgres cluster back to 3 instances."
  run_cmd kubectl patch postgresql gitea-vcs-postgres -n services --type=json -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

  wait_for_postgres_cluster_running

  echo "Scale the Gitea service back up."
  run_cmd kubectl scale deployment gitea-vcs -n services --replicas=1

  wait_for_pods_to_start app.kubernetes.io/name=vcs 1

  rm "${tmp_outfile}" "${postgres_cr_json}" "${postgres_cr_single_json}" > /dev/null 2>&1
}

function restore_pvc_data {
  local gitea_pod

  # Set the gitea_pod variable to the name of the gitea pod
  get_gitea_pod

  echo "Copy PVC data tarfile into pod (${gitea_pod})"
  run_cmd kubectl -n services cp "${TARFILE}" "${gitea_pod}":/tmp/vcs.tar

  echo "Expand PVC data tarfile in pod"
  run_cmd kubectl -n services exec "${gitea_pod}" -- tar -C / -xf /tmp/vcs.tar
}

function usage {
  echo "Usage: restore_vcs.sh <gitea-vcs backup tgz file>"
  echo
  echo "This file is the one produced by the backup_vcs.sh script" >&2
}

function input_file_exists_nonempty {
  [[ $# -eq 1 ]] || err_exit "Programming logic error: $0 function takes exactly 1 argument but received $#: $*"
  [[ -n $1 ]] || err_exit "Programming logic error: $0 function argument may not be blank"
  [[ -e $1 ]] || usage_err_exit "File does not exist: '$1'"
  [[ -f $1 ]] || usage_err_exit "Exists but is not a regular file: '$1'"
  [[ -s $1 ]] || usage_err_exit "File is 0 size: '$1'"
}

[[ $# -eq 0 ]] && usage_err_exit "Missing required arguments"
[[ $# -gt 1 ]] && usage_err_exit "Too many arguments"
[[ -n $1 ]] || usage_err_exit "Argument may not be blank"
input_file_exists_nonempty "$1"

TMPDIR=$(run_mktemp -d -p ~) || err_exit
run_cmd tar -C "${TMPDIR}" -xvf "$1"

DUMPFILE="${TMPDIR}/${SQL_BACKUP_NAME}"
MANIFEST="${TMPDIR}/${SEC_BACKUP_NAME}"
TARFILE="${TMPDIR}/${PVC_BACKUP_NAME}"
input_file_exists_nonempty "${DUMPFILE}"
input_file_exists_nonempty "${MANIFEST}"
input_file_exists_nonempty "${TARFILE}"

# A very quick check just to help catch cases where the completely wrong file is somehow found
grep -q 'PostgreSQL database cluster dump' "${DUMPFILE}" || usage_err_exit "Does not appear to be a SQL database cluster dump: '${DUMPFILE}'"
grep -Eq '^apiVersion:' "${MANIFEST}" || usage_err_exit "Does not appear to be a manifest file: '${MANIFEST}'"
file "${TARFILE}" | grep -q 'tar archive' || usage_err_exit "Does not appear to be a tar archive: '${TARFILE}'"

restore_sql_and_secrets
restore_pvc_data

echo "Restart gitea-vcs deployment"
run_cmd kubectl -n services rollout restart deployment gitea-vcs

echo "Wait for restart to complete"
run_cmd kubectl -n services rollout status deployment gitea-vcs

rm "${DUMPFILE}" "${MANIFEST}" "${TARFILE}"
rmdir "${TMPDIR}"

echo "Gitea/VCS restore completed!"
