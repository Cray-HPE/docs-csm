#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

upgrade_ncn=$1

. ${BASEDIR}/ncn-upgrade-common.sh ${upgrade_ncn}

cat <<EOF
NOTE:

  On the stable ncn (master node), start a separate terminal that will watch the status of the ceph cluster.

  ncn-m001# watch ceph -s

  Every 2.0s: ceph -s                                    ncn-m001: Mon Apr 12 21:09:51 2021

    cluster:
      id:     0534e7c4-dea8-49f2-9c56-cc5be5c9b9f7
      health: HEALTH_OK
      .
      .
EOF
read -p "Read and act on above steps. Press any key to continue ..."

state_name="CEPH_PARTITIONS"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
    ssh $upgrade_ncn '/usr/share/doc/csm/upgrade/1.0/scripts/ceph/ceph-partitions-stage1.sh'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

cat <<EOF
NOTE: 
  Wait until ceph health is OK:

  Every 2.0s: ceph -s                                    ncn-m001: Mon Apr 12 21:09:51 2021

    cluster:
      id:     0534e7c4-dea8-49f2-9c56-cc5be5c9b9f7
      health: HEALTH_OK
EOF
read -p "Read and act on above steps. Press any key to continue ..."

ok_report