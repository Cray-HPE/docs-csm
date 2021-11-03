#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

function create_cephadm_keys () {
 echo "Creating cephadm key"
 ceph cephadm generate-key
 ceph cephadm get-pub-key > ~/ceph.pub
 echo "Distributing cephadm key across the Ceph cluster"
 for host in $(ceph node ls | jq -r '.osd|keys[]');
 do echo $host;
  ssh-copy-id -f -i ~/ceph.pub root@$host
 done
}
