#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

usage() {
        echo "
Usage:

$0 context

context - Description of when the backups are being taken (e.g. 'post_install').
          This string is used for the backup name so the backup can be easily
          identified (e.g. cray-bss/post_install.backup_2022-09-30-20:51:46).
          Note the string proviced for context should contain '_' in order
          for the ncnHealthChecks.sh script to properly parse the timestamp
          from the backup name.
"
}

backup_clusters() {
  context=$1
  clusters=$(kubectl get statefulsets.apps -A | grep bitnami-etcd | awk '{print $2}')
  for c in $clusters; do
    short_name=$(echo $c | awk 'BEGIN{FS=OFS="-"}{NF--; NF--; print}')
    backup_name=$(echo "$context.backup_$(date +%Y-%m-%d-%H:%M:%S)")
    echo "Creating manual etcd backup for '$short_name' named '$backup_name'."
    /opt/cray/platform-utils/etcd/etcd-util.sh create_backup ${short_name} ${backup_name}
  done
}

if [ "$#" -lt 1 ]; then
        usage
        exit 1
fi

context=$1
echo $context | grep -q '_'
if [ $? -ne 0 ]; then
  echo "ERROR: '$context' needs to contain '_' for proper timestamp parsing."
  exit 1
fi

backup_clusters $context
exit 0
