#!/bin/bash
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

set -e
locOfScript=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${locOfScript}/../common/upgrade-state.sh
CSM_ARTI_DIR="not_set"
#shellcheck disable=SC2046
. ${locOfScript}/../common/ncn-common.sh $(hostname)
trap 'err_report' ERR
# array for paths to unmount after chrooting images
#shellcheck disable=SC2034
declare -a UNMOUNTS=()
DELETE_TARBALL_FILE=Y

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --csm-version)
        CSM_RELEASE="$2"
        CSM_REL_NAME="csm-${CSM_RELEASE}"
        shift # past argument
        shift # past value
        ;;
        --endpoint)
        ENDPOINT="$2"
        shift # past argument
        shift # past value
        ;;
        --no-delete-tarball-file)
        DELETE_TARBALL_FILE=N
        shift # past argument
        ;;
        --tarball-file)
        TARBALL_FILE="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        echo "[ERROR] - unknown options"
        exit 1
        ;;
    esac
done

if [[ -z ${LOG_FILE} ]]; then
    LOG_FILE="/root/output.log"
    echo
    echo
    echo " ************"
    echo " *** NOTE ***"
    echo " ************"
    echo "LOG_FILE is not specified; use default location: ${LOG_FILE}"
    echo
fi

if [[ -z ${CSM_RELEASE} ]]; then
    echo "CSM RELEASE is not specified"
    exit 1
fi

if [[ -z ${TARBALL_FILE} ]]; then
    # Download tarball from internet

    if [[ -z ${ENDPOINT} ]]; then
        # default endpoint to internal artifactory
        ENDPOINT=https://artifactory.algol60.net/artifactory/csm-releases/csm/1.3/
        echo "Use internal endpoint: ${ENDPOINT}"
    fi

    # Ensure we have enough disk space
    reqSpace=80000000 # ~80GB
    availSpace=$(df "/etc/cray/upgrade/csm" | awk 'NR==2 { print $4 }')
    # Validate that we received a nonnegative integer for the amount of available space
    if ! [[ $availSpace =~ ^(0|[1-9][0-9]*)$ ]]; then
        echo "ERROR: Invalid free space reported by df command: $availSpace"
        exit 1
    elif (( availSpace < reqSpace )); then
        echo "Not enough space; required: $reqSpace, available space: $availSpace" >&2
        exit 1
    fi

    # Download tarball file
    state_name="GET_CSM_TARBALL_FILE"
    #shellcheck disable=SC2046
    state_recorded=$(is_state_recorded "${state_name}" $(hostname))
    if [[ $state_recorded == "0" ]]; then
        # Because we are getting a new tarball
        # this has to be a new upgrade
        # clean up myenv 
        rm -rf /etc/cray/upgrade/csm/myenv || true
        touch /etc/cray/upgrade/csm/myenv
        echo "====> ${state_name} ..."
        {
        wget --progress=dot:giga ${ENDPOINT}/${CSM_REL_NAME}.tar.gz -P /etc/cray/upgrade/csm/
        # set TARBALL_FILE to newly downloaded file
        TARBALL_FILE=/etc/cray/upgrade/csm/${CSM_REL_NAME}.tar.gz
        } >> ${LOG_FILE} 2>&1
        #shellcheck disable=SC2046
        record_state ${state_name} $(hostname)
        echo
    else
        echo "====> ${state_name} has been completed"
    fi
fi

# untar csm tarball file
state_name="UNTAR_CSM_TARBALL_FILE"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    mkdir -p /etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball
    tar -xzf ${TARBALL_FILE} -C /etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball
    CSM_ARTI_DIR=/etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball/${CSM_REL_NAME}
    if [[ "${DELETE_TARBALL_FILE}" != N ]]; then
        rm -rf "${TARBALL_FILE}"
    fi

    # if we have to untar a file, we assume this is a new upgrade
    # remove existing myenv file just in case
    rm -rf /etc/cray/upgrade/csm/myenv
    echo "export CSM_ARTI_DIR=/etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball/${CSM_REL_NAME}" >> /etc/cray/upgrade/csm/myenv
    echo "export CSM_RELEASE=${CSM_RELEASE}" >> /etc/cray/upgrade/csm/myenv
    echo "export CSM_REL_NAME=${CSM_REL_NAME}" >> /etc/cray/upgrade/csm/myenv
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_CSI"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    #shellcheck disable=SC2046
    rpm --force -Uvh $(find ${CSM_ARTI_DIR}/rpm/cray/csm/ -name "cray-site-init*.rpm") 

    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="INSTALL_CANU"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    #shellcheck disable=SC2046
    rpm --force -Uvh $(find ${CSM_ARTI_DIR}/rpm/cray/csm/ -name "canu*.rpm") 
    } >> ${LOG_FILE} 2>&1
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

ok_report

