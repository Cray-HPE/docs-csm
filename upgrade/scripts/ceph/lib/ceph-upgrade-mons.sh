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

function upgrade_ceph_mons () {
for host in $(ceph node ls| jq -r '.mon|keys[]')
 do
  #shellcheck disable=SC2154
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
  #shellcheck disable=SC2155
  export verify_mon=$(cephadm ls|jq '.[]|select(.name=="mon.ncn-s001")|.name')
  if [[ "mon.$host" == "$verify_mon" ]]
  then
  echo "Confirmed that $host is running $verify_mon via cephadm"
  fi
 done
}
