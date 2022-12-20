#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

host=$(hostname)
host_ip=$(host ${host} | awk '{ print $NF }')

# run preload images on host
if [[ ! $(/srv/cray/scripts/common/pre-load-images.sh) ]]; then
  echo "Unable to run pre-load-images.sh on $host."
fi

# update ssh keys for rebuilt node on host and on ncn-s001/2/3
truncate --size=0 ~/.ssh/known_hosts 2>&1
for node in ncn-s001 ncn-s002 ncn-s003; do
  if ! host ${node}; then
    echo "Unable to get IP address of $node"
    exit 1
  else
    ncn_ip=$(host ${node} | awk '{ print $NF }')
  fi
  # add new authorized_hosts entry for the node
  ssh-keyscan -H "${node},${ncn_ip}" >> ~/.ssh/known_hosts
  
  if [[ "$host" != "$node" ]]; then
    ssh $node "if [[ ! -f ~/.ssh/known_hosts ]]; then > ~/.ssh/known_hosts; fi; ssh-keygen -R $host -f ~/.ssh/known_hosts > /dev/null 2>&1; ssh-keygen -R $host_ip -f ~/.ssh/known_hosts > /dev/null 2>&1; ssh-keyscan -H ${host},${host_ip} >> ~/.ssh/known_hosts"
  fi
done

# copy necessary ceph files to rebuilt node
(( counter=0 ))
for node in ncn-s001 ncn-s002 ncn-s003; do
  if [[ "$host" == "$node" ]]; then
    (( counter+1 ))
  elif [[ $(nc -z -w 10 $node 22) ]] || [[ $counter -lt 3 ]]
  then
    if [[ "$host" =~ ^("ncn-s001"|"ncn-s002"|"ncn-s003")$ ]]
    then
      scp $node:/etc/ceph/* /etc/ceph
    else
      scp $node:/etc/ceph/\{rgw.pem,ceph.conf,ceph_conf_min,ceph.client.ro.keyring\} /etc/ceph/
    fi
             
    if [[ ! $(pdsh -w $node "ceph orch host rm $host; ceph cephadm generate-key; ceph cephadm get-pub-key > ~/ceph.pub; ssh-copy-id -f -i ~/ceph.pub root@$host; ceph orch host add $host") ]]
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

# check rgw and haproxy are functional
res_file=$(mktemp)
http_code=$(curl -k -s -o "${res_file}" -w "%{http_code}" "https://rgw-vip.nmn")
if [[ ${http_code} != 200 ]]; then
  echo "ERROR Rados GW and haproxy are not healthy. Deploy RGW on rebuilt node."
  exit 1
fi
# check keepalived is active
if [[ $(systemctl is-active keepalived.service) != "active" ]]; then
  echo "ERROR keepalived is not active on $host. Add node to Haproxy and Keepalived."
  exit 1
fi