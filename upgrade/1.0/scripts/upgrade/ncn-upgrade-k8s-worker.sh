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
    In upgrade/1.0/resource_material/k8s/worker-reference.md
    step 1 and 2 are not automated
EOF
read -p "Read and act on above steps. Press any key to continue ..."

state_name="ENSURE_NEXUS_CAN_START_ON_ANY_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    yq r ./${CSM_RELEASE}/manifests/platform.yaml 'spec.charts(name==cray-precache-images).values.cacheImages[*]' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image"; done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# Ensure that the previously rebuilt worker node (if applicable) has started any etcd pods (if necessary). 
# We don't want to begin rebuilding the next worker node until etcd pods have reached quorum. 
state_name="ENSURE_ETCD_PODS_RUNNING"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    while [[ "$(kubectl get po -A -l 'app=etcd' | grep -v "Running"| wc -l)" != "1" ]]; do 
        echo "Some etcd pods are not in running state, wait for 5s ..."
        kubectl get po -A -l 'app=etcd' | grep -v "Running"
        sleep 5
    done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

drain_node $upgrade_ncn

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn
read -s -p "Enter SSH password of switches:" SW_PASSWORD
export SW_ARUBA_PASSWORD=$SW_PASSWORD
export SW_MELLANOX_PASSWORD=$SW_PASSWORD

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF

ssh -o SendEnv=SW_ARUBA_PASSWORD SendEnv=SW_MELLANOX_PASSWORD $upgrade_ncn -t "GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate"

ok_report