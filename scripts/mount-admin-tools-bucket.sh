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

# Mount admin-tools S3 bucket
s3_bucket="admin-tools"
s3fs_mount_dir="/var/lib/admin-tools"
s3_user="admin-tools"

s3fs_cache_dir=/var/lib/s3fs_cache
if [ -d ${s3fs_cache_dir} ]; then
  s3fs_opts="use_path_request_style,use_cache=${s3fs_cache_dir},check_cache_dir_exist,use_xattr"
else
  s3fs_opts="use_path_request_style,use_xattr"
fi

echo "Configuring for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"

mkdir -p ${s3fs_mount_dir}

pwd_file=/root/.${s3_user}.s3fs
access_key=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.access_key' | base64 -d)
secret_key=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.secret_key' | base64 -d)
s3_endpoint=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.http_s3_endpoint' | base64 -d)

echo "${access_key}:${secret_key}" > ${pwd_file}
chmod 600 ${pwd_file}

echo "Mounting bucket: ${s3_bucket} at ${s3fs_mount_dir}"
s3fs ${s3_bucket} ${s3fs_mount_dir} -o passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts}

echo "Adding fstab entry for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"
if [[ -z $(cat /etc/fstab | grep "admin-tools" | grep "fuse.s3fs") ]]; then
  echo "${s3_bucket} ${s3fs_mount_dir} fuse.s3fs _netdev,allow_other,passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts} 0 0" >> /etc/fstab
else
  echo "An entry in /etc/fstab already exists for ${s3_bucket} ${s3fs_mount_dir} fuse.s3fs"
fi

echo "Set cache pruning for admin tools to 5G of the 200G volume (every 2nd hour)"
echo "0 */2 * * * root /usr/bin/prune-s3fs-cache.sh admin-tools ${s3fs_cache_dir} 5368709120 -silent" > /etc/cron.d/prune-s3fs-admin-tools-cache

echo -e "Done mounting admin-tools S3 bucket\n"

# Validate admin-tools S3 bucket has been mounted

echo "/etc/fstab has the following content:"
grep fuse.s3fs /etc/fstab
exit_code=0
if [[ -n $(cat /etc/fstab | grep "admin-tools" | grep "fuse.s3fs") ]]; then
  echo -e "admin-tools was successfully added to /etc/fstab\n"
else
  echo -e "Error: admin-tools fuse.s3fs mount was not added to the /etc/fstab file\n"
  exit_code=1
fi
echo "The following s3fs mounts exist:"
mount | grep 's3fs on'
if [[ -n $(mount | grep 's3fs on /var/lib/admin-tools') ]]; then
  echo -e "/var/lib/admin-tools is a s3fs mount\n"
else
  echo -e "Error: /var/lib/admin-tools is not a s3fs mount.\n"
  exit_code=1
fi

if [[ $exit_code == 0 ]]; then
  echo "Successfully mounted admin-tools bucket"
fi
exit $exit_code
