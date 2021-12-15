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

# The UPGRADE_POSTGRES_MAX_LAG may be exported by the user to control
# the maximum lag value permitted by this script. Setting its value to
# a negative number or a non-integer value has the effect of skipping the
# maximum lag check. In other words, if one wishes to skip this check,
# one could:
# export UPGRADE_POSTGRES_MAX_LAG=skip
UPGRADE_POSTGRES_MAX_LAG=${UPGRADE_POSTGRES_MAX_LAG:-'0'}

# UPGRADE_POSTGRES_MAX_ATTEMPTS specifies the maximum number of times the
# postgres check will be performed on a given cluster before failing. Note that
# failures other than due to maximum lag are always fatal and are not retried.
# If unset or set to a non-positive integer, default to 10
if [[ ! $UPGRADE_POSTGRES_MAX_ATTEMPTS =~ ^[1-9][0-9]*$ ]]; then
    UPGRADE_POSTGRES_MAX_ATTEMPTS=10
fi

# UPGRADE_POSTGRES_WAIT_SECONDS_BETWEEN_ATTEMPTS specifies the time (in seconds)
# between postgres checks on a given cluster.
# If unset or set to a non-positive integer, default to 10
if [[ ! $UPGRADE_POSTGRES_WAIT_SECONDS_BETWEEN_ATTEMPTS =~ ^[1-9][0-9]*$ ]]; then
    UPGRADE_POSTGRES_WAIT_SECONDS_BETWEEN_ATTEMPTS=10
fi

state_name="ENSURE_POSTGRES_HEALTHY"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    SCRIPT_BASE="/opt/cray/tests/install/ncn/scripts"
    
    echo; echo "Check PostgresClusterStatus is 'Running' or 'Updating'"
    ${SCRIPT_BASE}/postgres_clusters_running.sh
    if [[ $? -ne 0 ]]
    then 
        echo "--- ERROR --- not all Postgresql Clusters have a status of 'Running'"
        exit 1
    fi

    echo; echo "Check for correct number of cluster members"
    ${SCRIPT_BASE}/postgres_pods_running.sh -p
    if [[ $? -ne 0 ]]
    then 
        echo "--- ERROR --- not all Postgresql Clusters have the correct number of members."
        exit 1
    fi

    echo; echo "Check for cluster leaders"
    ${SCRIPT_BASE}/postgres_clusters_leader.sh -p
    if [[ $? -ne 0 ]]
    then 
        echo "--- ERROR --- not all Postgresql Clusters have a leader."
        exit 1
    fi

    echo; echo "Check replication lag"
    ${SCRIPT_BASE}/postgres_replication_lag.sh -p -e 
    if [[ $? -ne 0 ]]
    then 
        echo "--- ERROR --- Postgresql Clusters have lag."
        exit 1
    fi

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

${BASEDIR}/../k8s/failover-leader.sh $upgrade_ncn

drain_node $upgrade_ncn

state_name="BACKUP_CREDENTIAL_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    scp ${upgrade_ncn}:/root/.ssh/id_rsa /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn
    scp ${upgrade_ncn}:/root/.ssh/authorized_keys /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn
    scp ${upgrade_ncn}:/etc/shadow /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

state_name="RESTORE_CREDENTIAL_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn/id_rsa ${upgrade_ncn}:/root/.ssh/id_rsa 
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn/authorized_keys ${upgrade_ncn}:/root/.ssh/authorized_keys
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$upgrade_ncn/shadow ${upgrade_ncn}:/etc/shadow 

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

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
    cps_state=$(cray cps deployment list --nodes $upgrade_ncn |grep -E "state ="|grep -v "running" | wc -l)
    if [[ $cps_state -ne 0 ]];then
        echo "ERROR: CPS is not running on $upgrade_ncn"
        cray cps deployment list --nodes $upgrade_ncn |grep -E "state ="
        exit 1
    fi
    cps_pod_assigned=$(kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $upgrade_ncn|wc -l)
    if [[ $cps_pod_assigned -ne 1 ]];then
        echo "ERROR: CPS pod is not assigned to $upgrade_ncn"
        kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $upgrade_ncn
        exit 1
    fi
fi

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
