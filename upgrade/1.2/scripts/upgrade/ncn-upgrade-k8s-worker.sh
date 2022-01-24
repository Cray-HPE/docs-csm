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

ssh_keygen_keyscan $1 || true # or true to unblock rerun

cfs_config_status=$(cray cfs components describe $UPGRADE_XNAME --format json | jq -r '.configurationStatus')
echo "CFS configuration status: ${cfs_config_status}"
if [[ $cfs_config_status != "configured" ]]; then
    echo "*************************************************"
    cat <<EOF
If the state is pending, the administrator may want to tail the logs of the CFS pod running on that node to watch the CFS job finish before rebooting this node. If the state is failed for this node, then it is unrelated to the upgrade process, and can be addressed independent of rebuilding this worker node.
EOF
    echo "*************************************************"
    read -p "Read and act on above steps. Press Enter key to continue ..."
fi

state_name="ENSURE_NEXUS_CAN_START_ON_ANY_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    kubectl get configmap -n nexus cray-precache-images -o json | jq -r '.data.images_to_cache' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image" 2>/dev/null; done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

cfs_config_status=$(cray cfs components describe $UPGRADE_XNAME --format json | jq -r '.configurationStatus')
echo "CFS configuration status: ${cfs_config_status}"
if [[ $cfs_config_status != "configured" ]]; then
    echo "*************************************************"
    cat <<EOF
Confirm the CFS configurationStatus after rebuilding the node. If the state is pending, the administrator may want to tail the logs of the CFS pod running on that node to watch the CFS job finish.

IMPORTANT: 
  The NCN personalization (CFS configuration) for a worker node which has been rebuilt should be complete before continuing in this process. If the state is failed for this node, it should be be addressed now.
EOF
    echo "*************************************************"
    read -p "Read and act on above steps. Press Enter key to continue ..."
fi

### redeploy cps if required
redeploy=$(cat /etc/cray/upgrade/csm/${CSM_RELEASE}/cp.deployment.snapshot | grep $upgrade_ncn | wc -l)
if [[ $redeploy == "1" ]];then
    cray cps deployment update --nodes $upgrade_ncn
    while [[ $(cray cps deployment list --nodes $upgrade_ncn |grep -E "state ="|grep -v "running" | wc -l) != 0 ]]
    do
        printf "%c" "."
        counter=$((counter+1))
        if [ $counter -gt 30 ]; then
            counter=0
            echo "ERROR: CPS is not running on $upgrade_ncn"
            cray cps deployment list --nodes $upgrade_ncn |grep -E "state ="
            exit 1
        fi
        sleep 5
    done
    cps_pod_assigned=$(kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $upgrade_ncn|wc -l)
    if [[ $cps_pod_assigned -ne 1 ]];then
        echo "ERROR: CPS pod is not assigned to $upgrade_ncn"
        kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $upgrade_ncn
        exit 1
    fi
fi

echo "******************************************"
echo "******************************************"
echo "**** Enter SSH password of switches: ****"
read -s -p "" SW_PASSWORD
echo
export SW_ARUBA_PASSWORD=$SW_PASSWORD
export SW_MELLANOX_PASSWORD=$SW_PASSWORD

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF

ssh $upgrade_ncn -t "SW_ARUBA_PASSWORD=$SW_PASSWORD SW_MELLANOX_PASSWORD=$SW_PASSWORD GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate"

ok_report
