#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e
basedir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${basedir}/../common/upgrade-state.sh
trap 'err_report' ERR

target_ncns=$1
IFS=', ' read -r -a array <<< "$target_ncns"
jsonArray=$(jq -r --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}")

${basedir}/../../../workflows/scripts/upload-worker-rebuild-templates.sh

if [[ -z "${SW_PASSWORD}" ]]; then
  read -r -s -p "Switch password:" SW_PASSWORD
fi

cat << EOF > data.json
{
  "dryRun": false,
  "hosts": ${jsonArray},
  "switchPassword": "${SW_PASSWORD}"
}
EOF
# shellcheck disable=SC2155,SC2046
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
   -d client_id=admin-client \
   -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

response=$(curl -sk -XPOST -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' -d @data.json "https://api-gw-service-nmn.local/apis/nls/v1/ncns/rebuild")

rm -rf data.json

if echo "${response}" | grep "message"; then
    echo
    echo "${response}" | jq -r '.message'
fi

workflow=$(echo "${response}" | grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*["|\.]')
workflow=${workflow::-1}

echo
echo "Running workflow: ${workflow}"

while true; do
    # TODO: limit to worker rebuild request
    phase=$(curl -sk -XGET -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/nls/v1/workflows" | \
        jq -r ".[] | select(.name==\"${workflow}\") | .status.phase")
    # skip null because workflow hasn't started yet
    if [[ "${phase}" == "null" ]]; then
        continue;
    fi

    if [[ "${phase}" == "Succeeded" ]]; then
        break;
    fi

    if [[ "${phase}" == "Failed" ]]; then
        # TODO: get los/troubleshooting
        break;
    fi

    if [[ "${phase}" == "Error" ]]; then
        echo "Workflow in Error state, Retry ..."
        curl -sk -XPUT -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/nls/v1/workflows/${workflow}/retry"
        sleep 20
    fi
    runningSteps=$(curl -sk -XGET -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/nls/v1/workflows" |         jq -r ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Running\")  | .displayName")
    echo "${phase}: ${runningSteps}"
    sleep 10
done