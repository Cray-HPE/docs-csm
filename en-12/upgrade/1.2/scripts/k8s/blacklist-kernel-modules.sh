#!/usr/bin/env bash

#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

set -ueo pipefail

NOW=$(date "+%Y%m%d%H%M%S")

function get-admin-client-secret() {
    kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
}

function get-token() {
    local client_secret
    client_secret="$(get-admin-client-secret)"
    curl -sSfk \
        -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret="${client_secret}" \
        'https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token' \
    | jq -r '.access_token'
}

function list-workers() {
    local token
    local workers

    token="$(get-token)"
    workers=$(curl -sSfk \
        -H "Authorization: Bearer ${token}" \
        'https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management' \
    | jq -r '.[]| .ExtraProperties.Aliases[]' \
    | sort -u | grep ncn-w)

    echo "$workers"
}

function list-worker-xnames() {
    local token

    token="$(get-token)"

    for worker in $(list-workers); do
        curl -s -k -H "Authorization: Bearer ${token}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
               jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$worker\")) | .Xname"
    done
}

module_blacklist="module_blacklist=rpcrdma"

# update worker node boot params to include the module blacklist
for worker in $(list-worker-xnames); do
    # get current params
    bootparams=$(cray bss bootparameters list --hosts "$worker" --format json)
    params=$(cray bss bootparameters list --hosts "$worker" --format json | jq -r '.[]|.["params"]')

    # save current params
    echo "$bootparams" > /tmp/bootparams."$worker.$NOW"

    # update params iff they're not already present
    if ! [[ $params == *"$module_blacklist"* ]]; then
        params="$params $module_blacklist"
        cray bss bootparameters update --hosts "$worker" --params "$params"

        # confirm the update was successful
        params=$(cray bss bootparameters list --hosts "$worker" --format json | jq -r '.[]|.["params"]')
        if [[ $params == *"$module_blacklist"* ]]; then
            echo "bootparameters update successful for $worker"
        else
            echo "bootparameters update failed for $worker"
        fi
    else
        echo "module blacklist already present for $worker, no action taken"
    fi
done
