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

source "${basedir}"/../common/upgrade-state.sh

# Relative source import
source "${basedir}"/../../../lib/lib.sh

trap 'argo_err_report' ERR

trap libcleanup EXIT

#global vars
dryRun=false
baseUrl="https://api-gw-service-nmn.local"
retry=true
force=false

function usage() {
    echo "CSM ncn worker and storage upgrade script"
    echo
    echo "Syntax: /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh [COMMA_SEPARATED_NCN_HOSTNAMES] [-f|--force|--retry|--base-url|--dry-run]"
    echo "options:"
    echo "--no-retry     Do not automatically retry  (default: false)"
    echo "-f|--force     Remove failed worker or storage rebuild/upgrade workflow and create a new one  (default: ${force})"
    echo "--base-url     Specify base url (default: ${baseUrl})"
    echo "--dry-run      Print out steps of workflow instead of running steps (default: ${dryRun})"
    echo
    echo "*COMMA_SEPARATED_NCN_HOSTNAMES"
    echo "  worker upgrade  - example 1) ncn-w001"
    echo "  worker upgrade  - example 2) ncn-w001,ncn-w002,ncn-w003"
    echo "  storage upgrade - example 3) ncn-s001"
    echo "  storage upgrade - example 4) ncn-s001,ncn-s002,ncn-s003"
    echo
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-retry)
        retry=false
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
        nodeType="worker"
        ;;
    ncn-s[0-9][0-9][0-9]*)
        target_ncns=$1
        shift # past argument
        IFS=', ' read -r -a array <<< "$target_ncns"
        jsonArray=$(jq -r --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}")
        nodeType="storage"
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
    "${basedir}"/../../../workflows/scripts/upload-rebuild-templates.sh
}

function createWorkflowPayload() {
    if [[ ${nodeType} == "worker" ]]
    then
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
    fi
    if [[ ${nodeType} == "storage" ]]
    then
        echo
        cat << EOF
{
"dryRun": ${dryRun},
"hosts": ${jsonArray}
}
EOF
    fi
}

function getToken() {
    # For all FUNCNAMES I *want* the first element which is function name
    #shellcheck disable=SC2128
    tmpfile=$(libtmpfile "${FUNCNAME}")

    # REVIEW: Default fatal
    curl --output "${tmpfile}" --show-error --data grant_type=client_credentials --data client_id=admin-client \
        --data client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
        "${baseUrl}"/keycloak/realms/shasta/protocol/openid-connect/token

    # REVIEW: Default fatal
    jq -r '.access_token' "${tmpfile}"
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

function getUnsucceededRebuildWorkflows() {
    #shellcheck disable=SC2128
    tmpfile=$(libtmpfile "$FUNCNAME")

    local labelSelector="node-type=${nodeType},workflows.argoproj.io/phase!=Succeeded"

    # REVIEW: Default fatal

    curl --output "${tmpfile}" --header "Authorization: Bearer $(getToken)" \
         "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}"

    # REVIEW: Default fatal
    jq -r ".[]? | .name?" "${tmpfile}"
}

function createRebuildWorkflow() {
    #shellcheck disable=SC2128
    tmpfile=$(libtmpfile "$FUNCNAME")

    # REVIEW: Default fatal
    curl --output "${tmpfile}" --request POST ---header "Authorization: Bearer $(getToken)" --header 'Content-Type: application/json' \
         --data "$(createWorkflowPayload)" \
         "${baseUrl}/apis/nls/v1/ncns/rebuild"

    grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*' "${tmpfile}"
}

function deleteRebuildWorkflow() {
    # REVIEW: Default fatal
    curl --output "${tmpfile}" --request DELETE --header "Authorization: Bearer $(getToken)" \
         "${baseUrl}/apis/nls/v1/workflows/${1}"
}

function retryRebuildWorkflow() {
    #shellcheck disable=SC2128
    tmpfile=$(libtmpfile "$FUNCNAME")

    # REVIEW: Default fatal
    curl --output "${resfile}" --request PUT --header "Authorization: Bearer $(getToken)" --data '{}' \
         "${baseUrl}/apis/nls/v1/workflows/${1}/retry"
}

printCmdArgs
uploadWorkflowTemplates
# shellcheck disable=SC2207
unsucceededWorkflows=($(getUnsucceededRebuildWorkflows))
numOfUnsucceededWorkflows="${#unsucceededWorkflows[*]}"

if [[ ${numOfUnsucceededWorkflows} -gt 1 ]]; then
    echo "ERROR: There are multiple unsuccessful ${nodeType} rebuild workflows"
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
    labelSelector="node-type=${nodeType}"
    # Shellcheck refuses to accept quoting of $0 and the basename call and its
    # wrong anyway.
    #shellcheck disable=SC2086
    tmpfile=$(libtmpfile "$(basename $0)")

    # REVIEW: In a retry loop so we'll use the non exit() version of hooks
    #shellcheck disable=SC2034
    CURLFN=curlretry

    if curl --output "${tmpfile}" --request GET --header "Authorization: Bearer $(getToken)" \ "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}"; then
        # REVIEW: In a retry loop so we'll use the non exit() version of hooks
        #shellcheck disable=SC2034
        JQTESTFAILFN=jqretry

        phase=$(jq -r ".[] | select(.name==\"${workflow}\") | .status.phase" "${tmpfile}")
        # skip null because workflow hasn't started yet
        if [[ "${phase}" == "null" ]]; then
            continue;
        fi

        if [[ "${phase}" == "Succeeded" ]]; then
            ok_report
            break;
        fi

        if [[ "${phase}" == "Failed" ]]; then
            echo "Workflow in Failed state, Retry ..."
            retryRebuildWorkflow "$workflow"
        fi

        if [[ "${phase}" == "Error" ]]; then
            echo "Workflow in Error state, Retry ..."
            retryRebuildWorkflow "$workflow"
        fi
        runningSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Running\")  | .name + \"\n  \" " "${tmpfile}")
        succeededSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Succeeded\")  | .name +\"\n  \" " "${tmpfile}")
        clear
        printf "\n%s\n" "Succeeded:"
        echo "  ${succeededSteps}" | awk -F'.' '{print $2" -  "$3}'
        printf "%s\n" "${phase}:"
        echo "  ${runningSteps}"  | awk -F'.' '{print $2" -  "$3}'
        sleep 10
    fi
done
