#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

set -o pipefail

usage() {
  # Display help
  echo "Backs up CFS components and configurations."
  echo "All parameters are optional and the values will be determined automatically if not set."
  echo
  echo "Usage: backup_cfs_config_comp.sh [ -b base_directory | -d target_directory ]"
  echo "                                 [--components-only | --configs-only]"
  echo
  echo "By default, a backup directory will be created as a subdirectory of /root."
  echo
  echo "Options:"
  echo "-b base_directory    Create the backup directory under base_directory instead of /root"
  echo "-d target_directory  Create the backup files in target_directory instead of creating a new directory."
  echo "--components-only           Only back up components"
  echo "--configs-only              Only back up configurations"
  echo
}

BASE_DIRECTORY=""
TARGET_DIRECTORY=""
ONLY=""
CFG_BACKUP=""
CMP_BACKUP=""

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  key="$1"

  if [[ ${key} == "--components-only" ]]; then
    if [[ ${ONLY} == components ]]; then
      usage_err_exit "Argument specified multiple times: ${key}"
    elif [[ -n ${ONLY} ]]; then
      usage_err_exit "--components-only and --configs-only are mutually exclusive"
    fi
    ONLY="components"
    shift
    continue
  elif [[ ${key} == "--configs-only" ]]; then
    if [[ ${ONLY} == configs ]]; then
      usage_err_exit "Argument specified multiple times: ${key}"
    elif [[ -n ${ONLY} ]]; then
      usage_err_exit "--components-only and --configs-only are mutually exclusive"
    fi
    ONLY="configs"
    shift
    continue
  elif [[ ${key} != "-b" && ${key} != "-d" ]]; then
    usage_err_exit "Unknown argument: '${key}'"
  fi

  # If we make it here, we are parsing -b or -d arguments

  # Both -b and -d require a nonblank argument
  [[ $# -ge 2 ]] || usage_err_exit "${key} requires an argument"
  [[ -n $2 ]] || usage_err_exit "Argument to ${key} may not be blank"

  # For both -b and -d, the argument must be an existing directory
  [[ -e $2 ]] || usage_err_exit "Argument to ${key} must be an existing directory. Does not exist: '$2'"
  [[ -d $2 ]] || usage_err_exit "Argument to ${key} must be a directory. Not a directory: '$2'"

  if [[ ${key} == "-b" ]]; then
    # -b
    # No duplicate flags
    [[ -z ${BASE_DIRECTORY} ]] || usage_err_exit "Argument specified multiple times: ${key}"

    # -b and -d are mutually exclusive
    [[ -z ${TARGET_DIRECTORY} ]] || usage_err_exit "-b and -d are mutually exclusive"

    BASE_DIRECTORY="$2"
  else
    # -d
    # No duplicate flags
    [[ -z ${TARGET_DIRECTORY} ]] || usage_err_exit "Argument specified multiple times: ${key}"

    # -b and -d are mutually exclusive
    [[ -z ${BASE_DIRECTORY} ]] || usage_err_exit "-b and -d are mutually exclusive"

    TARGET_DIRECTORY="$2"
  fi
  shift # past argument
  shift # past value
done

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [[ -z ${TARGET_DIRECTORY} ]]; then
  [[ -n ${BASE_DIRECTORY} ]] || BASE_DIRECTORY=/root
  if [[ -z ${ONLY} ]]; then
    TARGET_DIRECTORY=$(run_mktemp -d "${BASE_DIRECTORY}/cfs-configs-comps-backup-${TIMESTAMP}-XXX") || exit 1
  else
    TARGET_DIRECTORY=$(run_mktemp -d "${BASE_DIRECTORY}/cfs-${ONLY}-backup-${TIMESTAMP}-XXX") || exit 1
  fi

  # Since we just created this directory, we know its name already includes a timestamp and the fact that
  # these are CFS backups. We also then don't need to worry about existing files being in there whose names
  # may collide with ours.
  CFG_BACKUP="${TARGET_DIRECTORY}/configurations.json"
  CMP_BACKUP="${TARGET_DIRECTORY}/components.json"
else
  # In this case, since the target directory is dictated to us, we include more information in the backup file
  # names, as well as taking care to avoid existing files
  if [[ -z ${ONLY} || ${ONLY} == configs ]]; then
    CFG_BACKUP=$(run_mktemp "${TARGET_DIRECTORY}/cfs-configurations-backup-${TIMESTAMP}-XXX.json") || exit 1
  fi

  if [[ -z ${ONLY} || ${ONLY} == components ]]; then
    CMP_BACKUP=$(run_mktemp "${TARGET_DIRECTORY}/cfs-components-backup-${TIMESTAMP}-XXX.json") || exit 1
  fi
fi

echo "Backing up CFS to the following directory: ${TARGET_DIRECTORY}"

if [[ -n ${CFG_BACKUP} ]]; then
  echo "Backing up configurations to ${CFG_BACKUP}"
  run_cmd cray cfs configurations list --format json > "${CFG_BACKUP}" || err_exit "Error writing to ${CFG_BACKUP}"
fi

if [[ -n ${CMP_BACKUP} ]]; then
  echo "Backing up components to ${CMP_BACKUP}"
  run_cmd cray cfs components list --format json > "${CMP_BACKUP}" || err_exit "Error writing to ${CMP_BACKUP}"
fi

echo "SUCCESS"
exit 0
