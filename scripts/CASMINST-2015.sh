#!/usr/bin/env bash
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

TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d \
  client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

ncns=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" \
  "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" |
  jq -r '.[] | ."ExtraProperties" | ."Aliases" | .[]' | sort)

declare -A vlans_to_check
# Do not be tempted to add bond0.nmn0 to this list without more checking as there are things like VIPs that should not be
# removed!
vlans_to_check['bond0.hmn0']='hmn'
vlans_to_check['bond0.cmn0']='can'

for ncn in $ncns; do
  echo "Checking $ncn for incorrect IP addresses..."

  for vlan in "${!vlans_to_check[@]}"
  do
    network_name=${vlans_to_check[$vlan]}

    current_ips=$(ssh -o "StrictHostKeyChecking=no" "$ncn" "ip -j a show $vlan | jq -r '.[] | .\"addr_info\" |
      .[] | select(.family==\"inet\") | .local'")
    num_ips=$(echo "$current_ips" | wc -l)


    if [ "$num_ips" -gt 1 ]
    then
      # Figure out which is the correct IP for this host and network.
      correct_ip=$(dig +short "$ncn.$network_name")

      for ip in $current_ips
      do
        if [ "$ip" != "$correct_ip" ]
        then
          # Figure out the mask bits for this IP.
          mask_bits=$(ssh -o "StrictHostKeyChecking=no" "$ncn" "ip -j a show $vlan | jq -r '.[] | .\"addr_info\" |
            .[] | select(.family==\"inet\") | select(.local==\"$ip\") | .prefixlen'")

          echo -n "$ip on $vlan is incorrectly assigned, removing..."
          ssh -o "StrictHostKeyChecking=no" "$ncn" ip addr del "$ip/$mask_bits" dev $vlan
          echo "done"
        fi
      done
    fi
  done

done
