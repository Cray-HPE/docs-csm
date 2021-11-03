#!/usr/bin/env bash

TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d \
  client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

ncns=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" \
  "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" |
  jq -r '.[] | ."ExtraProperties" | ."Aliases" | .[]' | sort)

declare -A vlans_to_check
# Do not be tempted to add vlan002 to this list without more checking as there are things like VIPs that should not be
# removed!
vlans_to_check['vlan004']='hmn'
vlans_to_check['vlan007']='can'

for ncn in $ncns; do
  echo "Checking $ncn for incorrect IPs..."

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