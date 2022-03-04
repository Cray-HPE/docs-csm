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
basedir=$(dirname $0)
. ${basedir}/../common/upgrade-state.sh
trap 'err_report' ERR

target_ncn=$1

. ${basedir}/../common/ncn-common.sh ${target_ncn}

ssh_keygen_keyscan $1 || true # or true to unblock rerun

cfs_config_status=$(cray cfs components describe $TARGET_XNAME --format json | jq -r '.configurationStatus')
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
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    workers="$(kubectl get node --selector='!node-role.kubernetes.io/master' -o name | sed -e 's,^node/,,' | paste -sd,)"
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    kubectl get configmap -n nexus cray-precache-images -o json | jq -r '.data.images_to_cache' | while read image; do echo >&2 "+ caching $image"; pdsh -w "$workers" "crictl pull $image" 2>/dev/null; done

    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# Ensure that the previously rebuilt worker node (if applicable) has started any etcd pods (if necessary).
# We do not want to begin rebuilding the next worker node until etcd pods have reached quorum.
state_name="ENSURE_ETCD_PODS_RUNNING"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
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
            exit 1
        fi
    done

    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="ENSURE_POSTGRES_HEALTHY"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    wget -q http://rgw-vip.nmn/ncn-utils/csi;chmod 0755 csi; mv csi /usr/local/bin/csi
    csi pit validate --postgres

    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

drain_node $target_ncn

state_name="BACKUP_CREDENTIAL_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi
    scp ${target_ncn}:/root/.ssh/id_rsa /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn
    scp ${target_ncn}:/root/.ssh/authorized_keys /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn
    scp ${target_ncn}:/etc/shadow /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn

    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

csi handoff bss-update-param --set metal.no-wipe=0 --limit $TARGET_XNAME
${basedir}/../common/ncn-rebuild-common.sh $target_ncn

# TODO: wait for k8s

state_name="RESTORE_CREDENTIAL_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn/id_rsa ${target_ncn}:/root/.ssh/id_rsa 
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn/authorized_keys ${target_ncn}:/root/.ssh/authorized_keys
    scp /etc/cray/upgrade/csm/$CSM_RELEASE/$target_ncn/shadow ${target_ncn}:/etc/shadow 

    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

cfs_config_status=$(cray cfs components describe $TARGET_XNAME --format json | jq -r '.configurationStatus')
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

### redeploy CPS if required
redeploy=$(cat /etc/cray/upgrade/csm/${CSM_RELEASE}/cp.deployment.snapshot | grep $target_ncn | wc -l)
if [[ $redeploy == "1" ]];then
    cray cps deployment update --nodes $target_ncn
    # We will retry for a few minutes before giving up
    tmpfile=/tmp/cray-cps-deployment-list.${target_ncn}.$$.$(date +%Y-%m-%d_%H-%M-%S.%N).tmp
    count=0
    while [ true ]; do
        if ! cray cps deployment list --nodes $target_ncn > $tmpfile ; then
            # This command can fail when a node is first being brought up and deploying its CPS pods.
            if [[ $count -gt 30 ]]; then
                rm -f "$tmpfile" >/dev/null 2>&1 || true
                echo "ERROR: Command still failing after retries: Command failed: cray cps deployment list --nodes $target_ncn"
                exit 1
            fi
            echo "Command failed: cray cps deployment list --nodes $target_ncn; retrying in 5 seconds"
            sleep 5
            let count += 1
            continue
        fi
        cps_state=$(grep -E "state =" "$tmpfile"|grep -v "running" | wc -l)
        if [[ $cps_state -ne 0 ]];then
            if [[ $count -gt 30 ]]; then
                echo "ERROR: CPS is not running on $target_ncn"
                cray cps deployment list --nodes $target_ncn |grep -E "state ="
                rm -f "$tmpfile" >/dev/null 2>&1 || true
                exit 1
            fi
            echo "CPS not running yet on $target_ncn; checking again in 5 seconds"
            sleep 5
            let count += 1
            continue
        fi
        rm -f "$tmpfile" >/dev/null 2>&1 || true
        cps_pod_assigned=$(kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $target_ncn|wc -l)
        if [[ $cps_pod_assigned -ne 1 ]];then
            if [[ $count -gt 30 ]]; then
                echo "ERROR: CPS pod is not assigned to $target_ncn"
                kubectl get pod -A -o wide|grep cray-cps-cm-pm|grep $target_ncn
                exit 1
            fi
            echo "CPS pod not assigned yet to $target_ncn; checking again in 5 seconds"
            sleep 5
            let count += 1
            continue
        fi
        break
    done
fi

state_name="ENSURE_KEY_PODS_HAVE_STARTED"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    while true; do
      output=$(kubectl get po -A -o wide | grep -e etcd -e speaker | grep $target_ncn | awk '{print $4}')
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
        echo "All etcd and speaker pods are running on $target_ncn"
        break
      fi
      echo "Some etcd and speaker pods are not running on $target_ncn -- sleeping for 10 seconds..."
      sleep 10
    done
    ssh $target_ncn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi
echo "******************************************"
echo "******************************************"
echo "**** Enter SSH password of switches: ****"
read -s -p "" SW_ADMIN_PASSWORD
echo

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF

ssh $target_ncn -t "SW_ADMIN_PASSWORD=$SW_ADMIN_PASSWORD GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate"

ok_report

