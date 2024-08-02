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

CMS_IMPORT_SCRIPT="${locOfScript}/cms_minio_import_helper.sh"

set -uo pipefail

function usage {
  echo "Usage: import_cms_cpc_from_minio.sh [bos] [cfs] [cpc] [ims] [vcs]" >&2
  echo >&2
  echo "If no areas are specified, all areas are imported." >&2
  echo "Otherwise, only the specified areas are imported." >&2
}

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

import_areas=()
import_pids=()

function area_index {
  local i
  [[ $1 =~ ^(bos|cfs|cpc|ims|vcs)$ ]] || err_exit "Programming logic error: $0: Unrecognized import area '$1'"
  i=0
  while [[ $i -lt ${#import_areas[@]} ]]; do
    [[ ${import_areas[$i]} == "$1" ]] && echo "$i" && return 0
    let i+=1
  done
  return 1
}

function add_area {
  [[ $1 =~ ^(bos|cfs|cpc|ims|vcs)$ ]] || usage_err_exit "Unrecognized import area '$1'"
  # no need to add it if we already have it
  area_index "$a" > /dev/null && return
  import_areas+=("$1")
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
CMS_LOG_MINIO_MNT=$(run_mktemp -d ~/.import_cms_cpc_log_minio_mnt.XXX) || err_exit

echo "Creating CMS minio mount"
run_cmd "${locOfScript}/setup_cms_minio_mount.sh" --rw "${CMS_LOG_MINIO_MNT}"

LOG_REL_DIR="logs/imports/$(date +%Y%m%d%H%M%S)"
LOG_DIR="${CMS_LOG_MINIO_MNT}/${LOG_REL_DIR}"
echo "Create log directory in minio://cms/${LOG_REL_DIR}"
run_cmd mkdir -p "${LOG_DIR}"

function area_succeeded_if_included {
  # Returns 0 if we are not importing the specified area OR if we are
  # importing it, and its import has completed successfully
  # Returns 1 otherwise (that is, if we are importing the specified area, but the
  # import is still underway or it failed)
  local index
  [[ $1 =~ ^(bos|cfs|cpc|ims|vcs)$ ]] || err_exit "Programming logic error: $0: Unrecognized import area '$1'"
  # Return 0 if we are not importing it
  index=$(area_index "$1") || return 0
  # Return 0 if it completed successfully
  [[ ${import_pids[$index]} == 0 ]] && return 0
  # Return 1 otherwise
  return 1
}

function areas_succeeded_if_included {
  local a
  for a in "$@"; do
    [[ $a =~ ^(bos|cfs|cpc|ims|vcs)$ ]] || err_exit "Programming logic error: $0: Unrecognized import area '$a'"
    area_succeeded_if_included "$a" || return 1
  done
  return 0
}

function launch_area_import {
  local epid logbase area
  area="$1"
  # bos should not import until ims and cfs complete
  # cfs should not import until vcs completes
  # cpc should not import until vcs and ims complete
  case "${area}" in
    bos)
      areas_succeeded_if_included cfs ims || return
      ;;
    cfs)
      area_succeeded_if_included vcs || return
      ;;
    cpc)
      areas_succeeded_if_included ims vcs || return
      ;;
  esac
  logbase="${area}.log"
  echo "$(date) Starting ${area} import (log: minio://cms/${LOG_REL_DIR}/${logbase})"
  nohup "${CMS_IMPORT_SCRIPT}" "${area}" > "${LOG_DIR}/${logbase}" 2>&1 &
  epid=$!
  echo "${area} import PID is ${epid}"
  import_pids+=("${epid}")
}

function any_running {
  # Echos y if any imports are running
  # Echos n otherwise
  local i
  i=0
  while [[ $i -lt ${#import_areas[*]} ]]; do
    [[ -n ${import_pids[$i]} && ${import_pids[$i]} -gt 0 ]] && echo y && return
    let i+=1
  done
  echo n
}

# Launch the ones that can start

for area in "${import_areas[@]}"; do
  launch_area_import "${area}"
done

last_print=$SECONDS
need_newline=""

while [[ true ]]; do

  any_running_before=$(any_running)

  i=0
  while [[ $i -lt ${#import_areas[@]} ]]; do
    area=${import_areas[$i]}
    epid=${import_pids[$i]}

    # If the PID is not set, it means that this area was waiting on a prerequisite
    # script to complete. So let's try to launch it now.
    if [[ -z $epid ]]; then
      launch_area_import "${area}"
      let i+=1
      continue
    fi

    # If the PID is 0, it means we have previously seen that this
    # backup completed and checked it
    if [[ $epid -lt 1 ]]; then
      let i+=1
      continue
    fi

    # Don't let the scary kill fool you -- with signal 0, this just checks
    # if the process is still running -- no killing involved!
    if kill -0 "${epid}" > /dev/null 2>&1; then
      let i+=1
      still_running+=("${area} (${epid})")
      continue
    fi

    # The process seems to be done, so let's get its exit code
    wait "${epid}"
    rc=$?
    [[ -n ${need_newline} ]] && echo
    last_print=$SECONDS
    need_newline=""
    if [[ $rc -eq 0 ]]; then
      echo "$(date) ${area} import (PID ${epid}) completed successfully"
      # Mark that it completed successfully
      import_pids[$i]=0
    else
      echo "$(date) ${area} import (PID ${epid}) FAILED with exit code $rc (logfile: ${LOG_DIR}/${area}.log)"
      # Mark that it failed
      import_pids[$i]=-1
    fi
    let i+=1
  done

  if [[ ${any_running_before} == n && $(any_running) == n ]]; then
    # We must be done -- everything has either completed, or it cannot run because a dependency failed/did not run
    break
  fi

  # Print some progress characters while waiting, occasionally
  [[ $((SECONDS - last_print)) -ge 180 ]] || continue
  printf .
  need_newline=y
  last_print=$SECONDS

done

i=0
errors=0
while [[ $i -lt ${#import_areas[*]} ]]; do
  if [[ -z ${import_pids[$i]} ]]; then
    echo "WARNING: Import of ${import_areas[$i]} was not able to run because a prerequisite import did not successfully complete" >&2
  elif [[ ${import_pids[$i]} -lt 0 ]]; then
    let errors+=1
  fi
  let i+=1
done

umount "${CMS_LOG_MINIO_MNT}" || echo "WARNING: Unable to unmount '${CMS_LOG_MINIO_MNT}'" >&2

if [[ $errors -ne 0 ]]; then
  err_exit "${errors} of the imports failed. See individual log files for details"
  exit 1
fi

echo "All imports completed successfully"
