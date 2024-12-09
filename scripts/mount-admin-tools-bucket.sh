#!/bin/bash
# MIT License
#
# (C) Copyright [2024] Hewlett Packard Enterprise Development LP
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
set -euo pipefail
# Mount admin-tools S3 bucket
s3_bucket="${S3_BUCKET:-admin-tools}"
s3fs_mount_dir="${S3FS_MOUNT_DIR:-/var/lib/admin-tools}"
s3_user="${S3_USER:-admin-tools}"
s3fs_cache_dir="${S3FS_CACHE_DIR:-/var/lib/s3fs_cache}"
if [ -d ${s3fs_cache_dir} ]; then
  s3fs_opts="use_path_request_style,use_cache=${s3fs_cache_dir},check_cache_dir_exist,use_xattr"
else
  s3fs_opts="use_path_request_style,use_xattr"
fi

echo "Configuring for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"

if [ ! -d "${s3fs_mount_dir}" ]; then
  mkdir -pv "${s3fs_mount_dir}"
fi

pwd_file="/root/.${s3_user}.s3fs"
secret_name="${s3_user}-s3-credentials"
s3_user_credentials="$(
  if ! kubectl get secret "$secret_name" -o json 2> /dev/null | jq -r '.data' 2> /dev/null; then
    echo >&2 "Failed to obtain credential data for user: [$s3_user]"
  fi
)"
if [ -z "$s3_user_credentials" ]; then
  echo "Exiting."
  exit 1
fi
access_key="$(jq -n -r --argjson s3_user_credentials "$s3_user_credentials" '$s3_user_credentials.access_key' | base64 -d)"
secret_key="$(jq -n -r --argjson s3_user_credentials "$s3_user_credentials" '$s3_user_credentials.secret_key' | base64 -d)"
s3_endpoint="$(jq -n -r --argjson s3_user_credentials "$s3_user_credentials" '$s3_user_credentials.http_s3_endpoint' | base64 -d)"
if [ "$access_key" = 'null' ] || [ "$secret_key" = 'null' ] || [ "$s3_endpoint" = 'null' ]; then
  echo >&2 "Failed to find access_key, secret_key, or http_s3_endpoint for [$s3_user]"
  exit 1
fi

echo "${access_key}:${secret_key}" > ${pwd_file}
chmod 600 ${pwd_file}

echo "Mounting bucket: ${s3_bucket} at ${s3fs_mount_dir}"
if ! s3fs ${s3_bucket} ${s3fs_mount_dir} -o passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts}; then
  echo "Error: Check that ${s3_bucket} is not already mounted and ${s3fs_mount_dir} is empty."
  exit 1
fi

echo "Adding fstab entry for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"
if ! grep "${s3_bucket}" /etc/fstab | grep -q "fuse.s3fs"; then
  echo "${s3_bucket} ${s3fs_mount_dir} fuse.s3fs _netdev,allow_other,passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts} 0 0" >> /etc/fstab
else
  echo "An entry in /etc/fstab already exists for ${s3_bucket} ${s3fs_mount_dir} fuse.s3fs"
fi

echo "Set cache pruning for ${s3_bucket} to 5G of the 200G volume (every 2nd hour)"
echo "0 */2 * * * root /usr/bin/prune-s3fs-cache.sh ${s3_bucket} ${s3fs_cache_dir} 5368709120 -silent" > /etc/cron.d/prune-s3fs-${s3_bucket}-cache

echo -e "Done mounting ${s3_bucket} S3 bucket\n"

# Validate S3 bucket has been mounted

echo "/etc/fstab has the following content:"
grep fuse.s3fs /etc/fstab
exit_code=0
if grep "$s3_bucket" /etc/fstab | grep -q "fuse.s3fs"; then
  echo -e "${s3_bucket} was successfully added to /etc/fstab\n"
else
  echo -e "Error: ${s3_bucket} fuse.s3fs mount was not added to the /etc/fstab file\n"
  exit_code=1
fi
echo "The following s3fs mounts exist:"
mount | grep 's3fs on'
if mount | grep -q 's3fs on '"$s3fs_mount_dir"; then
  echo -e "$s3fs_mount_dir is an s3fs mount\n"
else
  echo -e "Error: ${s3fs_mount_dir} is not an s3fs mount.\n"
  exit_code=1
fi

if [ "$exit_code" -eq 0 ]; then
  echo "Successfully mounted ${s3_bucket} bucket"
else
  echo "Errors encountered. Please review script output."
fi
exit $exit_code
