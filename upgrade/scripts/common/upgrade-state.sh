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

CSM_REL_NAME=${CSM_REL_NAME-"csm-${CSM_RELEASE}"}
mkdir -p "/etc/cray/upgrade/csm/${CSM_REL_NAME}"

function record_state () {
    state_name=$1
    local target_ncn=$2
    local state_dir="/etc/cray/upgrade/csm/${CSM_REL_NAME}/${target_ncn}"

    mkdir -p "${state_dir}"

    if [[ -z ${state_name} ]]; then
        echo "state name is not specified"
        exit 1
    fi
    if [[ -z ${target_ncn} ]]; then
        echo "upgrade ncn is not specified"
        exit 1
    fi
    state_recorded=$(is_state_recorded $state_name $target_ncn)
    if [[ $state_recorded == "0" ]]; then
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${state_name}" >> "${state_dir}/state"
    fi
    echo "====> ${state_name} has been completed"
}

function is_state_recorded () {
    state_name=$1
    local target_ncn=$2
    local state_dir="/etc/cray/upgrade/csm/${CSM_REL_NAME}/${target_ncn}"

    mkdir -p "${state_dir}"

    if [[ -z ${state_name} ]]; then
        echo "state name is not specified"
        exit 1
    fi
    if [[ -z ${target_ncn} ]]; then
        echo "upgrade ncn is not specified"
        exit 1
    fi
    state_recorded=$(grep "${state_name}" "${state_dir}/state" 2>/dev/null | wc -l)
    if [[ ${state_recorded} != 0 ]]; then
        echo "1"
    else
        echo "0"
    fi
}

function move_state_file () {
    # we only rename the state file
    # this will not block another upgrade/rebuild/reboot
    # it also leaves a trace of what happened before
    local target_ncn=$1
    local state_dir="/etc/cray/upgrade/csm/${CSM_REL_NAME}/${target_ncn}"
    
    mv "${state_dir}/state" "${state_dir}/state.bak"
}

function err_report() {
    #shellcheck disable=SC2155
    local caller="$(caller)"
    local cmd="$BASH_COMMAND"
    if [[ -n $NO_ERROR_TRAP ]]; then
        return 0
    fi
    # add more logging to capture next where exactly the error happened
    echo "${caller}"
    echo "${cmd}"

    # restore previous ssh config if there was one, remove ours
    rm -f /root/.ssh/config
    test -f /root/.ssh/config.bak && mv /root/.ssh/config.bak /root/.ssh/config

    # ignore some internal expected errors
    local ignoreCmd="cray artifacts list config-data"
    shouldIgnore=$(echo "$cmd" | grep "${ignoreCmd}" | wc -l)
    if [[ ${shouldIgnore} -eq 1 ]]; then
        return 0
    fi

    ignoreCmd="https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history"
    shouldIgnore=$(echo "$cmd" | grep "${ignoreCmd}" | wc -l)
    if [[ ${shouldIgnore} -eq 1 ]]; then
        return 0
    fi

    ignoreCmd="csi automate ncn etcd --action add-member --ncn"
    shouldIgnore=$(echo "$cmd" | grep "${ignoreCmd}" | wc -l)
    if [[ ${shouldIgnore} -eq 1 ]]; then
        return 0
    fi
    
    # check if /dev/tty is available, it is not available when using argo workflows
    if sh -c ": >/dev/tty" >/dev/null 2>/dev/null; then
        # /dev/tty is available and usable
        # force output to console regardless of redirection
        echo >/dev/tty 
        echo "[ERROR] - Unexpected errors, check logs: ${LOG_FILE}" >/dev/tty
    else
        # /dev/tty is not available
        echo
        echo "[ERROR] - Unexpected errors, check logs: ${LOG_FILE}"
    fi
    # avoid shell double trap
    NO_ERROR_TRAP=1
}

function ok_report() {
    # check if /dev/tty is available, it is not available when using argo workflows
    if sh -c ": >/dev/tty" >/dev/null 2>/dev/null; then
        # /dev/tty is available and usable
        # force output to console regardless of redirection
        echo >/dev/tty 
        echo "[OK] - Successfully completed" >/dev/tty
    else
        # /dev/tty is not available
        echo
        echo "[OK] - Successfully completed"
    fi
    # avoid shell double trap
    NO_ERROR_TRAP=1
}

function argo_err_report() {
    #shellcheck disable=SC2155
    local caller="$(caller)"
    local cmd="$BASH_COMMAND"
    if [[ -n $NO_ERROR_TRAP ]]; then
        return 0
    fi
    # add more logging to capture next where exactly the error happened
    echo "${caller}"
    echo "${cmd}"

    # in case we have left over temp files
    rm -f /tmp/argo-res.* > /dev/null 2>&1 || true

    echo
    echo "[ERROR] - Unexpected errors"
    # avoid shell double trap
    NO_ERROR_TRAP=1
}
