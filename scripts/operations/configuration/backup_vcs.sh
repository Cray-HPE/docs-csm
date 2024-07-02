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

function backup_postgres {
  local leader_pod json secrets secret num_secrets tmpfile field

  sql_outfile="${TMPDIR}/${SQL_BACKUP_NAME}"
  sec_outfile="${TMPDIR}/${SEC_BACKUP_NAME}"

  json=$(run_cmd kubectl exec gitea-vcs-postgres-0 -n services -c postgres -it -- patronictl list -f json) || err_exit
  leader_pod=$(run_cmd jq -r '.[] | select(.Role == "Leader") | .Member' <<< "${json}") || err_exit
  [[ -n ${leader_pod} ]] || err_exit "No gitea-vcs-postgres leader pod found"
  echo "Backing up data from gitea-vcs-postgres leader pod ${leader_pod} to ${sql_outfile}"

  run_cmd kubectl exec -it "${leader_pod}" -n services -c postgres -- pg_dumpall --if-exists -c -U postgres > "${sql_outfile}" \
    || err_exit "Error writing to file '${sql_outfile}'"

  echo "Backing up gitea-vcs-postgres Kubernetes secrets to ${sec_outfile}"

  num_secrets=0
  secrets=$(run_cmd kubectl get secrets -n services -l cluster-name=gitea-vcs-postgres -o custom-columns=":metadata.name" --no-headers) || err_exit
  tmpfile=$(run_mktemp -p "$TMPDIR") || err_exit
  echo "---" > "${sec_outfile}" || err_exit "Error writing to '${sec_outfile}'"
  for secret in ${secrets}; do
    let num_secrets+=1
    echo "Backing up secret: ${secret}"
    run_cmd kubectl get secret "${secret}" -n services -o yaml > "${tmpfile}" || err_exit "Error writing to '${tmpfile}'"
    for field in creationTimestamp resourceVersion selfLink uid; do
      run_cmd yq d -i "${tmpfile}" "metadata.${field}"
    done
    run_cmd cat "${tmpfile}" >> "${sec_outfile}" || err_exit "Error appending to '${sec_outfile}'"
    echo "---" >> "${sec_outfile}" || err_exit "Error appending to '${sec_outfile}'"
  done
  run_cmd rm "${tmpfile}"
  [[ ${num_secrets} -ge 3 ]] || err_exit "Expected at least 3 secrets, but only found ${num_secrets}"
}

function backup_pvc {
  local pvc_outfile gitea_pod

  pvc_outfile="${TMPDIR}/${PVC_BACKUP_NAME}"

  # Set the gitea_pod variable to the name of the gitea pod
  get_gitea_pod

  echo "Backing up PVC data from gitea pod ${gitea_pod}"
  run_cmd kubectl -n services exec "${gitea_pod}" -- tar -cf /tmp/vcs.tar /var/lib/gitea/
  echo "Copying backed up data out of the pod to ${pvc_outfile}"
  run_cmd kubectl -n services cp "${gitea_pod}":/tmp/vcs.tar "${pvc_outfile}"
}

function usage {
  echo "Usage: backup_vcs.sh [-t workdir_location] [output_directory]" >&2
  echo
  echo "If no output directory is specified, one is created under the user's home directory" >&2
  echo "If no working directory is specified, one is created under the user's home directory" >&2
}

OUTDIR=""
WORKDIR_BASE=""

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    "-t")
      [[ $# -gt 1 ]] || usage_err_exit "The $1 parameter requires an argument"
      [[ -n ${WORKDIR_BASE} ]] && usage_err_exit "The $1 parameter may only be specified once"
      shift
      [[ -n $1 ]] || usage_err_exit "Work directory may not be blank"
      [[ -e $1 ]] || usage_err_exit "Specified work directory ($1) does not exist"
      [[ -d $1 ]] || usage_err_exit "Specified work directory ($1) exists but is not a directory"
      WORKDIR_BASE="$1"
      ;;
    *)
      [[ $# -eq 1 ]] || usage_err_exit "Too many arguments"
      [[ -n $1 ]] || usage_err_exit "Output directory argument may not be blank"
      [[ -e $1 ]] || usage_err_exit "Specified output directory ($1) does not exist"
      [[ -d $1 ]] || usage_err_exit "Specified output directory ($1) exists but is not a directory"
      OUTDIR="$1"
      ;;
  esac
  shift
done

[[ -n ${OUTDIR} ]] || OUTDIR=~
[[ -n ${WORKDIR_BASE} ]] || WORKDIR_BASE=~

TMPDIR=$(run_mktemp -d "${WORKDIR_BASE}/gitea_vcs_backup.$(date +%Y%m%d%H%M%S).XXX") || err_exit

echo "Backing up Gitea/VCS data"
backup_postgres
backup_pvc
BACKUP_TARFILE=$(run_mktemp "${OUTDIR}/gitea-vcs-$(date +%Y%m%d%H%M%S)-XXXXXX.tgz") || err_exit
run_cmd tar -C "${TMPDIR}" -czf "${BACKUP_TARFILE}" --remove-files "${SQL_BACKUP_NAME}" "${SEC_BACKUP_NAME}" "${PVC_BACKUP_NAME}"
rmdir "${TMPDIR}" || echo "WARNING: Unable to remove temporary directory '${TMPDIR}'"
echo "Gitea/VCS data successfully backed up to ${BACKUP_TARFILE}"
