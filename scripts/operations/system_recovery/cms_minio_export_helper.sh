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

set -uo pipefail

function usage {
  echo "Usage: cms_minio_export_helper.sh <bos | cfs | cpc | ims | vcs>" >&2
}

if [[ $# -eq 1 ]] && [[ $1 == "-h" || $1 == "--help" ]]; then
  usage
  exit 2
fi

[[ $# -ne 0 ]] || usage_err_exit "Missing required argument"
[[ $# -le 1 ]] || usage_err_exit "Too many arguments"
[[ -n $1 ]] || usage_err_exit "Export area cannot be blank"

# Set defaults
area="$1"
EXPORT_SCRIPT_ARGS=()
TMPDIR_BASE=~
BACKUP_EXT=tgz

case "${area}" in
  bos)
    EXPORT_SCRIPT_NAME="export_bos_data.sh"
    BACKUP_PREFIX=bos-export
    ;;
  cfs)
    EXPORT_SCRIPT_NAME="export_cfs_data.sh"
    BACKUP_PREFIX=cfs-export
    ;;
  cpc)
    EXPORT_SCRIPT_NAME="dump_cpc.sh"
    BACKUP_PREFIX=cray-product-catalog
    BACKUP_EXT=yaml
    ;;
  ims)
    EXPORT_SCRIPT_NAME="export_ims_data.py"
    # Unlike the other export scripts, we use an additional argument with the IMS exporter
    EXPORT_SCRIPT_ARGS=("--no-tar")
    # We don't set backup prefix and ext for IMS, because it is handled differently

    # IMS uses a different temp location for its backup, because of how large it is
    # Inform ShellCheck about the file we are sourcing
    # shellcheck source=./bash_lib/ims.sh
    . "${locOfScript}/bash_lib/ims.sh"

    [[ -e ${IMS_FS_MNT} ]] || err_exit "Directory does not exist: '${IMS_FS_MNT}'"
    [[ -d ${IMS_FS_MNT} ]] || err_exit "Exists but is not a directory: '${IMS_FS_MNT}'"
    TMPDIR_BASE="${IMS_FS_MNT}"
    ;;
  vcs)
    EXPORT_SCRIPT_NAME="backup_vcs.sh"
    BACKUP_PREFIX=gitea-vcs
    ;;
  *)
    usage_err_exit "Unknown export area: '${area}'"
    ;;
esac

TMPDIR=$(run_mktemp -d "${TMPDIR_BASE}/export-${area}.XXX") || err_exit
run_cmd "${CONFIG_SCRIPT_DIR}/${EXPORT_SCRIPT_NAME}" "${EXPORT_SCRIPT_ARGS[@]}" "${TMPDIR}"

# Copying the data over to minio is different for IMS versus the others
if [[ ${area} == ims ]]; then
  run_cmd aws s3 sync "${TMPDIR}" s3://cms/ims --endpoint-url http://localhost:8000
  # We want to fail the script if this fails, because it will leave a lot of data on disk otherwise
  run_cmd rm -rf "${TMPDIR}"
else
  run_cmd aws s3 mv "${TMPDIR}/${BACKUP_PREFIX}"*".${BACKUP_EXT}" s3://cms --endpoint-url http://localhost:8000
  # Non-IMS backups are much smaller, plus we are using s3 mv, so it's not the end of the world if
  # we don't clean up the temporary directory
  rmdir "${TMPDIR}" || echo "WARNING: Unable to remove directory '${TMPDIR}'" >&2
fi

echo "${area} export completed successfully"
