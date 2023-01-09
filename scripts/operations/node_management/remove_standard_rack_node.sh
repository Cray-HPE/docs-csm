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

NODE_XNAME=$1 # x3000c0s17b3n0

# Verify the provided xname is valid
if [[ ! "${NODE_XNAME}" =~ ^x([0-9]{1,4})c([0-7])s([0-9]+)b([0-9]+)n([0-9]+)$ ]]; then
    echo "Invalid node xname provided: ${NODE_XNAME}"
    echo "Needs to be in the format of xXcCsSbBnN"
    exit 1
fi

BMC_XNAME=$(echo "${NODE_XNAME}" | grep -E -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
NODE_ENCLOSURE_XNAME="${BMC_XNAME/b/e}" # Replace bB with eE

# TOKEN is required to be exported for the delete_bmc_subscriptions.py script.
if [[ -z "${TOKEN}" ]]; then
    echo "Environment variable TOKEN is not set"
    exit 1
fi

echo "=================================================="
echo "Xname Summary"
echo "=================================================="
echo "Node:          ${NODE_XNAME}"
echo "NodeBMC:       ${BMC_XNAME}"
echo "NodeEnclosure: ${NODE_ENCLOSURE_XNAME}"

echo
echo "=================================================="
echo "Verifying BMC exists as a RedfishEndpoint in HSM"
echo "=================================================="

if ! cray hsm inventory redfishEndpoints describe "${BMC_XNAME}" --format json; then
    echo "NodeBMC does not exist in HSM RedfishEndpoints: ${BMC_XNAME}"
    exit 1
fi

echo
echo "=================================================="
echo "Removing BMC Event subscriptions"
echo "=================================================="
/usr/share/doc/csm/scripts/operations/node_management/delete_bmc_subscriptions.py "${BMC_XNAME}"

echo
echo "=================================================="
echo "Removing node data from SLS"
echo "=================================================="

# Remove from SLS
MGMT_SWITCH_CONNECTOR_RESULT="$(cray sls search hardware list --node-nics "${BMC_XNAME}" --format json)"


if [[ "$(echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq 'length')" -ne 1 ]]; then
    echo "Unexpected number of MgmtSwitchConnectors found in SLS for ${BMC_XNAME}"
    echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq
    exit 1
fi

MGMT_SWITCH_CONNECTOR="$(echo "${MGMT_SWITCH_CONNECTOR_RESULT}" | jq  -r .[0].Xname)"

echo "Deleting MmgtSwitchConnector from SLS: ${MGMT_SWITCH_CONNECTOR}"
cray sls hardware describe "${MGMT_SWITCH_CONNECTOR}" --format json
cray sls hardware delete "${MGMT_SWITCH_CONNECTOR}"

echo "Deleting Node from SLS: ${NODE_XNAME}"
cray sls hardware describe "${NODE_XNAME}" --format json
cray sls hardware delete "${NODE_XNAME}"

echo
echo "=================================================="
echo "Removing node data from HSM"
echo "=================================================="

# Remove from HSM

## Disable the Redfish Endpoint
echo "Disabling Redfish Endpoint in HSM: ${BMC_XNAME}"
cray hsm inventory redfishEndpoints update "${BMC_XNAME}" --enabled false --id "${BMC_XNAME}"

## Remove from state components
for XNAME in "$NODE_XNAME" "$BMC_XNAME" "${NODE_ENCLOSURE_XNAME}"; do
    echo "Deleting component from HSM State Components: ${XNAME}"
    cray hsm state components describe "${XNAME}" --format json
    cray hsm state components delete "${XNAME}"
done

## Delete the `Node` MAC addresses from the HSM.
for ID in $(cray hsm inventory ethernetInterfaces list --component-id "${NODE_XNAME}" --format json | jq -r .[].ID); do
    echo "Deleting Node MAC address: ${ID}"
    cray hsm inventory ethernetInterfaces describe "${ID}" --format json
    cray hsm inventory ethernetInterfaces delete "${ID}"
done

# Delete each `NodeBMC` MAC address from the Hardware State Manager \(HSM\) Ethernet interfaces table.
for ID in $(cray hsm inventory ethernetInterfaces list --component-id "${BMC_XNAME}" --format json | jq -r .[].ID); do
    echo "Deleting BMC MAC address: ${ID}"
    cray hsm inventory ethernetInterfaces describe "${ID}" --format json
    cray hsm inventory ethernetInterfaces delete "${ID}"
done

# Delete the Redfish endpoint for the removed node.
echo "Deleting RedfishEndpoint from HSM: ${BMC_XNAME}"
cray hsm inventory redfishEndpoints describe "${BMC_XNAME}" --format json
cray hsm inventory redfishEndpoints delete "${BMC_XNAME}"
