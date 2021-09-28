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

err()
{
    echo "ERROR: $*" 1>&2
}

err_exit()
{
    err "$@"
    exit 1
}

run_cmd()
{
    "$@" || err_exit "Command failed with rc $?: $*"
}

run_mktemp()
{
    tmpfile=$(mktemp "$@") || err_exit "Command failed with rc $?: mktemp $*"
    [[ -n "${tmpfile}" ]] || err_exit "mktemp command passed but gave no output"
    [[ -e "${tmpfile}" ]] || err_exit "mktemp command passed but '${tmpfile}' does not exist"
    if [[ $# -gt 0 && "$1" == "-d" ]]; then
        [[ -d "${tmpfile}" ]] || err_exit "mktemp -d command passed and '${tmpfile}' exists, but is not a directory"
    else
        [[ -f "${tmpfile}" ]] || err_exit "mktemp command passed and '${tmpfile}' exists, but is not a regular file"
    fi
}

usage()
{
   # Display help
   echo "Updates CFS configurations"
   echo "All parameters are optional and the values will be determined automatically if not set."
   echo
   echo "Usage: apply_csm_configuration.sh [ --csm-release version ] [ --git-commit hash ]"
   echo "                                  [ --git-clone-url url ] [ --ncn-config-file file ]"
   echo "                                  [ --xnames xname1,xname2... ] [ --clear-state ]"
   echo
   echo "Options:"
   echo "csm-release          The version of the CSM release to use. (e.g. 1.6.11)"
   echo "git-commit           The git commit hash for CFS to use."
   echo "git-clone-url        The git clone url for CFS to use."
   echo "ncn-config-file      A file containing the NCN CFS configuration."
   echo "xnames               A comma-separated list of component names (xnames) to deploy to. All management nodes will be included if not set."
   echo "clear-state          Clears existing state from components to ensure CFS runs."
   echo
}

usage_err_exit()
{
    usage
    err_exit "usage: $*"
}

while [[ $# -gt 0 ]]; do
  key="$1"

  # Make sure that flags which require arguments get them
  case "${key}" in
    --csm-release|--csm-config-version|--git-commit|--git-clone-url|--ncn-config-file|--xnames)
      [[ $# -lt 2 ]] && usage_err_exit "${key} requires an argument"
      [[ -z "$2" ]] && usage_err_exit "Argument to ${key} may not be blank"
      ;;
  esac

  case "${key}" in
    --csm-release)
      RELEASE="$2"
      shift # past argument
      shift # past value
      ;;
    --csm-config-version)
      VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    --git-commit)
      COMMIT="$2"
      shift # past argument
      shift # past value
      ;;
    --git-clone-url)
      CLONE_URL="$2"
      shift # past argument
      shift # past value
      ;;
    --ncn-config-file)
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

## CONFIGURATION SETUP ##
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

run_mktemp "csm-config-$VERSION-XXXXXX.json"
CSM_CONFIG_FILE=${tmpfile}

run_mktemp "new-ncn-personalization-XXXXXX.json"
NCN_CONFIG_FILE=${tmpfile}

if [[ -z "${CLONE_URL}" ]]; then
    CLONE_URL="https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
fi

if [[ -z "${COMMIT}" ]]; then
    VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template='{{.data.vcs_username}}' | base64 --decode)
    [[ -n "${VCS_USER}" ]] || err_exit "Unable to obtain VCS username"
    VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template='{{.data.vcs_password}}' | base64 --decode)
    [[ -n "${VCS_PASSWORD}" ]] || err_exit "Unable to obtain VCS password"
    run_mktemp -d
    TEMP_DIR=${tmpfile}
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

#shellcheck disable=SC2089
CONFIG="{
  \"layers\": [
    {
      \"name\": \"csm-${VERSION}\",
      \"cloneUrl\": \"${CLONE_URL}\",
      \"commit\": \"${COMMIT}\",
      \"playbook\": \"site.yml\"
    }
  ]
}"

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

## RUNNING CFS ##
if [[ -z ${XNAMES} ]]; then
    echo "Retrieving a list of all management node component names (xnames)"
    XNAMES=$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
    [[ -n "${XNAMES}" ]] || err_exit "No management nodes found in HSM"
fi
XNAME_LIST=${XNAMES//,/ }

echo "Disabling configuration for all listed components"
for xname in ${XNAME_LIST}; do
    run_cmd cray cfs components update ${xname} --enabled false
done

echo "Updating ncn-personalization configuration"
run_cmd cray cfs configurations update ncn-personalization --file "${NCN_CONFIG_FILE}"

if [[ -n ${CLEAR_STATE} ]]; then
    echo "Clearing state from all listed components"
    for xname in ${XNAME_LIST}; do
        run_cmd cray cfs components update ${xname} --state []
    done
fi

echo "Setting desired configuration and enabling all listed components"
for xname in ${XNAME_LIST}; do
    run_cmd cray cfs components update ${xname} --enabled true --error-count 0 --desired-config ncn-personalization
done

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
