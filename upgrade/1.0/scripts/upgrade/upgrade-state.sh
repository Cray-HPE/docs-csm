#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#


function record_state () {
    state_name=$1
    upgrade_ncn=$2
    if [[ -z ${state_name} ]]; then
        echo "state name is not specified"
        exit 1
    fi
    if [[ -z ${upgrade_ncn} ]]; then
        echo "upgrade ncn is not specified"
        exit 1
    fi
    state_recorded=$(is_state_recorded $state_name $upgrade_ncn)
    if [[ $state_recorded == "0" ]]; then
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${state_name}" >> .${upgrade_ncn}
    fi
}

function is_state_recorded () {
    state_name=$1
    upgrade_ncn=$2
    if [[ -z ${state_name} ]]; then
        echo "state name is not specified"
        exit 1
    fi
    if [[ -z ${upgrade_ncn} ]]; then
        echo "upgrade ncn is not specified"
        exit 1
    fi
    state_recorded=$(cat .${upgrade_ncn} | grep "${state_name}" | wc -l)
    if [[ ${state_recorded} != 0 ]]; then
        echo "1"
    else
        echo "0"
    fi
}

function err_report() {
    echo
    echo "[ERROR] - Unexpected errors, check output above"
}

function ok_report() {
    echo
    echo "[OK] - Succeffully completed"
}