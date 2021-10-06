#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

function convert_radosgw () {
  echo "Converting radosgw to support Ceph 15.x requirements"
  echo "Verifying that a realm does not exist"
  radosgw-admin realm list
  echo "Creating realm..."
  radosgw-admin realm create --rgw-realm=site1 --default
  echo "Verifying that a zonegroup does not exist"
  radosgw-admin zonegroup list
  echo "Creating zonegroup ..."
  radosgw-admin zonegroup rename --rgw-zonegroup default --zonegroup-new-name=zonegroup1
  radosgw-admin zonegroup list
  echo "Verify Zonegroup got created"
  echo "Rename default zone"

  radosgw-admin zone rename --rgw-zone default --zone-new-name zone1 --rgw-zonegroup zonegroup1
  radosgw-admin zone modify --rgw-realm=site1 --rgw-zonegroup=zonegroup1 --rgw-zone=zone1 --endpoints http://ncn-s001.nmn:8080,http://ncn-s002.nmn:8080,http://ncn-s003.nmn:8080 --master --default
  radosgw-admin zonegroup modify --rgw-realm=site1 --rgw-zonegroup=zonegroup1 --endpoints http://ncn-s001.nmn:8080,http://ncn-s002.nmn:8080,http://ncn-s003.nmn:8080 --master --default
  radosgw-admin zone modify --rgw-realm=site1 --rgw-zonegroup=zonegroup1 --rgw-zone=zone1 --endpoints http://ncn-s001.nmn:8080,http://ncn-s002.nmn:8080,http://ncn-s003.nmn:8080 --master --default
  echo "Create radosgw system user"
  radosgw-admin user create --uid=system --display-name "system" --system
  echo "Commit the changes"
  radosgw-admin period update --commit
  echo "Completed the conversion"
}

function restart_radosgw_daemons () {
  for host in $(ceph node ls| jq -r '.osd|keys[]')
   do
    echo "Restarting ceph-radosgw@rgw.$host.rgw0.service"
    ssh "$host" 'systemctl restart ceph-radosgw@rgw.$hostname.rgw0.service'
    echo "ceph-radosgw@rgw.$host.rgw0.service restarted"
   done
}
