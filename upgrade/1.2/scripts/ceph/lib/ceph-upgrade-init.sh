#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function ceph_upgrade_init () {
 echo "Starting upgrade with initial tasks"
 for host in $(ceph node ls| jq -r '.osd|keys[]')
  do
   ssh $host 'cephadm prepare-host' >> /etc/cray/ceph/cephadm_upgrade_$host.log
  done
 cephadm ls >> /etc/cray/ceph/cephadm_upgrade.log
 echo "assimilating ceph.conf.."
 ceph config assimilate-conf -i /etc/ceph/ceph.conf
 ceph node ls
}
