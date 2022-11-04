#!/bin/bash
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

set -o pipefail

err()
{
    echo "ERROR: $*" 1>&2
}

err_exit()
{
    err "$@"
    exit 1
}

run_mktemp()
{
    tmpfile=$(mktemp "$@") || err_exit "Command failed with rc $?: mktemp $*"
    [[ -n ${tmpfile} ]] || err_exit "mktemp command passed but gave no output"
    [[ -e ${tmpfile} ]] || err_exit "mktemp command passed but '${tmpfile}' does not exist"
    if [[ $# -gt 0 && "$1" == "-d" ]]; then
        [[ -d ${tmpfile} ]] || err_exit "mktemp -d command passed and '${tmpfile}' exists, but is not a directory"
    else
        [[ -f ${tmpfile} ]] || err_exit "mktemp command passed and '${tmpfile}' exists, but is not a regular file"
    fi
}

usage()
{
   # Display help
   echo "Backs up CFS components and configurations."
   echo "All parameters are optional and the values will be determined automatically if not set."
   echo
   echo "Usage: backup_cfs_config_comp.sh [ -b base_directory | -d target_directory ]"
   echo
   echo "By default, a backup directory will be created as a subdirectory of /root."
   echo
   echo "Options:"
   echo "-b base_directory    Create the backup directory under base_directory instead of /root"
   echo "-d target_directory  Create the backup files in target_directory instead of creating a new directory."
   echo
}

usage_err_exit()
{
    usage
    err_exit "usage: $*"
}

BASE_DIRECTORY=""
TARGET_DIRECTORY=""

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
    usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    [[ ${key} != "-b" && ${key} != "-d" ]] && usage_err_exit "Unknown argument: '${key}'"

    # Both -b and -d require a nonblank argument
    [[ $# -lt 2 ]] && usage_err_exit "${key} requires an argument"
    [[ -z $2 ]] && usage_err_exit "Argument to ${key} may not be blank"

    # For both -b and -d, the argument must be an existing directory
    [[ ! -e $2 ]] && usage_err_exit "Argument to ${key} must be an existing directory. Does not exist: '$2'"
    [[ ! -d $2 ]] && usage_err_exit "Argument to ${key} must be a directory. Not a directory: '$2'"

    if [[ ${key} == "-b" ]]; then
        # -b
        # No duplicate flags
        [[ -n ${BASE_DIRECTORY} ]] && usage_err_exit "Argument specified multiple times: ${key}"

        # -b and -d are mutually exclusive
        [[ -n ${TARGET_DIRECTORY} ]] && usage_err_exit "-b and -d are mutually exclusive"

        BASE_DIRECTORY="$2"
    else
        # -d
        # No duplicate flags
        [[ -n ${TARGET_DIRECTORY} ]] && usage_err_exit "Argument specified multiple times: ${key}"

        # -b and -d are mutually exclusive
        [[ -n ${BASE_DIRECTORY} ]] && usage_err_exit "-b and -d are mutually exclusive"

        TARGET_DIRECTORY="$2"
    fi
    shift # past argument
    shift # past value
done

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [[ -z ${TARGET_DIRECTORY} ]]; then
    [[ -z ${BASE_DIRECTORY} ]] && BASE_DIRECTORY=/root
    run_mktemp -d "${BASE_DIRECTORY}/cfs-cfg-comp-backups-${TIMESTAMP}-XXX"
    TARGET_DIRECTORY=${tmpfile}
    # Since we just created this directory, we know its name already includes a timestamp and the fact that
    # these are CFS backups. We also then don't need to worry about existing files being in there whose names
    # may collide with ours.
    CFG_BACKUP="${TARGET_DIRECTORY}/configurations.json"
    CMP_BACKUP="${TARGET_DIRECTORY}/components.json"
else
    # In this case, since the target directory is dictated to us, we include more information in the backup file
    # names, as well as taking care to avoid existing files
    run_mktemp "${TARGET_DIRECTORY}/cfs-configurations-backup-${TIMESTAMP}-XXX.json"
    CFG_BACKUP=${tmpfile}
    run_mktemp "${TARGET_DIRECTORY}/cfs-components-backup-${TIMESTAMP}-XXX.json"
    CMP_BACKUP=${tmpfile}
fi

echo "Backing up CFS configurations and components to the following directory: ${TARGET_DIRECTORY}"

echo "Backing up configurations to ${CFG_BACKUP}"
cray cfs configurations list --format json > "${CFG_BACKUP}" ||
    err_exit "Error writing to ${CFG_BACKUP} or running command: cray cfs configurations list --format json"

echo "Backing up components to ${CMP_BACKUP}"
cray cfs components list --format json > "${CMP_BACKUP}" ||
    err_exit "Error writing to ${CMP_BACKUP} or running command: cray cfs components list --format json"

echo "SUCCESS"
exit 0
