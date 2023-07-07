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

set -e
basedir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
. ${basedir}/../common/upgrade-state.sh
trap 'argo_err_report' ERR

#global vars
dryRun=false
baseUrl="https://api-gw-service-nmn.local"
retry=true
force=false
upgrade=false
rebuild=false
zapOsds=false
workflowType=""
imageId=""
desiredCfsConfig=""
labels=""

function usage() {
  echo "CSM ncn worker and storage upgrade script"
  echo
  echo "Syntax: /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh [COMMA_SEPARATED_NCN_HOSTNAMES] [-f|--force|--retry|--base-url|--dry-run|--upgrade|--rebuild]"
  echo "options:"
  echo "--no-retry          Do not automatically retry  (default: false)"
  echo "-f|--force          Remove failed worker or storage rebuild/upgrade workflow and create a new one  (default: ${force})"
  echo "--base-url          Specify base url (default: ${baseUrl})"
  echo "--dry-run           Print out steps of workflow instead of running steps (default: ${dryRun})"
  echo "--upgrade           Perform a node upgrade. This only needs to be specified when upgrading storage nodes."
  echo "--image-id          The image-id that a worker node should be booted into when a node is rebuilt. This is optional."
  echo "--zap-osds          Zap osds. Only do this if unable to wipe the node prior to rebuild. For example, when a storage node unintentionally goes down and needs to be rebuilt. (This can only be used with storage rebuilds)."
  echo "--desired-cfs-conf  The desired cfs config worker node should be booted into when a node is rebuilt. This is optional."
  echo "--reboot-timeout    The timeout on worker reboot. This is optional."
  echo
  echo "*COMMA_SEPARATED_NCN_HOSTNAMES"
  echo "  worker upgrade  - example 1) ncn-w001"
  echo "  worker upgrade  - example 2) ncn-w001,ncn-w002,ncn-w003 --image-id <image-id>"
  echo "  storage upgrade - example 3) ncn-s001 --upgrade"
  echo "  storage upgrade - example 4) ncn-s001,ncn-s002,ncn-s003 --upgrade"
  echo
}

# Warn when passing in extra arguments that probably were intended to be comma
# separated hosts to upgrade, should fix this script to just accept all args
# after the first however
function argerr() {
  printf "Extra arguments %s present after arg parsing, did you intend these to be in the comma separated host list instead?\n\n" "$*" >&2
}

terminal=false

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
    --upgrade)
        upgrade=true
        shift # past argument
        ;;
    --rebuild)
        rebuild=true
        shift # past argument
        ;;
    --image-id)
        imageId="$2"
        shift # past argument
        shift # past value
        ;;
    --desired-cfs-conf)
        desiredCfsConfig="$2"
        shift # past argument
        shift # past value
        ;;
    --labels)
        labels="$2"
        shift # past argument
        shift # past value
        ;;
    --zap-osds)
        zapOsds=true
        shift # past argument
        ;;
    --reboot-timeout)
        rebootTimeout="$2"
        shift # past argument
        ;;
    ncn-w[0-9][0-9][0-9]*)
        if $terminal; then
          argerr "$@"
          usage
          exit 1
        else
          target_ncns=$1
          shift # past argument
          IFS=', ' read -r -a array <<< "$target_ncns"
          jsonArray=$(jq -r --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}")
          nodeType="worker"
        fi
        terminal=true
        ;;
    ncn-s[0-9][0-9][0-9]*)
        if $terminal; then
          argerr "$@"
          usage
          exit 1
        else
          target_ncns=$1
          shift # past argument
          IFS=', ' read -r -a array <<< "$target_ncns"
          jsonArray=$(jq -r --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}")
          nodeType="storage"
        fi
        terminal=true
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

if [[ $nodeType == "storage" ]]; then
    if $upgrade; then 
        workflowType="upgrade"
    elif $rebuild; then
        echo "Error: --rebuild flag was used for storage rebuild. This rebuild must be done manually. Follow instructions at /operations/node_management/Rebuild_NCNs/Rebuild_NCNs.md"
        exit 1
    else
        echo "Input Error: when upgrading storage nodes, the '--upgrade' flag needs to specified."
        exit 1
    fi
    if $upgrade && $rebuild; then
        echo "Input Error: cannot use both '--rebuild' and '--upgrade' flag at the same time."
        exit 1
    fi
fi

# set default reboot timeout to 600 if not specified
if [[ -z $rebootTimeout ]]; then
    rebootTimeout=600
fi

# check that cfs config exists if desiredCfsConfig is not empty
if [[ -n $desiredCfsConfig ]]; then
    cray cfs configurations describe "$desiredCfsConfig" > /dev/null
    if [[ $? -ne 0 ]]; then
      # could not find the desired cfs configuration
      exit 1
    fi
