#! /usr/bin/env bash
#
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
#

set -ue

CMC_XNAME=$1 # x3000c0s17b999

# Verify the provided xname is valid
if [[ ! "${CMC_XNAME}" =~ ^x([0-9]{1,4})c([0-7])s([0-9]+)b999$ ]]; then
    echo "Invalid CMC xname provided: ${CMC_XNAME}"
    echo "Needs to be in the format of xXcCsSb999"
    exit 1
fi


echo "=================================================="
echo "Xname Summary"
echo "=================================================="
echo "CMC: ${CMC_XNAME}"

echo
echo "=================================================="
echo "Removing CMC data from SLS"
echo "=================================================="

echo "Verifying CMC exists in SLS hardware: ${CMC_XNAME}"
if cray sls hardware describe "${CMC_XNAME}" --format json; then
    echo "CMC exists: ${CMC_XNAME}"
else
    echo "CMC does not exist in SLS Hardware: ${CMC_XNAME}"
    exit 1
fi

echo "Deleting CMC from SLS: ${CMC_XNAME}"
cray sls hardware describe "${CMC_XNAME}" --format json
cray sls hardware delete "${CMC_XNAME}"


# Remove from SLS
MGMT_SWITCH_CONNECTOR_RESULT="$(cray sls search hardware list --node-nics "${CMC_XNAME}" --format json)"
if [[ "$(echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq 'length')" -eq 0 ]]; then
    echo "Nothing more to remove as there is no MgmtSwitchConnector associated with ${CMC_XNAME} in SLS"
    exit 0
elif [[ "$(echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq 'length')" -gt 1 ]]; then
    echo "Unexpected number of MgmtSwitchConnectors found in SLS for ${CMC_XNAME}"
    echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq
    exit 1
fi

MGMT_SWITCH_CONNECTOR="$(echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq  -r .[0].Xname)"

echo "Deleting MgmtSwitchConnector from SLS: ${MGMT_SWITCH_CONNECTOR}"
cray sls hardware describe "${MGMT_SWITCH_CONNECTOR}" --format json
cray sls hardware delete "${MGMT_SWITCH_CONNECTOR}"

echo
echo "=================================================="
echo "Removing node data from HSM"
echo "=================================================="

# Remove from HSM
## Disable the Redfish Endpoint
echo "Disabling Redfish Endpoint in HSM: ${CMC_XNAME}"
cray hsm inventory redfishEndpoints update "${CMC_XNAME}" --enabled false --id "${CMC_XNAME}"

## Remove from state components
echo "Deleting component from HSM State Components: ${CMC_XNAME}"
cray hsm state components describe "${CMC_XNAME}" --format json
cray hsm state components delete "${CMC_XNAME}"

# Delete each `NodeBMC` MAC address from the Hardware State Manager \(HSM\) Ethernet interfaces table.
for ID in $(cray hsm inventory ethernetInterfaces list --component-id "${CMC_XNAME}" --format json | jq -r .[].ID); do
    echo "Deleting CMC MAC address: ${ID}"
    cray hsm inventory ethernetInterfaces describe "${ID}" --format json
    cray hsm inventory ethernetInterfaces delete "${ID}"
done

# Delete the Redfish endpoint for the removed node.
echo "Deleting RedfishEndpoint from HSM: ${CMC_XNAME}"
cray hsm inventory redfishEndpoints describe "${CMC_XNAME}" --format json
cray hsm inventory redfishEndpoints delete "${CMC_XNAME}"
