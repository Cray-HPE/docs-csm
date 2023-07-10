#!/usr/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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
# This script imports CFS data from the archive file created by the
# export_cfs_data script.
# It is essentially a wrapper for the Python script of the same name.
# This shell script just expands the archive file and then runs the
# Python script against the directory into which it was expanded. After
# the Python script completes, the expanded files from the archive are
# cleaned up by this shell script, unless --no-cleanup is specified.
#
# Usage: import_cfs_data.sh [--clear-cfs] [--no-cleanup] <CFS export file.tgz>
#
################################################################################

CLEANUP=YES
OUTPUT_DIR=""
CLEAR_CFS=""
ARCHIVE=""

cleanup() {
  [[ $CLEANUP == YES ]] || return
  [[ -n ${OUTPUT_DIR} ]] || return
  [[ -d ${OUTPUT_DIR} ]] || return
  echo "Removing directory '${OUTPUT_DIR}'"
  rm -rf "${OUTPUT_DIR}" || echo "WARNING: Error removing directory '${OUTPUT_DIR}'" >&2
  OUTPUT_DIR=""
  return 0
}

err_exit() {
  echo "ERROR: $*" >&2
  cleanup
  exit 1
}

usage() {
  echo "Usage: import_cfs_data.sh [--clear-cfs] [--no-cleanup] <CFS export file.tgz>"
  echo
  err_exit "$@"
}

run_cmd() {
  "$@" || err_exit "Command failed with return code $?: $*"
}

if [[ $# -eq 0 ]]; then
  usage "Missing required argument"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    "--no-cleanup") CLEANUP="" ;;
    "--clear-cfs") CLEAR_CFS="$1" ;;
    *)
      [[ $# -eq 1 ]] || usage "Unrecognized argument: $1"
      ARCHIVE="$1"
      ;;
  esac
  shift
done

[[ ${ARCHIVE} =~ .*\.tgz$ ]] || usage "Invalid archive file name: '${ARCHIVE}'"
[[ -e ${ARCHIVE} ]] || usage "Archive file does not exist: '${ARCHIVE}'"
[[ -f ${ARCHIVE} ]] || usage "Archive exists but is not a regular file: '${ARCHIVE}'"
[[ -s ${ARCHIVE} ]] || usage "Archive file is zero size: '${ARCHIVE}'"

basedir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
import_python_script="${basedir}/import_cfs_data.py"
[[ -e ${import_python_script} ]] \
  || err_exit "File does not exist: '${import_python_script}'"
[[ -f ${import_python_script} ]] \
  || err_exit "Not a regular file: '${import_python_script}'"
[[ -x ${import_python_script} ]] \
  || err_exit "File is not executable: '${import_python_script}'"

OUTPUT_DIR_PREFIX="cfs-import-$(date +%Y%m%d%H%M%S)"
OUTPUT_DIR=$(run_cmd mktemp --tmpdir -d "${OUTPUT_DIR_PREFIX}-XXX")

# Expand the archive into the directory
echo "Expanding archived CFS data into directory '${OUTPUT_DIR}'"
run_cmd tar -C "${OUTPUT_DIR}" -xzf "${ARCHIVE}"

# There should be a subdirectory of $OUTPUT_DIR which contains components.json, configurations.json, and options.json
JSON_DIR=$(find "${OUTPUT_DIR}" -type f -name components.json -printf "%h" -quit)
[[ -n ${JSON_DIR} ]] || err_exit "No components.json found inside archive"
for FNAME in configurations.json options.json; do
  [[ -f ${JSON_DIR}/${FNAME} ]] || err_exit "Archive directory containing components.json does not contain ${FNAME}"
done

# Call the Python importer script on this directory
# CLEAR_CFS is deliberately not quoted because if it is empty, we don't want to pass in an empty argument to the Python script
run_cmd "${import_python_script}" ${CLEAR_CFS} "${JSON_DIR}"

# Call cleanup (which will clean up the output directory unless --no-cleanup was specified)
cleanup
