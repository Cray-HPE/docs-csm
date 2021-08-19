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
read -p "Read and act on above steps. Press Enter key to continue ..."

state_name="ENSURE_NEXUS_CAN_START_ON_ANY_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    yq r ${CSM_ARTI_DIR}/manifests/platform.yaml 'spec.charts(name==cray-precache-images).values.cacheImages[*]' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image"; done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# Ensure that the previously rebuilt worker node (if applicable) has started any etcd pods (if necessary). 
# We do not want to begin rebuilding the next worker node until etcd pods have reached quorum. 
state_name="ENSURE_ETCD_PODS_RUNNING"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    while [[ "$(kubectl get po -A -l 'app=etcd' | grep -v "Running"| wc -l)" != "1" ]]; do 
        echo "Some etcd pods are not in running state, wait for 5s ..."
        kubectl get po -A -l 'app=etcd' | grep -v "Running"
        sleep 5
    done

    etcdClusters=$(kubectl get Etcdclusters -n services | grep "cray-"|awk '{print $1}')
    for cluster in $etcdClusters
    do 
        numOfPods=$(kubectl get pods -A -l 'app=etcd'| grep $cluster | grep "Running" | wc -l)
        if [[ $numOfPods -ne 3 ]];then
            echo "ERROR - Etcd cluster: $cluster should have 3 pods running but only $numOfPods are running"
        fi
    done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

${BASEDIR}/../k8s/failover-leader.sh $upgrade_ncn

drain_node $upgrade_ncn

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

state_name="ENSURE_KEY_PODS_HAVE_STARTED"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    while true; do
      output=$(kubectl get po -A -o wide | grep -e etcd -e speaker | grep $upgrade_ncn | awk '{print $4}')
      if [ ! -n "$output" ]; then
        #
        # No pods scheduled to start on this node, we are done
        #
        break
      fi
      set +e
      echo "$output" | grep -v -e Running -e Completed > /dev/null
      rc=$?
      set -e
      if [[ "$rc" -eq 1 ]]; then
        echo "All etcd and speaker pods are running on $upgrade_ncn"
        break
      fi
      echo "Some etcd and speaker pods are not running on $upgrade_ncn -- sleeping for 10 seconds..."
      sleep 10
    done
    ssh $upgrade_ncn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
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
