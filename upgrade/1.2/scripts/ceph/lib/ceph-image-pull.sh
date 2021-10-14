#!/bin/bash
# Pre-pull images for upgrade so we can live without nexus during upgrade
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function pre_pull_ceph_images () {
  IMAGE="$registry/ceph/ceph:v15.2.8"
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    echo "Pre-pulling $IMAGE image on $host"
    ssh "$host" "cephadm --image $IMAGE pull"
    echo "Verify the image on present on $host"
    ssh "$host" "podman image inspect $IMAGE > /dev/null 2>&1 && echo -e 'Image $IMAGE is present on $host'|| echo 'Image is missing exiting script'; exit 1"
    echo -e "\n"
  done
}
