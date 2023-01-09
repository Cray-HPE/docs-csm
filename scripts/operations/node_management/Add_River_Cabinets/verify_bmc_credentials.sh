#! /usr/bin/env bash
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

set -u

# For each redfish endpoint
for endpoint in $(cray hsm inventory redfishEndpoints list --laststatus HTTPsGetFailed --format json | jq .RedfishEndpoints[].ID -r); do
    echo
    echo "------------------------------------------------------------"
    echo "Redfish Endpoint $endpoint has discovery state HTTPsGetFailed"
    # Ignore the failure if it is a master node    
    mgmtSwitchConnectorCount=$(cray sls search hardware list --node-nics "$endpoint" --format json  | jq -s 'if . == [] then null else .[0] end | length')
    if [[ "$mgmtSwitchConnectorCount" == "0" ]]; then
        echo "Has no connection to HMN, ignoring"
        continue
    fi

    # See if the BMC resolvable in DNS
    echo "Checking to see if $endpoint resolves in DNS"
    if ! nslookup "$endpoint" > /dev/null; then
        echo "  Hostname does not resolve"
        continue
    else 
        echo "  Hostname resolves"
    fi

    # Check the BMC creds against what is in vault
    echo "Retrieving BMC credentials for $endpoint from SCSD/Vault"
    results=$(cray scsd bmc creds list --targets "$endpoint" --format json | jq .Targets -c)
    if [[ "$results" == "null" ]]; then
        echo "BMC Credentials are missing from vault"
        continue
    fi

    username=$(echo "$results" | jq .[0].Username -r)
    password=$(echo "$results" | jq .[0].Password -r)

    echo "Testing stored BMC credentials against the BMC"
    curl_result=$(curl -k -s -u "$username:$password" "https://${endpoint}/redfish/v1/Managers" -i | head -n 1)
    
    if echo "$curl_result" | grep "200" > /dev/null; then
        echo "  BMC credentials are OK."
        echo "  ERROR Additional investigation is required!"
    else
        if echo "$curl_result" | grep "401" > /dev/null; then
            echo "  ERROR Received 401 Unauthorized. BMC credentials in Vault do not match current BMC credentials."
        else
        echo " ERROR Unexpected HTTP Status code: $curl_result"
        fi
    fi

done
