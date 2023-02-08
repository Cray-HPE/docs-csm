#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

#!/bin/bash

host=$(hostname)
host_ip=$(host ${host} | awk '{ print $NF }')

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

# add ssh key to m001, then update ssh keys for rebuilt node on m001
m001_ip=$(host ncn-m001 | awk '{ print $NF }')
ssh-keyscan -H ncn-m001,${m001_ip} >> ~/.ssh/known_hosts
ssh ncn-m001 "ssh-keygen -R $host -f ~/.ssh/known_hosts > /dev/null 2>&1; ssh-keygen -R $host_ip -f ~/.ssh/known_hosts > /dev/null 2>&1; ssh-keyscan -H ${host},${host_ip} >> ~/.ssh/known_hosts"

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

# run preload images on host
echo "Running pre-load-images on $host"
if [[ ! $(/srv/cray/scripts/common/pre-load-images.sh) ]]; then
  echo "ERROR  Unable to run pre-load-images.sh on $host."
fi

sleep 30
(( ceph_mgr_failed_restarts=0 ))
(( ceph_mgr_successful_restarts=0 ))
until [[ $(cephadm shell -- ceph-volume inventory --format json-pretty|jq '.[] | select(.available == true) | .path' | wc -l) == 0 ]]
do
  for node in ncn-s001 ncn-s002 ncn-s003; do
    if [[ $ceph_mgr_successful_restarts -gt 15 ]]
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

# check if node-exporter needs to be restarted
status=$(ceph --name client.ro orch ps $host --format json | jq '.[] | select(.daemon_type == "node-exporter") | .status_desc' | tr -d '"')
if [[ $status != "running" ]]; then
  for node in ncn-s001 ncn-s002 ncn-s003; do
    ssh $node "ceph orch daemon restart node-exporter.${host}"
    if [[ $? -eq 0 ]]; then break; fi
  done
fi

for service in $(cephadm ls | jq -r '.[].systemd_unit')
do
  systemctl enable $service
done
echo "Completed adding $host to ceph cluster."
echo "Checking haproxy and keepalived..."
# check rgw and haproxy are functional
res_file=$(mktemp)
http_code=$(curl -k -s -o "${res_file}" -w "%{http_code}" "https://rgw-vip.nmn")
if [[ ${http_code} != 200 ]]; then
  echo "NOTICE Rados GW and haproxy are not healthy. Deploy RGW on rebuilt node."
fi
# check keepalived is active
if [[ $(systemctl is-active keepalived.service) != "active" ]]; then
  echo "NOTICE keepalived is not active on $host. Add node to Haproxy and Keepalived."
fi

# fix spire and restart cfs
echo "Fixing spire and restarting cfs-state-reporter"
scp ncn-m001:/etc/kubernetes/admin.conf /etc/kubernetes/admin.conf
ssh ncn-m001 '/opt/cray/platform-utils/spire/fix-spire-on-storage.sh'
systemctl restart cfs-state-reporter.service