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

# Begin run on each mon/mgr

function upgrade_ceph_mgrs () {
for host in $(ceph node ls| jq -r '.mgr|keys[]')
 do
  echo "Converting ceph-mgr to Octopus"
  #shellcheck disable=SC2154
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
