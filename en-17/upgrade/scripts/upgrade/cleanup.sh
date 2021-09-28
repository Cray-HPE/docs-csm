#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

# Export a keycloak token so we can access BSS.
TOKEN=$(curl -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN

python3 /usr/share/doc/csm/upgrade/scripts/upgrade/cleanup.py

# Remove the upgrade file from all NCN hosts.
ncns=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ',')
pdsh -S -b -w ${ncns} "rm -f /etc/cray/kubernetes/upgrade"
