#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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
