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

usage()
{
   # Display Help
   echo "Runs CFS to setup passwordless ssh"
   echo "All parameters are optional and the values will be determined automatically if not set."
   echo
   echo "Usage: deploy_ssh_keys.sh [ --csm-release version ] [ --git-commit hash ]"
   echo "                            [ --git-clone-url url ] [ --ncn-config-file file ]"
   echo "                            [ --xnames xname1,xname2... ] [ --clear-state ]"
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

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
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
      usage
      exit 1
      ;;
  esac
done

## CONFIGURATION SETUP ##
if [[ -z "${RELEASE}" &&  -z "${VERSION}" ]]; then
    RELEASE=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' 2>/dev/null\
        | yq r -j - 2>/dev/null | jq -r ' to_entries | max_by(.key) | .key' 2>/dev/null)
    echo "Using latest release ${RELEASE}"
fi

if [[ -z "${VERSION}" ]]; then
    VERSION=$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' 2>/dev/null\
        | yq r -j - 2>/dev/null | jq -r ".[\"$RELEASE\"].configuration.import_branch" 2>/dev/null\
        | awk -F'/' '{ print $NF }')
    echo "Using csm configuration version ${VERSION}"
fi

CSM_CONFIG_FILE=$(mktemp csm-config-$VERSION-XXXXXX.json) ||
    err_exit "Failed to create temporary CSM configuration file with mktemp command (exit code=$?)"
NCN_CONFIG_FILE=$(mktemp new-ncn-personalization-XXXXXX.json) ||
    err_exit "Failed to create temporary NCN configuration file with mktemp command (exit code=$?)"

if [[ -z "${CLONE_URL}" ]]; then
    CLONE_URL="https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
fi

if [[ -z "${COMMIT}" ]]; then
    VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
    VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    TEMP_DIR=`mktemp -d`
    TEMP_HOME=$HOME
    HOME=$TEMP_DIR
    cd $TEMP_DIR
    echo "${CLONE_URL/\/\//\/\/${VCS_USER}:${VCS_PASSWORD}@}" > .git-credentials
    git config --file .gitconfig credential.helper store
    COMMIT=$(git ls-remote $CLONE_URL refs/heads/cray/csm/${VERSION} | awk '{print $1}')
    if [[ -n $COMMIT ]]; then
        echo "Found git commit ${COMMIT}"
    else
        echo "No git commit found"
        exit 1
    fi
    cd - >/dev/null 2>&1
    HOME=$TEMP_HOME
    rm -r $TEMP_DIR
fi

CONFIG="{
  \"layers\": [
    {
      \"name\": \"csm-${VERSION}\",
      \"cloneUrl\": \"$CLONE_URL\",
      \"commit\": \"${COMMIT}\",
      \"playbook\": \"site.yml\"
    }
  ]
}"

echo "Creating the configuration file ${CSM_CONFIG_FILE}"
echo $CONFIG | jq > $CSM_CONFIG_FILE

if [[ -n ${OLD_NCN_CONFIG_FILE} && -f ${OLD_NCN_CONFIG_FILE} ]]; then
    echo "Combining new CSM configuration $CSM_CONFIG_FILE with contents of ${OLD_NCN_CONFIG_FILE} to generate ${NCN_CONFIG_FILE}"
    jq -n --slurpfile new $CSM_CONFIG_FILE --slurpfile old $OLD_NCN_CONFIG_FILE \
        '{"layers": ($new[0].layers + ($old[0].layers | del(.[] | select(.cloneUrl == $new[0].layers[0].cloneUrl and .playbook == $new[0].layers[0].playbook))))}'\
        > ${NCN_CONFIG_FILE}
else
    echo "Creating new NCN configuration file ${NCN_CONFIG_FILE}"
    cp -p ${CSM_CONFIG_FILE} ${NCN_CONFIG_FILE}
fi

## RUNNING CFS ##
if [[ -z $XNAMES ]]; then
    echo "Retrieving a list of all management node component names (xnames)"
    XNAMES=$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
fi
XNAME_LIST=${XNAMES//,/ }

echo "Disabling configuration for all listed components"
for xname in $XNAME_LIST; do
    cray cfs components update $xname --enabled false
done

echo "Updating ncn-personalization configuration"
cray cfs configurations update ncn-personalization --file $NCN_CONFIG_FILE

if [[ -n $CLEAR_STATE ]]; then
    echo "Clearing state from all listed components"
    for xname in $XNAME_LIST; do
        cray cfs components update $xname --state []
    done
fi

echo "Setting desired configuration and enabling all listed components"
for xname in $XNAME_LIST; do
    cray cfs components update $xname --enabled true --error-count 0 --desired-config ncn-personalization
done

while true; do
  RESULT=$(cray cfs components list --status pending --ids ${XNAMES} --format json | jq length)
  if [[ "$RESULT" -eq 0 ]]; then
    break
  fi
  echo "Waiting for configuration to complete.  ${RESULT} components remaining."
  sleep 60
done

CONFIGURED=$(cray cfs components list --status configured --ids ${XNAMES} --format json | jq length)
FAILED=$(cray cfs components list --status failed --ids ${XNAMES} --format json | jq length)
echo "Configuration complete. $CONFIGURED component(s) completed successfully.  $FAILED component(s) failed."
if [ "$FAILED" -ne "0" ]; then
   echo "The following components failed: $(cray cfs components list --status failed --ids ${XNAMES} --format json | jq -r '. | map(.id) | join(",")')"
fi
