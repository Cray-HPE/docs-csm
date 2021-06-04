#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -e

#shellcheck disable=SC2155,SC2046
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

URL="https://api_gw_service.local/apis/sls/v1/networks"

function on_error() {
    echo "Error: $1.  Exiting"
    exit 1
}

if ! command -v csi &> /dev/null
then
    echo "csi could not be found in $PATH"
    exit 1
fi

# Collect network information from SLS
nmn_hmn_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR, Gateway: .Subnets.Gateway} | select(.SubnetName==\"network_hardware\") ")
[[ -n ${nmn_hmn_networks} ]] || on_error "Cannot retrieve HMN and NMN networks from SLS. Check SLS connectivity."
cabinet_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR} | select(.SubnetName | startswith(\"cabinet_\")) ")
[[ -n ${cabinet_networks} ]] || on_error "Cannot retrieve cabinet networks from SLS. Check SLS connectivity."

# NMN
nmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"NMN\") | .Gateway")
[[ -n ${nmn_gateway} ]] || on_error "NMN gateway not found"
nmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"NMN\" or .NetworkName==\"NMN_RVR\" or .NetworkName==\"NMN_MTN\") | .SubnetCIDR")
[[ -n ${nmn_cabinet_subnets} ]] || on_error "NMN cabinet subnets not found"

# HMN
hmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"HMN\") | .Gateway")
[[ -n ${hmn_gateway} ]] || on_error "HMN gateway not found"
hmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"HMN\" or .NetworkName==\"HMN_RVR\" or .NetworkName==\"HMN_MTN\") | .SubnetCIDR")
[[ -n ${hmn_cabinet_subnets} ]] || on_error "HMN cabinet subnets not found"


# Format for ifroute-<interface> syntax
nmn_routes=()
for rt in $nmn_cabinet_subnets; do
    nmn_routes+=("$rt $nmn_gateway - vlan002")
done

hmn_routes=()
for rt in $hmn_cabinet_subnets; do
    hmn_routes+=("$rt $hmn_gateway - vlan004")
done

printf -v nmn_routes_string '%s\\n' "${nmn_routes[@]}"
printf -v hmn_routes_string '%s\\n' "${hmn_routes[@]}"

# generate json file for input to csi
cat <<EOF>user-data.json
{
  "user-data": {
    "write_files": [{
        "content": "${nmn_routes_string%,}",
        "owner": "root:root",
        "path": "/etc/sysconfig/network/ifroute-vlan002",
        "permissions": "0644"
      },
      {
        "content": "${hmn_routes_string%,}",
        "owner": "root:root",
        "path": "/etc/sysconfig/network/ifroute-vlan004",
        "permissions": "0644"
      }
    ]
  }
}
EOF

# update bss
csi handoff bss-update-cloud-init --user-data=user-data.json
