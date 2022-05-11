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

(( counter=0 ))

host=$(hostname)

truncate --size=0 ~/.ssh/known_hosts  2>&1

/srv/cray/scripts/common/pre-load-images.sh

function gather_ceph_conf () {
  FSID=$(ssh $node 'ceph -s --format=json-pretty|jq -r .fsid')
  WAS_MON=$(ssh $node ceph node ls|jq -r --arg h $host 'any(.mon|keys; .[] == $h)')
  if [[ "$WAS_MON" != "true" ]]; then 
    WAS_MON="false"
  fi
  WAS_OSD=$(ssh $node ceph node ls|jq -r --arg h $host 'any(.osd|keys; .[] == $h)')
  if [[ "$WAS_OSD" != "true" ]]; then 
    WAS_OSD="false"
  fi
  if [[ "$WAS_OSD" == "true" ]]
  then
    OSDS+=($(ssh $node "ceph osd ls-tree $host"))
  fi
  CONF=$(ssh $node ceph config generate-minimal-conf)
  echo "fsid $FSID"
  echo "OSDS ${OSDS[@]}"
  echo "WAS_MON $WAS_MON"
  echo "WAS_OSD $WAS_OSD"

}

function apply_ceph_conf () {
  if [[ "$WAS_OSD" == "true" ]]
  then
    if [[ ! -d /var/lib/ceph/$FSID ]]
    then
      if [[ ! $(mkdir /var/lib/ceph/$FSID) ]]
      then
        echo "Unable to create /var/lib/ceph/$FSID directory"
        exit 1
      fi
    fi
    for osd in ${OSDS[@]}
    do
      if [[ ! -d /var/lib/ceph/$FSID/osd.$osd ]]
      then
        if [[ ! $(mkdir /var/lib/ceph/$FSID/osd.$osd) ]]
        then
          echo "Unable to create /var/lib/ceph/$FSID/osd.$osd directory"
          exit 1
        fi
      fi
      echo "$CONF" > /var/lib/ceph/$FSID/osd.$osd/config
    done
  fi
}

(( loop_counter=0 ))
(( counter_a=0 ))

for node in ncn-s001 ncn-s002 ncn-s003; do

  if [[ $counter -eq 0 ]] && nc -z -w 10 $node 22
    then
      ssh-keygen -R "$node"
      ssh-keyscan -H "$node" >> ~/.ssh/known_hosts
      if [[ "$host" =~ ^("ncn-s001"|"ncn-s002"|"ncn-s003")$ ]] && [[ "$host" != "$node" ]]
      then
        scp $node:/etc/ceph/* /etc/ceph
      elif [[ "$host" != "$node" ]]
      then
        scp $node:/etc/ceph/rgw.pem /etc/ceph/rgw.pem
      else
        continue
      fi

      gather_ceph_conf
      apply_ceph_conf

      if [[ "$WAS_OSD" == "true" ]]
      then
        if [[ $counter_a -eq 0 ]] && [[ $(ssh $node "ceph orch host rm $host") ]]
        then
          (( counter_a+=1 ))
        fi
      fi

      if [[ $WAS_MON == "true" ]]
      then
	ssh $node "ceph mon rm $host"
      fi

      if [[ ! $(ssh -o StrictHostKeyChecking=no $node "ceph cephadm generate-key; ceph cephadm get-pub-key > ~/ceph.pub; ssh-keygen -R $host; ssh-keyscan -H $host >> ~/.ssh/known_hosts ;ssh-copy-id -f -i ~/ceph.pub root@$host; ceph orch host add $host") ]]
      then
        if [[ "$node" =~ "ncn-s003" ]]
        then
          echo "Unable to access ceph monitor nodes"
          exit 1
        else
          continue
        fi
      else
        (( counter+=1 ))
      fi
  fi

sleep 30

if [[ $WAS_OSD == "false" ]]
then
  (( ceph_mgr_failed_restarts=0 ))
  (( ceph_mgr_successful_restarts=0 ))
  until [[ $(cephadm shell -- ceph-volume inventory --format json-pretty|jq '.[] | select(.available == true) | .path' | wc -l) == 0 ]]
  do
      if [[ $ceph_mgr_successful_restarts > 10 ]]
      then
        echo "Failed to bring in OSDs, manual troubleshooting required."
        exit 1
      fi
      if ssh -o StrictHostKeyChecking=no $node ceph mgr fail
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
fi

if $WAS_OSD
then
    if [[ "$host" != "$node" ]]
    then
      active_mgr=$(ssh $node "ceph mgr dump|jq -r '.active_name'")
      ssh $node ceph mgr fail
      until [[ "$active_mgr" != $(ssh $node "ceph mgr dump|jq '.active_name'") ]]
      do
         sleep 15
      done
      for osd in ${OSDS[@]}
      do
         echo "redeploying osd.$osd"
         ssh $node "ceph orch daemon redeploy osd.$osd"
         (( loop_counter+=1 ))
         sleep 5
     done
     if [[ $loop_counter -ge 1 ]]
     then
       break
     fi
  fi
fi
echo “loop counter: $loop_counter”
done

num_storage_nodes=$(craysys metadata get num_storage_nodes)

if [ ! -f "/etc/ceph/ceph.client.ro.keyring" ]
then
  truncate --size=0 ~/.ssh/known_hosts  2>&1
  echo "*** num of storage nodes $num_storage_nodes"
  for node in $(seq 1 $num_storage_nodes); do
   nodename=$(printf "ncn-s%03d.nmn" $node)
   echo "****** ssh-keyscan $nodename"
   ssh-keyscan -t rsa -H $nodename >> ~/.ssh/known_hosts
  done

  for node in $(seq 1 $num_storage_nodes); do
   nodename=$(printf "ncn-s%03d.nmn" $node)
    if [[ $(scp $nodename:/etc/ceph/ceph.client.ro.keyring /etc/ceph/ceph.client.ro.keyring) ]]
    then
      break
    fi
  done
fi

if  [ ! -f "/etc/ceph/ceph.conf" ]
then
  for node in $(seq 1 $num_storage_nodes); do
    nodename=$(printf "ncn-s%03d.nmn" $node)
    if [[ $(scp $nodename:/etc/ceph/ceph.conf /etc/ceph/ceph.conf) ]]
    then
      break
    fi
  done
fi

for service in $(cephadm ls | jq -r '.[].systemd_unit'|grep -v cephadm)
do
  systemctl enable $service
  is_active=null
  until [[ "$is_active" == "active" ]]
  do 
    is_active=$(systemctl is-active $service)
  done
done
