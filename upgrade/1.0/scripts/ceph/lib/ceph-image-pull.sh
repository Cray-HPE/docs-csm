# Pre-pull images for upgrade so we can live without nexus during upgrade

function pre_pull_ceph_images () {
  IMAGE="$registry/ceph/ceph:v15.2.8"
  for host in $(ceph node ls| jq -r '.osd|keys[]'); do
    echo "Pre-pulling $IMAGE image on $host"
    ssh $host "cephadm --image $IMAGE pull"
  done
}
