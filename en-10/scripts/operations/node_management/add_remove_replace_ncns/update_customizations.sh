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
set -eu
set -o pipefail

if [[ -z "$TOKEN" ]]; then
    echo "Error: TOKEN enviroment variable not set"
    exit 1
fi

# Set temporary working directory
tmp_dir="/tmp"
echo "Working directory $tmp_dir"
pushd "$tmp_dir"

# Grab customizations.yaml
kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
cp customizations.yaml customizations.original.yaml

# Update Storage NCN IPs
storage_ips=$(curl --fail -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks/NMN | 
    jq '[.ExtraProperties.Subnets[] |  select(.Name == "bootstrap_dhcp").IPReservations[] | select(.Name | startswith("ncn-s")).IPAddress] | sort')

yq merge -a overwrite -xP -i customizations.yaml <(echo "$storage_ips" | yq prefix -P - spec.network.netstaticips.nmn_ncn_storage)

# Update Master NCN IPs
master_ips=$(curl --fail -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks/NMN | 
    jq '[.ExtraProperties.Subnets[] |  select(.Name == "bootstrap_dhcp").IPReservations[] | select(.Name | startswith("ncn-m")).IPAddress] | sort')

yq merge -a overwrite -xP -i customizations.yaml <(echo "$master_ips" | yq prefix -P - spec.network.netstaticips.nmn_ncn_masters)

echo "Original customizations.yaml is located at $tmp_dir/customizations.original.yaml"
echo "Updated customizations.yaml is located at $tmp_dir/customizations.yaml"

