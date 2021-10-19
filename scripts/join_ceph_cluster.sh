#!/bin/bash

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

