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

ssh_keygen_keyscan $1

# Back up local files and directories used by System Admin Toolkit (SAT)
state_name="BACKUP_SAT_LOCAL_FILES"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    sat_paths_to_backup="/root/.config/sat/sat.toml
        /root/.config/sat/tokens/
        /root/.config/sat/s3_access_key
        /root/.config/sat/s3_secret_key
        /var/log/cray/sat/sat.log"
    # We would use mktemp here, but that will not work if this script runs multiple times.
    sat_backup_directory="/tmp/sat-backup-${upgrade_ncn}"
    mkdir -p $sat_backup_directory
    for path in $sat_paths_to_backup; do
        # Check path exists on the remote host
        if ssh "$upgrade_ncn" "ls $path" 2>/dev/null; then
            echo "Copying $path from $upgrade_ncn to $sat_backup_directory"
            mkdir -p "$(dirname "${sat_backup_directory}/${path}")"
            rsync -azl "${upgrade_ncn}:${path}" "${sat_backup_directory}/${path}"
        else
            echo "Path $path does not exist on host $upgrade_ncn"
        fi
    done
    echo "SAT local files backed up to $sat_backup_directory"
    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
   state_name="BACKUP_M001_NET_CONFIG"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."

      scp root@ncn-m001:/etc/sysconfig/network/ifcfg-lan0 .
      record_state "${state_name}" ${upgrade_ncn}
   else
      echo "====> ${state_name} has been completed"
   fi
fi

first_master_hostname=`curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | \
     jq -r '.[] | ."cloud-init"."meta-data"."first-master-hostname"'`
if [[ ${first_master_hostname} == ${upgrade_ncn} ]]; then
   state_name="RECONFIGURE_FIRST_MASTER"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      promotingMaster="none"
      masterNodes=$(kubectl get nodes| grep "ncn-m" | awk '{print $1}')
      for node in $masterNodes; do
        # skip upgrade_ncn
        if [[ ${node} == ${upgrade_ncn} ]]; then
            continue;
        fi
        # check if cloud-init data is healthy
        ssh $node -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'cloud-init query -a > /dev/null 2>&1'
        rc=$?
        if [[ "$rc" -eq 0 ]]; then
            promotingMaster=$node
            echo "Promote: ${promotingMaster} to be FIRST_MASTER"
            break;
        fi
      done

      if [[ ${promotingMaster} == "none" ]];then
        echo "No master nodes has healthy cloud-init metadata, fail upgrade. You may try to upgrade another master node first. If that still fails, we do not have any master nodes that can be promoted."
        exit 1
      fi

      VERBOSE=1 csi handoff bss-update-cloud-init --set meta-data.first-master-hostname=$promotingMaster --limit Global
      ssh $promotingMaster -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
      ssh $promotingMaster -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "/usr/share/doc/csm/upgrade/1.0.1/scripts/k8s/promote-initial-master.sh"

      record_state "${state_name}" ${upgrade_ncn}
   else
      echo "====> ${state_name} has been completed"
   fi
fi


state_name="STOP_ETCD_SERVICE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    ssh $upgrade_ncn 'systemctl daemon-reload'
    ssh $upgrade_ncn 'systemctl stop etcd.service'
    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="PREPARE_ETCD"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    export MEMBER_ID=$(etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/ca.crt \
     --key=/etc/kubernetes/pki/etcd/ca.key \
     --endpoints=localhost:2379 member list | \
     grep $upgrade_ncn | cut -d ',' -f1)

     etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/ca.crt \
     --key=/etc/kubernetes/pki/etcd/ca.key \
     --endpoints=localhost:2379 member remove $MEMBER_ID

     etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/ca.crt  \
      --key=/etc/kubernetes/pki/etcd/ca.key \
      --endpoints=localhost:2379 \
      member add $upgrade_ncn --peer-urls=https://$UPGRADE_IP_NMN:2380

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

drain_node $upgrade_ncn

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

# Restore files used by the System Admin Toolkit (SAT) that were previously backed up
state_name="RESTORE_SAT_LOCAL_FILES"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    sat_backup_directory="/tmp/sat-backup-${upgrade_ncn}/"
    # Check the existence of the SAT backup directory. The directory missing should
    # not happen, but if it does the upgrade script probably should not fail.
    if [ -d "$sat_backup_directory" ]; then
        # Do not preserve ownership as this could lead to the owner of /root/ changing.
        rsync -az --no-o "$sat_backup_directory" "${upgrade_ncn}:/"
    else
        echo "$sat_backup_directory does not exist"
    fi
    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# Install the docs-csm on newly upgraded master
state_name="INSTALL_DOCS_NEW_MASTER"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    record_state "${state_name}" ${upgrade_ncn}
    ssh $upgrade_ncn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
else
    echo "====> ${state_name} has been completed"
fi

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF
ssh $upgrade_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

ok_report
