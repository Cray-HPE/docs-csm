#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

(( counter=0 ))

host=$(hostname)

> ~/.ssh/known_hosts

for node in ncn-s001 ncn-s002 ncn-s003; do
  ssh-keyscan -H "$node" >> ~/.ssh/known_hosts
  pdsh -w $node > ~/.ssh/known_hosts
  if [[ "$host" == "$node" ]]; then
    continue
  fi

  if [[ $(nc -z -w 10 $node 22) ]] || [[ $counter -lt 3 ]]
  then
    if [[ "$host" =~ ^("ncn-s001"|"ncn-s002"|"ncn-s003")$ ]]
    then
      scp $node:/etc/ceph/* /etc/ceph
    else
      scp $node:/etc/ceph/rgw.pem /etc/ceph/rgw.pem
    fi

    if [[ ! $(pdsh -w $node "/srv/cray/scripts/common/pre-load-images.sh; ceph orch host rm $host; ceph cephadm generate-key; ceph cephadm get-pub-key > ~/ceph.pub; ssh-keyscan -H $host >> ~/.ssh/known_hosts ;ssh-copy-id -f -i ~/ceph.pub root@$host; ceph orch host add $host") ]]
    then
      (( counter+1 ))
      if [[ $counter -ge 3 ]]
      then
        echo "Unable to access ceph monitor nodes"
        exit 1
      fi
    else
      break
    fi
  fi
done

sleep 30
(( ceph_mgr_failed_restarts=0 ))
(( ceph_mgr_successful_restarts=0 ))
until [[ $(cephadm shell -- ceph-volume inventory --format json-pretty|jq '.[] | select(.available == true) | .path' | wc -l) == 0 ]]
do
  for node in ncn-s001 ncn-s002 ncn-s003; do
    if [[ $ceph_mgr_successful_restarts > 10 ]]
    then
      echo "Failed to bring in OSDs, manual troubleshooting required."
      exit 1
    fi
    if pdsh -w $node ceph mgr fail
    then
      (( ceph_mgr_successful_restarts+1 ))
      sleep 120
      break
    else
      (( ceph_mgr_failed_restarts+1 ))
      if [[ $ceph_mgr_failed_restarts -ge 3 ]]
      then
        echo "Unable to access ceph monitor nodes."
        exit 1
      fi
    fi
  done
done

for service in $(cephadm ls | jq -r '.[].systemd_unit')
do
  systemctl enable $service
done

