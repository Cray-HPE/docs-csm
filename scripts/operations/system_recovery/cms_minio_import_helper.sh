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
  echo "Usage: cms_minio_import_helper.sh <bos | cfs | cpc | ims | vcs>" >&2
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
IMPORT_SCRIPT_ARGS=()
BACKUP_EXT=tgz

case "${area}" in
  bos)
    IMPORT_SCRIPT_NAME="import_bos_data.sh"
    BACKUP_PREFIX=bos-import
    IMPORT_SCRIPT_ARGS=("--clear-bos")
    ;;
  cfs)
    IMPORT_SCRIPT_NAME="import_cfs_data.sh"
    BACKUP_PREFIX=cfs-import
    IMPORT_SCRIPT_ARGS=("--clear-cfs")
    ;;
  cpc)
    IMPORT_SCRIPT_NAME="restore_cpc.sh"
    BACKUP_PREFIX=cray-product-catalog
    BACKUP_EXT=yaml
    ;;
  ims)
    IMPORT_SCRIPT_NAME="import_ims_data.py"
    # We don't set backup prefix and ext for IMS, because it is handled differently

    # IMS uses a different temp location for its backup, because of how large it is
    # Inform ShellCheck about the file we are sourcing
    # shellcheck source=./bash_lib/ims.sh
    . "${locOfScript}/bash_lib/ims.sh"

    IMS_EXPORTED_DATA_DIR="${IMS_FS_MNT}/exported-ims-data"
    for dir in "${IMS_FS_MNT}" "${IMS_EXPORTED_DATA_DIR}"; do
      [[ -e ${dir} ]] || err_exit "Directory does not exist: '${dir}'"
      [[ -d ${dir} ]] || err_exit "Exists but is not a directory: '${dir}'"
    done
    ;;
  vcs)
    IMPORT_SCRIPT_NAME="backup_vcs.sh"
    BACKUP_PREFIX=gitea-vcs
    ;;
  *)
    usage_err_exit "Unknown import area: '${area}'"
    ;;
esac

if [[ ${area} != ims ]]; then
  # We need to set up a minio mount point and find the backup file
  CMS_MINIO_MNT=$(run_mktemp -d ~/.import_${area}_minio_mnt.XXX) || err_exit
  run_cmd "${locOfScript}/setup_cms_minio_mount.sh" --ro "${CMS_MINIO_MNT}"

  # Sort and tail to pick the one with the most recent timestamp
  BACKUP_FILE=$(ls "${CMS_MINIO_MNT}/${BACKUP_PREFIX}"*".${BACKUP_EXT}" | sort | tail -1) || err_exit "Error locating backup file for ${area}"

  run_cmd "${CONFIG_SCRIPT_DIR}/${IMPORT_SCRIPT_NAME}" "${IMPORT_SCRIPT_ARGS[@]}" "${BACKUP_FILE}"

  umount "${CMS_MINIO_MNT}" || echo "WARNING: Unable to unmount '${CMS_MINIO_MNT}'" >&2
else
  # IMS is handled differently
  run_cmd "${CONFIG_SCRIPT_DIR}/${IMPORT_SCRIPT_NAME}" -d "${IMS_EXPORTED_DATA_DIR}" overwrite

  run_cmd "${IMS_EXPORTED_DATA_DIR}/cleanup.sh"
fi

echo "${area} import completed successfully"
