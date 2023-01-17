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

# stop the ceph-rgw daemon on all hosts as the command needs the cluster status to be in HEALTH_OK

function upgrade_rgws () {

  for host in $(ceph node ls| jq -r '.osd|keys|join(" ")'); do
    ssh $host 'systemctl stop ceph-radosgw.target && rm -rf /var/lib/ceph/radosgw/ceph-*'
  done

  echo "sleeping 20 seconds to allow for old rgw instances to stop"
  sleep 20
  ceph orch apply rgw site1 zone1 --placement="3 $(ceph node ls|jq -r '.mon|keys| join(" ")')" --port=8080

  while [[ $(ceph health) != "HEALTH_OK" ]]; do
    echo "sleeping 5 seconds before next check"
    sleep 5
  done

  echo "Setting default realm"
  radosgw-admin realm default --rgw-realm=site1


}

function enable_sts () {
  echo "Enabling sts for client.rgw.site1"
  sts_key=$(ceph config get client.rgw.ncn-s001.rgw0 rgw_sts_key)
  ceph config set client.rgw.site1 rgw_s3_auth_use_sts true
  ceph config set client.rgw.site1 rgw_sts_key $sts_key
}
