#!/usr/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2024 Hewlett Packard Enterprise Development LP
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
# This script exports all BOS data into JSON files. These files are then
# compressed into an tgz archive.
#
# Usage: export_bos_data.sh [--include-v1] [directory_to_create_archive_in]
#
# If no directory is specified, the archive will be created in the current
# directory.
#
# If --include-v1 is specified, the script will attempt to backup BOS v1
# data as well. This is intended for use before upgrades to CSM 1.6 from
# CSM 1.5. If the system is already at CSM 1.6, BOS v1 is no longer available,
# and specifying this option will have no effect.
#
################################################################################

err_exit() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "Usage: export_bos_data.sh [--include-v1] [directory_to_create_archive_in]"
  echo
  err_exit "$@"
}

run_cmd() {
  "$@" || err_exit "Command failed with return code $?: $*"
}

bos_cli() {
  # Expands to: run_cmd cray bos <args to bos_cli> --format json
  # e.g. bos_cli v1 session list
  #      bos_cli v2 sessiontemplates  list
  run_cmd cray bos "$@" --format json
}

bos_list() {
  # Wrapper for bos_cli for list actions
  bos_cli "$@" list
}

INCLUDE_V1=N

if [[ $# -gt 0 ]]; then
  if [[ $1 == --include-v1 ]]; then
    echo "User has requested to include BOS v1 data in the export, if possible"
    # Use the Cray CLI to see if BOS v1 is available
    if ! cray bos v1 >/dev/null 2>&1; then
      echo "BOS v1 is no longer available in the Cray CLI; BOS v1 data will not be exported"
    else
      INCLUDE_V1=Y
    fi
    shift
  elif [[ $1 == --exclude-v1 ]]; then
    # This flag is deprecated, because this is now the default behavior for the script.
    # We still allow for it, though, so as to not break any scripts which may be using it.
    shift
  fi
fi

if [[ $# -gt 1 ]]; then
  usage "Too many arguments"
elif [[ $# -eq 0 ]]; then
  OUTPUT_DIRECTORY=$(pwd)
else
  [[ -n $1 ]] || usage "Directory name is optional, but if specified it may not be blank"
  [[ -e $1 ]] || usage "Target directory does not exist: '$1'"
  [[ -d $1 ]] || usage "Target exists but is not a directory: '$1'"
  OUTPUT_DIRECTORY=$1
fi

ARCHIVE_PREFIX="bos-export-$(date +%Y%m%d%H%M%S)"
ARCHIVE_DIR=$(run_cmd mktemp -p "${OUTPUT_DIRECTORY}" -d "${ARCHIVE_PREFIX}-XXX")

# Export all BOS data. Some of it (like sessions and components) are not intended to be
# restored from this backup, but retaining the historical data may be useful in some situations.

if [[ ${INCLUDE_V1} == Y ]]; then
  V1_DIR="${ARCHIVE_DIR}/v1"
  run_cmd mkdir -p "${V1_DIR}"

  # For BOS v1 the only thing to list is sessions. Every other thing that could be listed can be
  # listed using the v2 CLI.

  echo "Exporting BOS v1 sessions..."
  V1_SESSION_LIST_JSON="${V1_DIR}/session.json"
  bos_list v1 session > "${V1_SESSION_LIST_JSON}"

  # For v1 sessions, we will also describe each, since in BOS v1, just listing them
  # does not show information about them.

  V1_SESSION_DIR="${V1_DIR}/session"
  run_cmd mkdir -p "${V1_SESSION_DIR}"

  for SESSION_ID in $(jq -r '.[] | .' "${V1_SESSION_LIST_JSON}"); do
    bos_cli v1 session describe "${SESSION_ID}" > "${V1_SESSION_DIR}/${SESSION_ID}.json"
  done
fi

# For v2, listing is all we need for all of the types.

V2_DIR="${ARCHIVE_DIR}/v2"
run_cmd mkdir -p "${V2_DIR}"

for OBJECT in components options sessions sessiontemplates version; do
  echo "Exporting BOS v2 ${OBJECT}..."
  bos_list v2 "${OBJECT}" > "${V2_DIR}/${OBJECT}.json"
done

# Compress the results
echo "Creating compressed archive of exported data..."
ARCHIVE_FILE=$(run_cmd mktemp "${ARCHIVE_DIR}XXX.tgz")
ARCHIVE_DIR_BASENAME=$(run_cmd basename "${ARCHIVE_DIR}")
run_cmd tar --remove-files -C "${OUTPUT_DIRECTORY}" -czf "${ARCHIVE_FILE}" "${ARCHIVE_DIR_BASENAME}"
echo "SUCCESS: BOS data stored in file: ${ARCHIVE_FILE}"
