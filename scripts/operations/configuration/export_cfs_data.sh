#!/usr/bin/bash
#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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

################################################################################
#
# This script exports all CFS data into JSON files. These files are then
# compressed into an tgz archive.
#
# Usage: export_cfs_data.sh [directory_to_create_archive_in]
#
# If no directory is specified, the archive will be created in the current
# directory.
#
################################################################################

err_exit() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "Usage: export_cfs_data.sh [directory_to_create_archive_in]"
  echo
  err_exit "$@"
}

run_cmd() {
  "$@" || err_exit "Command failed with return code $?: $*"
}

basedir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
export_python_script="${basedir}/export_cfs_data.py"
[[ -e ${export_python_script} ]] \
  || err_exit "File does not exist: '${export_python_script}'"
[[ -f ${export_python_script} ]] \
  || err_exit "Not a regular file: '${export_python_script}'"
[[ -x ${export_python_script} ]] \
  || err_exit "File is not executable: '${export_python_script}'"

if [[ $# -eq 0 ]]; then
  OUTPUT_DIRECTORY=$(pwd)
else
  [[ -n $1 ]] || usage "Directory name is optional, but if specified it may not be blank"
  [[ -e $1 ]] || usage "Target directory does not exist: '$1'"
  [[ -d $1 ]] || usage "Target exists but is not a directory: '$1'"
  OUTPUT_DIRECTORY=$1
fi

ARCHIVE_PREFIX="cfs-export-$(date +%Y%m%d%H%M%S)"
ARCHIVE_DIR=$(run_cmd mktemp -p "${OUTPUT_DIRECTORY}" -d "${ARCHIVE_PREFIX}-XXX")

# Export the CFS data to ARCHIVE_DIR
run_cmd "${export_python_script}" "${ARCHIVE_DIR}"

# Compress the results
echo "Creating compressed archive of exported data..."
ARCHIVE_FILE=$(run_cmd mktemp "${ARCHIVE_DIR}XXX.tgz")
ARCHIVE_DIR_BASENAME=$(run_cmd basename "${ARCHIVE_DIR}")
run_cmd tar --remove-files -C "${OUTPUT_DIRECTORY}" -czf "${ARCHIVE_FILE}" "${ARCHIVE_DIR_BASENAME}"
echo "SUCCESS: CFS data stored in file: ${ARCHIVE_FILE}"
