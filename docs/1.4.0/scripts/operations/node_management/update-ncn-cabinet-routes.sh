#! /usr/bin/env bash
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

URL="https://api-gw-service-nmn.local/apis/sls/v1/networks"

function on_error() {
    echo "Error: $1. Exiting"
    exit 1
}

[[ -n ${TOKEN} ]] || on_error "Environment varaible TOKEN is not set"

# Collect network information from SLS
echo "Collecting networking information from SLS"
nmn_hmn_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR, Gateway: .Subnets.Gateway} | select(.SubnetName==\"network_hardware\") ")
[[ -n ${nmn_hmn_networks} ]] || on_error "Cannot retrieve HMN and NMN networks from SLS. Check SLS connectivity."

cabinet_networks=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetName: .Subnets.Name, SubnetCIDR: .Subnets.CIDR} | select(.SubnetName | startswith(\"cabinet_\")) ")
[[ -n ${cabinet_networks} ]] || on_error "Cannot retrieve cabinet networks from SLS. Check SLS connectivity."

# NMN
nmnlb=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetCIDR: .Subnets.CIDR} | select(.NetworkName==\"NMNLB\")")

nmnlb_cidr=$(echo $nmnlb | jq -r .SubnetCIDR)
[[ -n ${nmnlb_cidr} ]] || on_error "NMN LB CIDR not found"

nmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"NMN\") | .Gateway")
[[ -n ${nmn_gateway} ]] || on_error "NMN gateway not found"

nmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"NMN\" or .NetworkName==\"NMN_RVR\" or .NetworkName==\"NMN_MTN\") | .SubnetCIDR")
[[ -n ${nmn_cabinet_subnets} ]] || on_error "NMN cabinet subnets not found"

# HMN
hmnlb=$(curl -k -H "Authorization: Bearer ${TOKEN}" ${URL} 2>/dev/null | jq ".[] | {NetworkName: .Name, Subnets: .ExtraProperties.Subnets[]} | { NetworkName: .NetworkName, SubnetCIDR: .Subnets.CIDR} | select(.NetworkName==\"HMNLB\")")
hmnlb_cidr=$(echo $hmnlb | jq -r .SubnetCIDR)
[[ -n ${hmnlb_cidr} ]] || on_error "HMN LB CIDR not found"
hmn_gateway=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"HMN\") | .Gateway")
[[ -n ${hmn_gateway} ]] || on_error "HMN gateway not found"
hmn_cabinet_subnets=$(echo "${cabinet_networks}" | jq -r ". | select(.NetworkName==\"HMN\" or .NetworkName==\"HMN_RVR\" or .NetworkName==\"HMN_MTN\") | .SubnetCIDR")
[[ -n ${hmn_cabinet_subnets} ]] || on_error "HMN cabinet subnets not found"

# MTL
mtl_cidr=$(echo "${nmn_hmn_networks}" | jq -r ". | select(.NetworkName==\"MTL\") | .SubnetCIDR")
[[ -n ${mtl_cidr} ]] || on_error "MTL CIDR not found"

# Create the routing files first so we can fan it out to all the NCNs later.
local_nmn_route_file="./ifroute-bond0.nmn0"
local_hmn_route_file="./ifroute-bond0.hmn0"
rm -f $local_nmn_route_file
rm -f $local_hmn_route_file
touch $local_nmn_route_file
touch $local_hmn_route_file

# Format for ifroute-<interface> syntax
nmn_routes=()
for rt in $nmn_cabinet_subnets; do
    nmn_routes+=("$rt $nmn_gateway - bond0.nmn0")
done
nmn_routes+=("$mtl_cidr $nmn_gateway - bond0.nmn0")
nmn_routes+=("$nmnlb_cidr $nmn_gateway - bond0.nmn0")

hmn_routes=()
for rt in $hmn_cabinet_subnets; do
    hmn_routes+=("$rt $hmn_gateway - bond0.hmn0")
done
hmn_routes+=("$hmnlb_cidr $hmn_gateway - bond0.hmn0")

printf -v nmn_routes_string '%s\n' "${nmn_routes[@]}"
printf -v hmn_routes_string '%s\n' "${hmn_routes[@]}"

echo "Contents of $local_nmn_route_file"
echo "${nmn_routes_string}"
echo
echo "Contents of $local_hmn_route_file"
echo "${hmn_routes_string}"
echo

echo "Writing $local_nmn_route_file"
echo -n "${nmn_routes_string}" > $local_nmn_route_file
echo "Writing $local_hmn_route_file"
echo -n "${hmn_routes_string}" > $local_hmn_route_file

echo "Querying SLS for Management NCNs"
ncns=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | jq -r '.[] | ."ExtraProperties" | ."Aliases" | .[]' | sort)

for ncn in $ncns; do
  echo "Adding routes to $ncn."

  # Create backup of ifroute files
  echo "Creating backup of existing ifroute files"
  ssh -o "StrictHostKeyChecking=no" "$ncn" "if [ -e /etc/sysconfig/network/ifroute-bond0.nmn0 ]; then cp /etc/sysconfig/network/ifroute-bond0.nmn0 /etc/sysconfig/network/orig-ifroute-bond0.nmn0;fi"
  ssh -o "StrictHostKeyChecking=no" "$ncn" "if [ -e /etc/sysconfig/network/ifroute-bond0.hmn0 ]; then cp /etc/sysconfig/network/ifroute-bond0.hmn0 /etc/sysconfig/network/orig-ifroute-bond0.hmn0;fi"

  echo "Adding cabinet routes"
  for rt in $nmn_cabinet_subnets; do
    ssh -o "StrictHostKeyChecking=no" "$ncn" ip route add "$rt" via "$nmn_gateway"
  done
  for rt in $hmn_cabinet_subnets; do
    ssh -o "StrictHostKeyChecking=no" "$ncn" ip route add "$rt" via "$hmn_gateway"
  done

  echo "Copying updated ifroute files into place"
  scp $local_nmn_route_file "$ncn:/etc/sysconfig/network/ifroute-bond0.nmn0"
  scp $local_hmn_route_file "$ncn:/etc/sysconfig/network/ifroute-bond0.hmn0"
done