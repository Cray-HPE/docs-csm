# Begin OSD conversion.  Run on each node that has OSDS
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

function upgrade_osds () {
for host in $(ceph node ls| jq -r '.osd|keys[]')
 do
  for osd in $(ceph node ls| jq --arg host_key $host -r '.osd[$host_key]|values|tostring|ltrimstr("[")|rtrimstr("]")'| sed "s/,/ /g")
   do
    ssh $host "cephadm --image $registry/ceph/ceph:v15.2.8 adopt --style legacy --name osd.$osd" --skip-pull
   done
 done
}

# End  OSD conversion.  Run on each node that has OSDS

