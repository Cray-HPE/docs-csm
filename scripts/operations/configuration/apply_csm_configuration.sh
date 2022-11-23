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

locOfScript=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Inform ShellCheck about the file we are sourcing
# shellcheck source=./bash_lib/common.sh
. "${locOfScript}/bash_lib/common.sh"

DEFAULT_CONFIG_NAME="ncn-personalization"
CONFIG_NAME=""
CONFIG_CHANGE=""
RELEASE=""
VERSION=""
COMMIT=""
CLONE_URL=""
OLD_NCN_CONFIG_FILE=""
XNAMES=""
CLEAR_STATE=""
NO_ENABLE=""
NO_CLEAR_ERR=""

usage()
{
   # Display help
   echo "Updates CFS configurations"
   echo "All parameters are optional and the values will be determined automatically if not set."
   echo
   echo "Usage 1: apply_csm_configuration.sh [ --config-change ] [ --config-name name ]"
   echo "                                    [ --csm-release version ] [ --git-commit hash ]"
   echo "                                    [ --git-clone-url url ] [ --ncn-config-file file ]"
   echo "                                    [ --clear-state ] [ --no-enable ] [ --no-clear-err ]"
   echo "                                    [ --xnames xname1,xname2... ]"
   echo
   echo "Usage 2: apply_csm_configuration.sh --no-config-change [ --config-name name ]"
   echo "                                    [ --clear-state ] [ --no-enable ] [ --no-clear-err ]"
   echo "                                    [ --xnames xname1,xname2... ]"
   echo
   echo "In usage 1, either a new CFS configuration is created or an existing CFS configuration is updated."
   echo "In usage 2, an existing CFS configuration is used without modification."
   echo
   echo "Options:"
   echo "config-name          Usage 1: name to use for the new/updated CFS configuration."
   echo "                     Usage 2: name of existing CFS configuration to use"
   echo "                     Default: ${DEFAULT_CONFIG_NAME}"
   echo "config-change        Specifies usage 1. (default)"
   echo "no-config-change     Specifies usage 2."
   echo "csm-release          The version of the CSM release to use. (e.g. 1.6.11). Only valid with usage 1."
   echo "git-commit           The git commit hash for CFS to use. Only valid with usage 1."
   echo "git-clone-url        The git clone url for CFS to use. Only valid with usage 1."
   echo "ncn-config-file      A file containing the NCN CFS configuration. Only valid with usage 1."
   echo "xnames               A comma-separated list of component names (xnames) to deploy to. All management nodes will be included if not set."
   echo "clear-state          Clears existing state from components to ensure CFS runs."
   echo "no-enable            By default, the script enables all of the NCNs and waits for them to complete configuration. If this flag is set,"
   echo "                     however, it updates their desired configurations but leaves them disabled."
   echo "no-clear-err         By default, the script clears the error count of all NCNs in CFS. If this flag is set, it does not."
   echo
}

while [[ $# -gt 0 ]]; do
  key="$1"

  # Make sure that flags which require arguments get them
  case "${key}" in
    --csm-release|--csm-config-version|--git-commit|--git-clone-url|--ncn-config-file|--xnames|--config-name)
      [[ $# -lt 2 ]] && usage_err_exit "${key} requires an argument"
      [[ -z "$2" ]] && usage_err_exit "Argument to ${key} may not be blank"
      ;;
  esac

  case "${key}" in
    --config-change)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--config-change and --no-config-change are mutually exclusive"
      CONFIG_CHANGE="true"
      shift # past argument
      ;;
    --no-config-change)
      [[ ${CONFIG_CHANGE} == true ]] && usage_err_exit "--config-change and --no-config-change are mutually exclusive"
      # This argument conflicts with several others
      [[ -n ${RELEASE} ]] && usage_err_exit "--csm-release and --no-config-change are mutually exclusive"
      [[ -n ${VERSION} ]] && usage_err_exit "--csm-config-version and --no-config-change are mutually exclusive"
      [[ -n ${COMMIT} ]] && usage_err_exit "--git-commit and --no-config-change are mutually exclusive"
      [[ -n ${CLONE_URL} ]] && usage_err_exit "--git-clone-url and --no-config-change are mutually exclusive"
      [[ -n ${OLD_NCN_CONFIG_FILE} ]] && usage_err_exit "--ncn-config-file and --no-config-change are mutually exclusive"
      CONFIG_CHANGE="false"
      shift # past argument
      ;;
    --config-name)
      CONFIG_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    --csm-release)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--csm-release and --no-config-change are mutually exclusive"
      RELEASE="$2"
      shift # past argument
      shift # past value
      ;;
    --csm-config-version)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--csm-config-version and --no-config-change are mutually exclusive"
      VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    --git-commit)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--git-commit and --no-config-change are mutually exclusive"
      COMMIT="$2"
      shift # past argument
      shift # past value
      ;;
    --git-clone-url)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--git-clone-url and --no-config-change are mutually exclusive"
      CLONE_URL="$2"
      shift # past argument
      shift # past value
      ;;
    --ncn-config-file)
      [[ ${CONFIG_CHANGE} == false ]] && usage_err_exit "--ncn-config-file and --no-config-change are mutually exclusive"
      # Make sure the file exists, is a regular file, is not empty, and 
      # contains valid JSON data
      [[ -e "$2" ]] || usage_err_exit "NCN config file ($2) does not exist"
      [[ -f "$2" ]] || usage_err_exit "NCN config file ($2) exists but is not a regular file"
      [[ -s "$2" ]] || usage_err_exit "NCN config file ($2) has zero size"
      json=$(cat "$2" | jq) || usage_err_exit "NCN config file ($2) is not valid JSON format"
      [[ -z "$json" ]] && usage_err_exit "NCN config file ($2) contains no JSON data"
      OLD_NCN_CONFIG_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    --xnames)
      XNAMES="$2"
      shift # past argument
      shift # past value
      ;;
    --clear-state)
      CLEAR_STATE="true"
      shift # past argument
      ;;
    --no-clear-err)
      NO_CLEAR_ERR="true"
      shift # past argument
      ;;      
    --no-enable)
      NO_ENABLE="true"
      shift # past argument
      ;;
    -h|--help) # help option
      usage
      exit 0
      ;;
    *) # unknown option
      usage_err_exit "Unknown argument: '${key}'"
      exit 1
      ;;
  esac
