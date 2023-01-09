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

# Many of our functions do not check return codes because they assume that
# they are being run with set -e. This file is used in isolation at one
# point during the upgrade procedure, thus it is important that we verify
# return codes here.

# This helper function just prints an error message
function update_bss_storage_error() {
    echo "update_bss_storage: ERROR: $*" 1>&2
}

# This helper function just prints an error message that a command failed
function update_bss_storage_cmd_failed() {
    update_bss_storage_error "Command failed: $*"
}

# This helper function just prints an error message that a command passed
# but gave blank output
function update_bss_storage_cmd_blank() {
    update_bss_storage_error "Command passed but gave blank output: $*"
}

# This helper function takes a command and arguments as its arguments,
# runs it, prints an error message to stderr if the command failed, and then
# returns the return code from the command.
function update_bss_storage_run_cmd() {
    local rc
    "$@"
    rc=$?
    if [ $rc -ne 0 ]; then
        update_bss_storage_cmd_failed "$@"
    fi
    return $rc
}

# This is a wrapper around the previous helper function, which adds a
# verification that the command gave output to stdout. If it does not,
# an error message is printed to stderr and this function returns 1.
# Otherwise this function is essentially a passthrough to the
# above helper function
function update_bss_storage_run_cmd_verify_nonblank() {
    local rc out
    out=$(update_bss_storage_run_cmd "$@")
    rc=$?
    [ -z "$out" ] || echo "$out"
    if [ $rc -ne 0 ]; then
        return $rc
    elif [ -z "$out" ]; then
        update_bss_storage_cmd_blank "$@"
        return 1
    fi
    
    return 0
}

function update_bss_storage() {
    local curl_out k8s_secret node_num num_storage_nodes rc secret xName TOKEN
    k8s_secret=$(update_bss_storage_run_cmd_verify_nonblank kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}') || return 1
    if ! secret=$(echo "${k8s_secret}" | base64 -d) ; then
        update_bss_storage_cmd_failed echo "${k8s_secret}" \| base64 -d
        return 1
    elif [ -z "$secret" ]; then
        update_bss_storage_cmd_blank echo "${k8s_secret}" \| base64 -d
        return 1
    fi
    curl_out=$(update_bss_storage_run_cmd_verify_nonblank curl -s -k -S -d grant_type=client_credentials \
                       -d client_id=admin-client -d client_secret="$secret" \
                       https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token) || return 1
    #shellcheck disable=SC2155
    export TOKEN=$(echo "$curl_out" | jq -r '.access_token')
    if [ $? -ne 0 ]; then
        update_bss_storage_cmd_failed echo "$curl_out" \| jq -r '.access_token'
        return 1
    elif [ -z "$TOKEN" ]; then
        update_bss_storage_cmd_blank echo "$curl_out" \| jq -r '.access_token'
        return 1
    fi
    num_storage_nodes=$(update_bss_storage_run_cmd_verify_nonblank craysys metadata get num-storage-nodes) || return 1
    if [[ ! "$num_storage_nodes" =~ ^[1-9][0-9]*$ ]] ; then
        update_bss_storage_error "Command 'craysys metadata get num-storage-nodes' should give a positive integer but it gave '$num_storage_nodes'"
        return 1
    fi
    echo "update_bss_storage: Found ${num_storage_nodes} storage nodes"
    for node_num in $(seq $num_storage_nodes); do
        storage_node=$(printf "ncn-s%03d" "$node_num")
        echo -e "\nupdate_bss_storage: Processing ${storage_node}"
        status=$(pdsh -N -w $storage_node "systemctl is-active cray-node-exporter" 2>/dev/null)
        if [ "$status" == "active" ]; then
          pdsh -N -w $storage_node "systemctl stop cray-node-exporter.service; systemctl disable cray-node-exporter.service"
        fi
        xName=$(update_bss_storage_run_cmd_verify_nonblank ssh -q -o StrictHostKeyChecking=no $storage_node 'cat /etc/cray/xname') || return 1
        cray bss bootparameters list --name $xName --format=json | jq '.[]' > /tmp/$xName
        if [ $? -ne 0 ]; then
            update_bss_storage_cmd_failed cray bss bootparameters list --name $xName --format=json \| jq '.[]' \> /tmp/$xName
            return 1
        fi

        # Even if this string is not found in the file, the sed command will succeed (and simply do nothing)
        update_bss_storage_run_cmd sed -i '/cray-node-exporter-1[.]2[.]2/d' /tmp/$xName || return 1

        if ! grep -q pre-load-images.sh /tmp/$xName; then
            update_bss_storage_run_cmd sed -i \
                '/"\/srv\/cray\/scripts\/common\/update_ca_certs.py"/a \        "\/srv\/cray\/scripts\/common\/pre-load-images.sh",' \
                /tmp/$xName || return 1
        fi

        if [ "$storage_node" = ncn-s001 ]; then
            update_bss_storage_run_cmd sed -i '/storage-ceph-cloudinit.sh/d' /tmp/$xName || return 1
        fi

        echo "update_bss_storage: Putting updated bootparameters for ${storage_node}"
        curl -i -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
            -X PUT -d @/tmp/$xName > /tmp/put.$xName
        rc=$?
        if [ $rc -ne 0 ]; then
            cat /tmp/put.$xName
            update_bss_storage_cmd_failed curl -i -s -k -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
                -X PUT -d @/tmp/$xName \> /tmp/put.$xName
            return 1
        elif ! head -1 /tmp/put.$xName | grep -Eq "^HTTP.*[[:space:]]200[[:space:]]*$" ; then
            cat /tmp/put.$xName
            update_bss_storage_error "Expected 200 response but did not receive it from command: " \
                "curl -i -s -k -H \"Content-Type: application/json\" -H \"Authorization: Bearer ${TOKEN}\" "\
                "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters -X PUT -d @/tmp/$xName"
            return 1
        fi
        echo "update_bss_storage: Successfully updated bootparameters for ${storage_node}"
    done
    echo -e "\nupdate_bss_storage: Success!"
}
