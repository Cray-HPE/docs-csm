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

#global vars
dryRun=false
baseUrl="https://api-gw-service-nmn.local"
retry=true
force=false

function usage() {
    echo "CSM ncn worker upgrade script"
    echo
    echo "Syntax: /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-nodes.sh [COMMA_SEPARATED_NCN_HOSTNAMES] [-f|--force|--retry|--base-url|--dry-run]"
    echo "options:"
    echo "--retry        Send RETRY request instead of CREATE if there is a failed worker rebuild/upgrade workflow already  (default: ${retry})"
    echo "-f|--force     Remove failed worker rebuild/upgrade workflow and create a new one  (default: ${force})"
    echo "--base-url     Specify base url (default: ${baseUrl})"
    echo "--dry-run      Print out steps of workflow instead of running steps (default: ${dryRun})"
    echo
    echo "*COMMA_SEPARATED_NCN_HOSTNAMES"
    echo "  example 1) ncn-w001"
    echo "  example 2) ncn-w001,ncn-w002,ncn-w003"
    echo
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --retry)
        retry=true
        shift # past argument
        ;;
    -f|--force)
        force=true
        shift # past argument
        ;;
    --base-url)
        baseUrl="$2"
        shift # past argument
        shift # past value
        ;;
    --dry-run)
        dryRun=true
        shift # past argument
        ;;
    ncn-w[0-9][0-9][0-9]*)
        target_ncns=$1
        shift # past argument
        IFS=', ' read -r -a array <<< "$target_ncns"
        jsonArray=$(jq -r --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}")
        ;;
    *)
        echo 
        echo "Unknown option $1" 
        usage
        exit 1
        ;;
  esac
done

if $retry && $force; then
    echo "WARNING: RETRY is ignored when FORCE is set"
    retry=false
fi

function uploadWorkflowTemplates() {
    "${basedir}"/../../../workflows/scripts/upload-worker-rebuild-templates.sh
}

function createWorkflowPayload() {
    # ask for switch password if it's not set
    if [[ -z "${SW_ADMIN_PASSWORD}" ]]; then
    read -r -s -p "Switch password:" SW_ADMIN_PASSWORD
    fi
    echo
    cat << EOF
{
  "dryRun": ${dryRun},
  "hosts": ${jsonArray},
  "switchPassword": "${SW_ADMIN_PASSWORD}"
}
EOF
}

function getToken() {
    # shellcheck disable=SC2155,SC2046
    curl -k -s -S -d grant_type=client_credentials \
        -d client_id=admin-client \
        -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
        "${baseUrl}"/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
}

function printCmdArgs() {
    echo "Inputs: "
    echo "============================================================"
    echo "Target Ncn(s):    ${jsonArray}"
    echo "Base URL:         ${baseUrl}"
    echo "Retry:            ${retry}"
    echo "Dry Run:          ${dryRun}"
    echo "Force:            ${force}"
    echo "============================================================="
}

function getUnsucceededWorkerRebuildWorkflows() {
    res_file=$(mktemp)
    local labelSelector="node-type=worker,workflows.argoproj.io/phase!=Succeeded"
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XGET -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    fi
    jq -r ".[]? | .name?" < "${res_file}"
}

function createRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XPOST -H "Authorization: Bearer $(getToken)" -H 'Content-Type: application/json' -d "$(createWorkflowPayload)" "${baseUrl}/apis/nls/v1/ncns/rebuild")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    fi
    local workflow
    workflow=$(grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*' < "${res_file}" )
    echo "${workflow}"
}

function deleteRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XDELETE -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows/${1}")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    fi
}

function retryRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XPUT -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows/${1}/retry")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
    fi
}

printCmdArgs
uploadWorkflowTemplates
# shellcheck disable=SC2207
unsucceededWorkflows=($(getUnsucceededWorkerRebuildWorkflows))
numOfUnsucceededWorkflows="${#unsucceededWorkflows[*]}"

if [[ ${numOfUnsucceededWorkflows} -gt 1 ]]; then
    echo "ERROR: There are multiple unsucceeded worker rebuild workflows"
    exit 1
fi

# dealing with FORCE
# shellcheck disable=SC2046
if $force && [ "${numOfUnsucceededWorkflows}" -eq 1 ]; then
    workflow=$(echo "${unsucceededWorkflows[0]}" | grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*')
    echo "Delete workflow: ${workflow}"
    deleteRebuildWorkflow "${workflow}"
    numOfUnsucceededWorkflows=0
fi

# dealing with RETRY
# shellcheck disable=SC2046
if $retry && [ "${numOfUnsucceededWorkflows}" -eq 1 ]; then
    workflow=$(echo "${unsucceededWorkflows[0]}" | grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*')
    echo "Retry workflow: ${workflow}"
    retryRebuildWorkflow "${workflow}"
fi

if [ "${numOfUnsucceededWorkflows}" -eq 0 ]; then
    # create a new workflow
    workflow=$(createRebuildWorkflow)
    echo "Create workflow: ${workflow}"
fi

if [[ -z "${workflow}" ]]; then
    echo
    echo "No workflow to pull, something is wrong"
else 
    echo
    echo "Poll status of: ${workflow}"
fi

sleep 20

# poll
while true; do
    labelSelector="node-type=worker"
    res_file="$(mktemp)"
    http_status=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XGET -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}")
    
    if [ "${http_status}" -eq 200 ]; then
        phase=$(jq -r ".[] | select(.name==\"${workflow}\") | .status.phase" < "${res_file}")
        # skip null because workflow hasn't started yet
        if [[ "${phase}" == "null" ]]; then
            continue;
        fi

        if [[ "${phase}" == "Succeeded" ]]; then
            ok_report
            break;
        fi

        if [[ "${phase}" == "Failed" ]]; then
            exit 1
            break;
        fi

        if [[ "${phase}" == "Error" ]]; then
            echo "Workflow in Error state, Retry ..."
            curl -sk -XPUT -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows/${workflow}/retry"
        fi
        runningSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Running\")  | .displayName + \"\n  \" " < "${res_file}")
        succeededSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Succeeded\")  | .displayName +\"\n  \" " < "${res_file}")
        printf "\n%s\n" "Succeeded:"
        echo "  ${succeededSteps}"
        printf "%s\n" "${phase}:"
        echo "  ${runningSteps}"
        echo "============================="
        sleep 10
    fi
done

