#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

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
