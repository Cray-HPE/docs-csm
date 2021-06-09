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

echo -e "${YELLOW}"
cat <<EOF
NOTE: 
    In upgrade/1.0/resource_material/stage3/k8s-worker-node-upgrade.md
    step 1 and 2 are not automated
EOF
read -p "Read and act on above steps. Press any key to continue ..."
echo -e "${NOCOLOR}"

state_name="ENSURE_NEXUS_CAN_START_ON_ANY_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    
    workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    yq r ./${CSM_RELEASE}/manifests/platform.yaml 'spec.charts(name==cray-precache-images).values.cacheImages[*]' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image"; done

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

# TODO: automate this by a while loop
echo -e "${YELLOW}"
cat <<EOF
NOTE: 
    Ensure that the previously rebuilt worker node (if applicable) has started any etcd pods (if necessary). We don't want to begin rebuilding the next worker node until etcd pods have reached quorum. Run the following command, and pause on this step until all pods are in a Running state:

    kubectl get po -A -l 'app=etcd' | grep -v "Running"

EOF
read -p "Read and act on above steps. Press any key to continue ..."
echo -e "${NOCOLOR}"

# TODO: duplicate code
state_name="DRAIN_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    /usr/share/doc/csm/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $UPGRADE_NCN
    
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

${BASEDIR}/ncn-upgrade-k8s-nodes.sh $upgrade_ncn

ssh $upgrade_ncn 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

echo -e "${YELLOW}"
cat <<EOF
If above test failed, try to fix it based on test output. Then run the test again:

ssh $upgrade_ncn 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

read -p "Press any key to continue ..."
echo -e "${NOCOLOR}"