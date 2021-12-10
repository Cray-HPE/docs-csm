#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Begin run on each mon/mgr

function upgrade_ceph_mons () {
for host in $(ceph node ls| jq -r '.mon|keys[]')
 do
  ssh "$host" "cephadm --image $registry/ceph/ceph:v15.2.8 adopt --style legacy --name mon.$host" --skip-pull
  (( counter=0 ))
  #while [ $(ceph -f json-pretty orch ps|jq -r '.[]|select(.daemon_type|test("mon"))|select(.hostname|test("ncn-s001"))'|jq -r .status_desc) != "running" ]
  while [[ $(ceph health -f json-pretty|jq -r .status) != "HEALTH_OK" ]]
  do
   echo "sleeping 5 seconds to allow services to start on $host"
   sleep 5
   ((counter++))
   if [ "$counter" -gt 120 ]
   then
   break
   fi
  done
  echo "Confirming the MON daemon is bootstrapped by cephadm"
  export verify_mon=$(cephadm ls|jq '.[]|select(.name=="mon.ncn-s001")|.name')
  if [[ "mon.$host" == "$verify_mon" ]]
  then
  echo "Confirmed that $host is running $verify_mon via cephadm"
  fi
 done
}
