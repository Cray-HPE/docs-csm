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

. /etc/cray/upgrade/csm/myenv

state_name="VERIFY_K8S_NODES_UPGRADED"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/verify-k8s-nodes-upgraded.sh

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PRE_CEPH_CSI_UPGRADE_REQUIREMENTS"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    scp ncn-s001:/srv/cray/scripts/common/csi-configuration.sh /tmp/csi-configuration.sh
    mkdir -p /srv/cray/tmp
    . /tmp/csi-configuration.sh
    create_ceph_rbd_1.2_csi_configmap
    create_ceph_cephfs_1.2_csi_configmap
    create_k8s_1.2_ceph_secrets
    create_sma_1.2_ceph_secrets
    create_cephfs_1.2_ceph_secrets
    create_k8s_1.2_storage_class
    create_sma_1.2_storage_class
    create_cephfs_1.2_storage_class

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="PRE_STRIMZI_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    pushd /usr/share/doc/csm/upgrade/1.2/scripts/strimzi
    ./kafka-prereq.sh
    popd +0

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="CSM_SERVICE_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    pushd ${CSM_ARTI_DIR}
    ./upgrade.sh
    popd +0

    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_ENABLE_PSP"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/enable-psp.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_STRIMZI_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    /usr/share/doc/csm/upgrade/1.2/scripts/strimzi/kafka-restart.sh
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

ok_report
