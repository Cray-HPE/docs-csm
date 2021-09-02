#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

. /etc/cray/upgrade/csm/myenv

state_name="POST_CSM_UPDATE_SPIRE_ENTRIES"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.1/scripts/upgrade/update-spire-entries.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_JOIN_SPIRE_ON_STORAGE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.1/scripts/upgrade/join-spire-on-storage.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

ok_report
