#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

upgrade_ncn="ncn-s001"

. ${BASEDIR}/ncn-upgrade-common.sh ${upgrade_ncn}

state_name="INSTALL_DOC_ON_STORAGE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="CEPH_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ssh $upgrade_ncn "cd /usr/share/doc/csm/upgrade/1.0/scripts/ceph;./ceph-upgrade.sh"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

ok_report
