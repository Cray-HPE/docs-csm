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

DEFAULT_CMS_MINIO_MNT=/etc/cray/minio/cms
AWS_CREDFILE=/root/.aws/credentials

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=../configuration/bash_lib/common.sh
. "${locOfScript}/../configuration/bash_lib/common.sh"

set -o pipefail

function usage {
  echo "Usage: setup_cms_minio_mount.sh {--rw | --ro} [--init] [mount_point]" >&2
  echo >&2
  echo "If --init is specified, the cms bucket will be created, if it does not exist." >&2
  echo "The --rw / --ro arguments govern whether it will be mounted read-write or read-only" >&2
  echo "If mount_point is not specified, it defaults to '${DEFAULT_CMS_MINIO_MNT}'" >&2
  echo >&2
}

CMS_MINIO_MNT=""
MOUNT_OPT=""
INIT=""
[[ $# -eq 0 ]] && usage_err_exit "At least 1 argument is required"
while [[ $# -gt 0 ]]; do
  case "$1" in
    "--ro")
      [[ ${MOUNT_OPT} == "ro" ]] && usage_err_exit "Argument --ro may only be specified once"
      [[ ${MOUNT_OPT} == "rw" ]] && usage_err_exit "Arguments --ro and --rw are mutually exclusive"
      [[ -n ${MOUNT_OPT} ]] && err_exit "Programming logic error: MOUNT_OPT='${MOUNT_OPT}'"
      MOUNT_OPT=ro
      ;;
    "--rw")
      [[ ${MOUNT_OPT} == "rw" ]] && usage_err_exit "Argument --rw may only be specified once"
      [[ ${MOUNT_OPT} == "ro" ]] && usage_err_exit "Arguments --ro and --rw are mutually exclusive"
      [[ -n ${MOUNT_OPT} ]] && err_exit "Programming logic error: MOUNT_OPT='${MOUNT_OPT}'"
      MOUNT_OPT=rw
      ;;
    "--init")
      [[ -n ${INIT} ]] && usage_err_exit "Argument --init may only be specified once"
      INIT=Y
      ;;
    *)
      [[ $# -gt 1 ]] && usage_err_exit "Too many arguments"
      [[ -n $1 ]] || usage_err_exit "Mount point may not be blank"
      [[ $1 =~ ^/.* ]] || usage_err_exit "Cannot use relative path for mount point"
      CMS_MINIO_MNT="$1"
      ;;
  esac
  shift
done

[[ -z ${MOUNT_OPT} ]] && usage_err_exit "Either --ro or --rw must be specified"
[[ -n ${CMS_MINIO_MNT} ]] || CMS_MINIO_MNT="${DEFAULT_CMS_MINIO_MNT}"

# Make sure the credentials file exists and is not empty
[[ -e ${AWS_CREDFILE} ]] || err_exit "AWS credentials file (${AWS_CREDFILE}) does not exist"
[[ -f ${AWS_CREDFILE} ]] || err_exit "AWS credentials file (${AWS_CREDFILE}) exists but is not a regular file"
[[ -s ${AWS_CREDFILE} ]] || err_exit "AWS credentials file (${AWS_CREDFILE}) exists but is empty"

# Check for existence of CMS bucket
if ! aws s3api list-buckets --endpoint-url http://ncn-m001.nmn:8000 | jq -r '.Buckets[] | .Name' | grep -Eq '^cms$'; then
  [[ -z ${INIT} ]] && err_exit "'cms' bucket does not exist in Minio"
  echo "Creating cms bucket"
  run_cmd aws s3api create-bucket --bucket cms --endpoint-url http://ncn-m001.nmn:8000
fi

# Unmount, if it is currently mounted
umount "${CMS_MINIO_MNT}" > /dev/null 2>&1

if [[ ! -d ${CMS_MINIO_MNT} ]]; then
  echo "Creating directory '${CMS_MINIO_MNT}'"
  run_cmd mkdir -pv "${CMS_MINIO_MNT}"
fi

credfile=$(run_mktemp /root/.XXXXXX.minio.s3fs) || exit 1

AKEY=$(grep '^aws_access_key_id = ' "${AWS_CREDFILE}" | awk '{ print $NF }') || err_exit "Error getting aws_access_key_id from ${AWS_CREDFILE}"
SKEY=$(grep '^aws_secret_access_key = ' "${AWS_CREDFILE}" | awk '{ print $NF }') || err_exit "Error getting aws_secret_access_key from ${AWS_CREDFILE}"

cat << EOF > "${credfile}" || err_exit "Error writing to '${credfile}'"
${AKEY}:${SKEY}
EOF

run_cmd chmod 600 "${credfile}"
run_cmd s3fs cms "${CMS_MINIO_MNT}" -o "_netdev,${MOUNT_OPT},allow_other,passwd_file=${credfile},url=http://ncn-m001.nmn:8000,use_path_request_style,use_xattr"

echo "CMS minio mount (${CMS_MINIO_MNT}) created"
exit 0
