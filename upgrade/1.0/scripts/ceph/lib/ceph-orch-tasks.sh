#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function ceph_orch_tasks () {
 for host in $(ceph node ls| jq -r '.osd|keys[]')
  do
   echo "Adding $host to the Ceph orchestrator"
   ceph orch host add $host
  done
 ceph orch ps
 ceph orch host ls
}
