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

set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR

upgrade_ncn=$1

. ${BASEDIR}/ncn-upgrade-common.sh ${upgrade_ncn}

skipCephInitial=$(sort -V /tmp/csm_versions | tail -1 | grep "1.0.1" | wc -l)
if [[ $skipCephInitial -eq 1 ]]; then
    echo "It is running on 1.0.1 already. Skip ceph upgrade"
    exit 0
fi


cat <<EOF
NOTE:

  On the stable NCN (master node), start a separate terminal that will watch the status of the Ceph cluster.

  ncn-m001# watch ceph -s

  Every 2.0s: ceph -s                                    ncn-m001: Mon Apr 12 21:09:51 2021

    cluster:
      id:     0534e7c4-dea8-49f2-9c56-cc5be5c9b9f7
      health: HEALTH_OK
      .
      .
EOF
read -p "Read and act on above steps. Press Enter key to continue ..."

state_name="CEPH_PARTITIONS"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
    ssh $upgrade_ncn '/usr/share/doc/csm/upgrade/1.0.1/scripts/ceph/ceph-partitions-stage1.sh'

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
read -p "Read and act on above steps. Press Enter key to continue ..."

ok_report