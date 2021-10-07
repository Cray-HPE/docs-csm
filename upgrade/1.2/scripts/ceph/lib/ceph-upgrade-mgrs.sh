#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

# Begin run on each mon/mgr

function upgrade_ceph_mgrs () {
for host in $(ceph node ls| jq -r '.mgr|keys[]')
 do
  echo "Converting ceph-mgr to Octopus"
  ssh "$host" "cephadm --image $registry/ceph/ceph:v15.2.8 adopt --style legacy --name mgr.$host" --skip-pull
 done
 echo "Sleeping 20 seconds..."
 sleep 20
 echo "Enabling Ceph orchestrator"
 ceph mgr module enable orchestrator
 echo "Sleeping 20 seconds..."
 sleep 20
 echo "Enabling cephadm manager module"
 ceph mgr module enable cephadm
 echo "Sleeping 20 seconds..."
 sleep 20
 echo "Setting the Ceph orchestrator backend to cephadm"
 ceph orch set backend cephadm

 echo "Verify Ceph orchestrator's backend is cephadm"
 while [[ $avail != "true" ]] && [[ $backend != "cephadm" ]]
 do
  avail=$(ceph orch status -f json-pretty|jq .available)
  backend=$(ceph orch status -f json-pretty|jq -r .backend)
done
echo "Ceph orchestrator has been set to backend $backend and its availability is : $avail"
}
