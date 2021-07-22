#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Begin OSD conversion. Run on each node that has OSDs

function upgrade_osds () {
for host in $(ceph node ls| jq -r '.osd|keys[]')
 do
  for osd in $(ceph node ls| jq --arg host_key "$host" -r '.osd[$host_key]|values|tostring|ltrimstr("[")|rtrimstr("]")'| sed "s/,/ /g")
   do
    timeout 300 ssh "$host" "cephadm --image $registry/ceph/ceph:v15.2.8 adopt --style legacy --name osd.$osd" --skip-pull
    if [ $? -ne 0 ]
       then
	ceph mgr fail $(ceph mgr dump | jq -r .active_name)
    fi
    sleep 10
   done
   sleep 180
 done
 ceph osd require-osd-release octopus
}

# End  OSD conversion. Run on each node that has OSDs