done

## Set defaults
[[ -z ${CONFIG_NAME} ]] && CONFIG_NAME=${DEFAULT_CONFIG_NAME}
[[ -z ${CONFIG_CHANGE} ]] && CONFIG_CHANGE="true"

# The script will keep all relevant files in a temporary directory. During
# CSM upgrades, this directory will be backed up, in case it is needed for
# future reference.

TMPDIR=$(run_mktemp -d "${HOME}/apply_csm_configuration.$(date +%Y%m%d_%H%M%S).XXXXXX")
BACKUP_NCN_CONFIG_FILE=$(run_mktemp --tmpdir="${TMPDIR}" "backup-${CONFIG_NAME}-XXXXXX.json")

if [[ -z ${XNAMES} ]]; then
    echo "Retrieving a list of all management node component names (xnames)"
    XNAMES=$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
    [[ -n "${XNAMES}" ]] || err_exit "No management nodes found in HSM"
fi
XNAME_LIST=${XNAMES//,/ }

## CONFIGURATION SETUP ##
if [[ ${CONFIG_CHANGE} == true ]]; then

    if [[ -z "${RELEASE}" && -z "${VERSION}" ]]; then
        RELEASE=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' 2>/dev/null\
            | yq r -j - 2>/dev/null | jq -r ' to_entries | max_by(.key) | .key' 2>/dev/null)
        [[ -n "${RELEASE}" ]] || err_exit "Unable to determine CSM release version"
        echo "Using latest release ${RELEASE}"
    fi

    if [[ -z "${VERSION}" ]]; then
        VERSION=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' 2>/dev/null\
            | yq r -j - 2>/dev/null | jq -r ".[\"$RELEASE\"].configuration.import_branch" 2>/dev/null\
            | awk -F'/' '{ print $NF }')
        [[ -n "${VERSION}" ]] || err_exit "Unable to determine CSM configuration version"
        echo "Using CSM configuration version ${VERSION}"
    fi

    # If a file is passed in as input, keep a copy in the temporary directory
    if [[ -n ${OLD_NCN_CONFIG_FILE} && -f ${OLD_NCN_CONFIG_FILE} ]]; then
        run_cmd cp "${OLD_NCN_CONFIG_FILE}" "${TMPDIR}"
    fi

    CSM_CONFIG_FILE=$(run_mktemp --tmpdir="${TMPDIR}" "csm-config-${VERSION}-XXXXXX.json")
    NCN_CONFIG_FILE=$(run_mktemp --tmpdir="${TMPDIR}" "new-${CONFIG_NAME}-XXXXXX.json")

    if [[ -z "${CLONE_URL}" ]]; then
        CLONE_URL="https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    fi

    if [[ -z "${COMMIT}" ]]; then
        VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template='{{.data.vcs_username}}' | base64 --decode)
        [[ -n "${VCS_USER}" ]] || err_exit "Unable to obtain VCS username"
        VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template='{{.data.vcs_password}}' | base64 --decode)
        [[ -n "${VCS_PASSWORD}" ]] || err_exit "Unable to obtain VCS password"
        TEMP_DIR=$(run_mktemp -d)
        TEMP_HOME=${HOME}
        HOME=${TEMP_DIR}
        cd "${TEMP_DIR}" || err_exit "Unable to change directory to '${TEMP_DIR}'"
        echo "${CLONE_URL/\/\//\/\/${VCS_USER}:${VCS_PASSWORD}@}" > .git-credentials
        run_cmd git config --file .gitconfig credential.helper store
        COMMIT=$(git ls-remote ${CLONE_URL} refs/heads/cray/csm/${VERSION} | awk '{print $1}')
        if [[ -n ${COMMIT} ]]; then
            echo "Found git commit ${COMMIT}"
        else
            echo "No git commit found"
            exit 1
        fi
        cd - >/dev/null || err_exit "Unable to change directory back to previous directory"
        HOME=${TEMP_HOME}
        rm -r "${TEMP_DIR}" || echo "WARNING: Unable to delete temporary directory '${TEMP_DIR}'" 1>&2
    fi

    CONFIG="{ \"layers\": [ { \"name\": \"csm-${VERSION}\", \"cloneUrl\": \"${CLONE_URL}\", \"commit\": \"${COMMIT}\", \"playbook\": \"site.yml\" } ] }"

    echo "Creating the configuration file ${CSM_CONFIG_FILE}"
    echo "${CONFIG}" | jq > "${CSM_CONFIG_FILE}" || err_exit "Unexpected error parsing JSON or writing to '${CSM_CONFIG_FILE}'"

    if [[ -n ${OLD_NCN_CONFIG_FILE} && -f ${OLD_NCN_CONFIG_FILE} ]]; then
        echo "Combining new CSM configuration '${CSM_CONFIG_FILE}' with contents of '${OLD_NCN_CONFIG_FILE}' to generate '${NCN_CONFIG_FILE}'"
        jq -n --slurpfile new "${CSM_CONFIG_FILE}" --slurpfile old "${OLD_NCN_CONFIG_FILE}" \
            '{"layers": ($new[0].layers + ($old[0].layers | del(.[] | select(.cloneUrl == $new[0].layers[0].cloneUrl and .playbook == $new[0].layers[0].playbook))))}'\
            > "${NCN_CONFIG_FILE}" || err_exit "Unexpected error combining JSON or writing to '${NCN_CONFIG_FILE}'"
    else
        echo "Creating new NCN configuration file ${NCN_CONFIG_FILE}"
        run_cmd cp -p "${CSM_CONFIG_FILE}" "${NCN_CONFIG_FILE}"
    fi

    ## UPDATING CFS ##

    echo "Disabling configuration for all listed components"
    for xname in ${XNAME_LIST}; do
        run_cmd cray cfs components update ${xname} --enabled false
    done

    # Before updating the configuration, make a backup of the existing configuration (if it exists)
    echo "Backing up existing ${CONFIG_NAME} configuration (if any) to ${BACKUP_NCN_CONFIG_FILE}"
    # Do not use run_cmd for this call because if it fails, that's okay -- it most likely means that the CFS configuration does not exist.
    cray cfs configurations describe "${CONFIG_NAME}" --format json > "${BACKUP_NCN_CONFIG_FILE}" 2>&1

    echo "Updating ${CONFIG_NAME} configuration"
    run_cmd cray cfs configurations update "${CONFIG_NAME}" --file "${NCN_CONFIG_FILE}"