fi

# check that image-id exists if imageId is not empty
if [[ -n $imageId ]]; then
    cray ims images describe "$imageId" > /dev/null
    if [[ $? -ne 0 ]]; then
      # could not find the desired cfs configuration
      exit 1
    fi
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
"switchPassword": "${SW_ADMIN_PASSWORD}",
"imageId": "${imageId}",
"bootTimeoutInSeconds": ${rebootTimeout},
"desiredCfsConfig": "${desiredCfsConfig}"$(if [[ -n "${labels}" ]]; then echo ", \"labels\": \"${labels}\""; fi)
}
EOF
    fi
    if [[ ${nodeType} == "storage" ]]
    then    
        echo
        cat << EOF
{
"dryRun": ${dryRun},
"hosts": ${jsonArray},
"zapOsds": ${zapOsds},
"workflowType": "${workflowType}",
"imageId": "${imageId}",
"bootTimeoutInSeconds": ${rebootTimeout},
"desiredCfsConfig": "${desiredCfsConfig}"$(if [[ -n "${labels}" ]]; then echo ", \"labels\": \"${labels}\""; fi)
}
EOF
    fi
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

function getUnsucceededRebuildWorkflows() {
    res_file=$(mktemp)
    local labelSelector="node-type=${nodeType},workflows.argoproj.io/phase!=Succeeded"
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XGET -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        rm -f "${res_file}" > /dev/null 2>&1 || true
        exit 1
    fi
    jq -r ".[]? | .name?" < "${res_file}"
    rm -f "${res_file}" > /dev/null 2>&1 || true
}

function createRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XPOST -H "Authorization: Bearer $(getToken)" -H 'Content-Type: application/json' -d "$(createWorkflowPayload)" "${baseUrl}/apis/nls/v1/ncns/rebuild")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        rm -f "${res_file}" > /dev/null 2>&1 || true
        exit 1
    fi
    local workflow
    workflow=$(grep -o 'ncn-lifecycle-rebuild-[a-z0-9]*' < "${res_file}" )
    echo "${workflow}"
    rm -f "${res_file}" > /dev/null 2>&1  || true
}

function deleteRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XDELETE -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows/${1}")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        rm -f "${res_file}" > /dev/null 2>&1 || true 
        exit 1
    fi
    rm -f "${res_file}" > /dev/null 2>&1 || true 
}

function retryRebuildWorkflow() {
    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XPUT -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows/${1}/retry" -d '{}')
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
    fi
    rm -f "${res_file}" > /dev/null 2>&1 || true 
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
    echo "DEBUG - Retry workflow: ${workflow}"
    retryRebuildWorkflow "${workflow}"
fi

if [ "${numOfUnsucceededWorkflows}" -eq 0 ]; then
    # create a new workflow
    workflow=$(createRebuildWorkflow)
    echo "NOTICE - Create workflow: ${workflow}. Please see the workflow ${workflow} in the Argo UI to see detailed logs"
fi

if [[ -z "${workflow}" ]]; then
    echo
    echo "ERROR - No workflow to pull, something is wrong"
else 
    echo
    echo "DEBUG - Poll status of: ${workflow}"
fi

sleep 20

# poll
while true; do
    labelSelector="node-type=${nodeType}"
    res_file="$(mktemp)"
    # Retry the curl command if it fails
    while ! http_status=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XGET -H "Authorization: Bearer $(getToken)" "${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector}") ; do
        echo "WARNING: curl call to ${baseUrl}/apis/nls/v1/workflows?labelSelector=${labelSelector} failed. Retrying after 10 seconds"
        sleep 10
    done

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
            echo "WARNING - Workflow in Failed state, Retry ..."
            retryRebuildWorkflow "$workflow"
            continue
        fi

        if [[ "${phase}" == "Error" ]]; then
            echo "WARNING - Workflow in Error state, Retry ..."
            retryRebuildWorkflow "$workflow"
            continue
        fi
        runningSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Running\")  | .name + \"\n  \" " < "${res_file}")
        succeededSteps=$(jq -jr ".[] | select(.name==\"${workflow}\") | .status.nodes[] | select(.type==\"Retry\")| select(.phase==\"Succeeded\")  | .name +\"\n  \" " < "${res_file}")
        clear
        printf "\n%s\n" "INFO - Succeeded:"
        echo "INFO $(echo ${succeededSteps} | awk -F'.' '{print $2" -  "$3}')"
        printf "%s\n" "INFO - ${phase}:"
        echo "INFO $(echo ${runningSteps} | awk -F'.' '{print $2" -  "$3}')"
        sleep 10
    fi
    rm -f "${res_file}" > /dev/null 2>&1 || true
done
