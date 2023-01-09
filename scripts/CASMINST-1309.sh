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

# Restart Kea so it doesn't just push the stale entry back in after we delete it.
kubectl -n services rollout restart deployment cray-dhcp-kea

ncns=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | jq -r '.[] | ."ExtraProperties" | ."Aliases" | .[]')

# Just reset all the NCN BMCs
for ncn in $ncns; do
  if [ "$ncn" = "ncn-m001" ]; then
    continue
  fi
  echo "Sending cold reset to $ncn BMC..."
  ssh -o "StrictHostKeyChecking=no" "$ncn" ipmitool mc reset cold
done

bmcs=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management | jq -r '.[] | .Parent')

# Now delete all the BMC entries in EthernetInterfaces with an IP present.
for bmc in $bmcs; do
  bad_ips=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?ComponentID=$bmc" | jq -r '.[] | ."IPAddresses" | .[] | ."IPAddress"')
  for ip in $bad_ips; do
    id=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces?IPAddress=$ip" | jq -r '.[] | ."ID"')

    # Make sure ID isn't blank.
    if [ -z "$id" ]
    then
      echo "$id blank when trying to find an owner for IP $ip!"
    else
      echo "Deleting $id from EthernetInterfaces"...
      curl -X DELETE -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/$id" | jq
    fi
  done
done
