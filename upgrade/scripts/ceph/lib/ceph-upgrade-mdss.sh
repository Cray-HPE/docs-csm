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

# Begin OSD conversion. Run on each node that has OSDs
#

. ./lib/ceph-health.sh

function repair_cephfs () {
  echo "Beginning repair process for cephfs"

  echo "Running cephfs-journal-tool event recover_dentries summary"
  cephfs-journal-tool --rank=cephfs:0 event recover_dentries summary

  echo "Running cephfs-journal-tool journal reset"
  cephfs-journal-tool --rank=cephfs:0 journal reset

  echo "ceph mds repaired cephfs:0"
  ceph mds repaired cephfs:0
}

function upgrade_mds () {

  ceph fs ls
  ceph orch ps --daemon-type mds
  ceph fs status

  date=$(date +%m%d%y.%H%M)

  echo "Backing up the Ceph MDS Journal"
  for mds_node in $(ceph mds metadata -f json-pretty|jq -r '.[].name'|cut -d . -f 2)
  do
    pdsh -w $mds_node cephfs-journal-tool --rank cephfs:all journal export /root/backup."$date".bin
  done
  #shellcheck disable=SC2155
  export standby_mdss=$(ceph fs dump -f json-pretty|jq -r '.standbys|map(.name)|join(" ")')
  #shellcheck disable=SC2155
  export active_mds=$(ceph fs status -f json-pretty|jq -r '.mdsmap[]|select(.state=="active")|.name')
  export mds_cluster="$active_mds $standby_mdss"

  ceph fs set cephfs max_mds 1
  ceph fs set cephfs allow_standby_replay false
  ceph fs set cephfs standby_count_wanted 0

  echo "Active MDS is: $active_mds"
  echo "Standby MDS(s) are: $standby_mdss"

  ceph orch apply mds cephfs --placement="3 $(ceph node ls |jq -r '.mon|map(.[])|join(" ")')"

  wait_for_running_daemons mds 3

  for host in $mds_cluster
  do
   echo "Stopping mds service on $host"
   ssh "$host" "systemctl stop ceph-mds.target"
   echo "Cleaning up /var/lib/ceph/mds/ceph-* on $host"
   ssh "$host" "rm -rf /var/lib/ceph/mds/ceph-*"
  done

  ceph fs set cephfs standby_count_wanted 2
  ceph fs set cephfs allow_standby_replay true
  wait_for_health_ok

  fsmap_in=$(ceph status -f json-pretty |jq '.fsmap.in')
  fsmap_up=$(ceph status -f json-pretty |jq '.fsmap.up')

  echo "Checking to see if mds file system is healthy"
  if [[ $fsmap_in -ne $fsmap_up ]]; then
    repair_cephfs
  fi

  ceph orch ps --daemon-type mds
}
