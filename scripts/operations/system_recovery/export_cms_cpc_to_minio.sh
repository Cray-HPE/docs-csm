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
CONFIG_SCRIPT_DIR="${locOfScript}/../configuration"
# Inform ShellCheck about the file we are sourcing
# shellcheck source=../configuration/bash_lib/common.sh
. "${CONFIG_SCRIPT_DIR}/bash_lib/common.sh"

CMS_EXPORT_SCRIPT="${locOfScript}/cms_minio_export_helper.sh"

set -uo pipefail

function usage {
  echo "Usage: export_cms_cpc.sh [bos] [cfs] [cpc] [ims] [vcs]" >&2
  echo >&2
  echo "If no areas are specified, all areas are exported." >&2
  echo "Otherwise, only the specified areas are exported." >&2
}

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

backup_areas=()
backup_pids=()

function add_area {
  local a IMS_FS_MNT
  [[ $1 =~ ^(bos|cfs|cpc|ims|vcs)$ ]] || usage_err_exit "Unrecognized export area '$1'"
  for a in "${backup_areas[@]}"; do
    # no need to add it if we already have it
    [[ $a == "$1" ]] && return
  done
  backup_areas+=("$1")
  [[ $1 == ims ]] || return
  # Since we're exporting IMS, make sure /opt/cray/pit/ims exists
  # Inform ShellCheck about the file we are sourcing
  # shellcheck source=./bash_lib/ims.sh
  . "${locOfScript}/bash_lib/ims.sh"
  [[ -e ${IMS_FS_MNT} ]] || err_exit "Directory does not exist: '${IMS_FS_MNT}'"
  [[ -d ${IMS_FS_MNT} ]] || err_exit "Exists but is not a directory: '${IMS_FS_MNT}'"
}

if [[ $# -eq 0 ]]; then
  add_area bos
  add_area cfs
  add_area cpc
  add_area ims
  add_area vcs
else
  while [[ $# -gt 0 ]]; do
    add_area "$1"
    shift
  done
fi

# Create mount point for CMS minio s3fs
CMS_MINIO_MNT=$(run_mktemp -d ~/.export_cms_cpc_minio_mnt.XXX) || err_exit

echo "Initializing CMS bucket in minio (if needed)"
run_cmd "${locOfScript}/setup_cms_minio_mount.sh" --rw --init "${CMS_MINIO_MNT}"

LOG_REL_DIR="logs/exports/$(date +%Y%m%d%H%M%S)"
LOG_DIR="${CMS_MINIO_MNT}/${LOG_REL_DIR}"
echo "Create log directory in minio://cms/${LOG_REL_DIR}"
run_cmd mkdir -p "${LOG_DIR}"

function launch_area_export {
  local epid logbase area
  area="$1"
  logbase="${area}.log"
  echo "$(date) Starting ${area} export (log: minio://cms/${LOG_REL_DIR}/${logbase})"
  nohup "${CMS_EXPORT_SCRIPT}" "${area}" > "${LOG_DIR}/${logbase}" 2>&1 &
  epid=$!
  echo "${area} export PID is ${epid}"
  backup_pids+=("${epid}")
}

for area in "${backup_areas[@]}"; do
  launch_area_export "${area}"
done

echo "Waiting for exports to complete"

errors=0
running=${#backup_pids[@]}
last_print=$SECONDS
need_newline=""
while [[ ${running} -gt 0 ]]; do
  sleep 1
  old_running=${running}
  running=0
  still_running=()
  i=0
  while [[ $i -lt ${#backup_pids[@]} ]]; do
    bpid=${backup_pids[$i]}
    area=${backup_areas[$i]}

    # If the PID is 0, it means we have previously seen that this
    # backup completed and checked it
    if [[ ${bpid} == 0 ]]; then
      let i+=1
      continue
    fi

    # Don't let the scary kill fool you -- with signal 0, this just checks
    # if the process is still running -- no killing involved!
    if kill -0 "${bpid}" > /dev/null 2>&1; then
      let i+=1
      let running+=1
      still_running+=("${area} (${bpid})")
      continue
    fi

    # The process seems to be done, so let's get its exit code
    wait "${bpid}"
    rc=$?
    # Mark that it is done
    backup_pids[$i]=0
    let i+=1
    [[ -n ${need_newline} ]] && echo
    last_print=$SECONDS
    need_newline=""
    if [[ $rc -eq 0 ]]; then
      echo "$(date) ${area} export (PID ${bpid}) completed successfully"
    else
      echo "$(date) ${area} export (PID ${bpid}) FAILED with exit code $rc (logfile: ${LOG_DIR}/${area}.log)"
      let errors+=1
    fi
  done
  if [[ ${running} -gt 0 && ${running} -ne ${old_running} ]]; then
    [[ -n ${need_newline} ]] && echo
    last_print=$SECONDS
    need_newline=""
    echo "Still running: ${still_running[*]}"
    continue
  fi
  # Print some progress characters while waiting, occasionally
  [[ $((SECONDS - last_print)) -ge 180 ]] || continue
  printf .
  need_newline=y
  last_print=$SECONDS
done

umount "${CMS_MINIO_MNT}" || echo "WARNING: Unable to unmount '${CMS_MINIO_MNT}'" >&2

if [[ $errors -ne 0 ]]; then
  err_exit "${errors} of the exports failed. See individual log files for details"
  exit 1
fi

echo "All exports completed successfully"