else

    # In this case, we are using an existing configuration. We will take a snapshot of it, and unlike above, we will
    # fail if it does not exist
    echo "Taking snapshot of existing ${CONFIG_NAME} configuration to ${BACKUP_NCN_CONFIG_FILE}"
    run_cmd cray cfs configurations describe "${CONFIG_NAME}" --format json > "${BACKUP_NCN_CONFIG_FILE}"

fi

CFS_COMP_UPDATE_MSG="Setting desired configuration"
CFS_COMP_UPDATE_ARGS=""

if [[ -n ${CLEAR_STATE} ]]; then
    CFS_COMP_UPDATE_MSG+=", clearing state"
    CFS_COMP_UPDATE_ARGS+=" --state []"
fi

if [[ -z ${NO_CLEAR_ERR} ]]; then
    CFS_COMP_UPDATE_MSG+=", clearing error count"
    CFS_COMP_UPDATE_ARGS+=" --error-count 0"
fi

if [[ -z ${NO_ENABLE} ]]; then
    echo "${CFS_COMP_UPDATE_MSG}, enabling components in CFS"
    for xname in ${XNAME_LIST}; do
        run_cmd cray cfs components update ${xname} --enabled true ${CFS_COMP_UPDATE_ARGS} --desired-config "${CONFIG_NAME}"
    done
else
    echo "${CFS_COMP_UPDATE_MSG} components in CFS"
    for xname in ${XNAME_LIST}; do
        run_cmd cray cfs components update ${xname} --enabled false ${CFS_COMP_UPDATE_ARGS} --desired-config "${CONFIG_NAME}"
    done
    echo "All components updated successfully."
    exit 0
fi

while true; do
  RESULT=$(cray cfs components list --status pending --ids ${XNAMES} --format json | jq length)
  if [[ "${RESULT}" -eq 0 ]]; then
    break
  fi
  echo "Waiting for configuration to complete.  ${RESULT} components remaining."
  sleep 60
done

CONFIGURED=$(cray cfs components list --status configured --ids ${XNAMES} --format json | jq length)
FAILED=$(cray cfs components list --status failed --ids ${XNAMES} --format json | jq length)
echo "Configuration complete. ${CONFIGURED} component(s) completed successfully.  ${FAILED} component(s) failed."
if [ "${FAILED}" -ne "0" ]; then
   echo "The following components failed: $(cray cfs components list --status failed --ids ${XNAMES} --format json | jq -r '. | map(.id) | join(",")')"
fi
