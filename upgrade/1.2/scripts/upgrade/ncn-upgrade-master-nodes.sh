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

ssh_keygen_keyscan $1

# Back up local files and directories used by System Admin Toolkit (SAT)
state_name="BACKUP_SAT_LOCAL_FILES"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    sat_paths_to_backup="/root/.config/sat/sat.toml
        /root/.config/sat/tokens/
        /root/.config/sat/s3_access_key
        /root/.config/sat/s3_secret_key
        /var/log/cray/sat/sat.log"
    # We would use mktemp here, but that will not work if this script runs multiple times.
    sat_backup_directory="/tmp/sat-backup-${target_ncn}"
    mkdir -p $sat_backup_directory
    for path in $sat_paths_to_backup; do
        # Check path exists on the remote host
        if ssh "$target_ncn" "ls $path" 2>/dev/null; then
            echo "Copying $path from $target_ncn to $sat_backup_directory"
            mkdir -p "$(dirname "${sat_backup_directory}/${path}")"
            rsync -azl "${target_ncn}:${path}" "${sat_backup_directory}/${path}"
        else
            echo "Path $path does not exist on host $target_ncn"
        fi
    done
    echo "SAT local files backed up to $sat_backup_directory"
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

if [[ ${target_ncn} == "ncn-m001" ]]; then
   state_name="BACKUP_M001_NET_CONFIG"
   state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."

      scp root@ncn-m001:/etc/sysconfig/network/ifcfg-lan0 .
      record_state "${state_name}" ${target_ncn}
   else
      echo "====> ${state_name} has been completed"
   fi
fi

first_master_hostname=`curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | \
     jq -r '.[] | ."cloud-init"."meta-data"."first-master-hostname"'`
if [[ ${first_master_hostname} == ${target_ncn} ]]; then
   state_name="RECONFIGURE_FIRST_MASTER"
   state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      promotingMaster="none"
      masterNodes=$(kubectl get nodes| grep "ncn-m" | awk '{print $1}')
      for node in $masterNodes; do
        # skip target_ncn
        if [[ ${node} == ${target_ncn} ]]; then
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

      ssh $promotingMaster -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
      ssh $promotingMaster -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "/usr/share/doc/csm/upgrade/1.2/scripts/k8s/promote-initial-master.sh"
      VERBOSE=1 csi handoff bss-update-cloud-init --set meta-data.first-master-hostname=$promotingMaster --limit Global

      record_state "${state_name}" ${target_ncn}
   else
      echo "====> ${state_name} has been completed"
   fi
fi

state_name="PREPARE_ETCD"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    csi automate ncn etcd --action remove-member --ncn $target_ncn --kubeconfig /etc/kubernetes/admin.conf
    ssh $target_ncn 'systemctl daemon-reload'
    ssh $target_ncn 'systemctl stop etcd.service'
    csi automate ncn etcd --action add-member --ncn $target_ncn --kubeconfig /etc/kubernetes/admin.conf
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

drain_node $target_ncn

csi handoff bss-update-param --set metal.no-wipe=0 --limit $TARGET_XNAME
${basedir}/../common/ncn-rebuild-common.sh $target_ncn

# Restore files used by the System Admin Toolkit (SAT) that were previously backed up
state_name="RESTORE_SAT_LOCAL_FILES"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    sat_backup_directory="/tmp/sat-backup-${target_ncn}/"
    # Check the existence of the SAT backup directory. The directory missing should
    # not happen, but if it does the upgrade script probably should not fail.
    if [ -d "$sat_backup_directory" ]; then
        # Do not preserve ownership as this could lead to the owner of /root/ changing.
        rsync -az --no-o "$sat_backup_directory" "${target_ncn}:/"
    else
        echo "$sat_backup_directory does not exist"
    fi
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# Install the docs-csm on newly upgraded master
state_name="INSTALL_DOCS_NEW_MASTER"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    record_state "${state_name}" ${target_ncn}
    ssh $target_ncn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
else
    echo "====> ${state_name} has been completed"
fi

if [[ ${target_ncn} != "ncn-m001" ]]; then
   state_name="UPDATE_M001_KUBEAPI_SERVICE_ISSUER"
   state_recorded=$(is_state_recorded "${state_name}" ncn-m001)
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."

      /usr/share/doc/csm/upgrade/1.2/scripts/k8s/update_kubeapi_service_issuer.sh ncn-m001

      record_state "${state_name}" ncn-m001
   else
      echo "====> ${state_name} has been completed"
   fi
fi

# Update kubeapi istio-ca audience newly upgraded master
state_name="UPDATE_KUBEAPI_ISTIO_CA"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
   echo "====> ${state_name} ..."

   /usr/share/doc/csm/upgrade/1.2/scripts/k8s/update_kubeapi_istio_ca.sh ${target_ncn}

   record_state "${state_name}" ${target_ncn}
else
   echo "====> ${state_name} has been completed"
fi

cat <<EOF
NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF
ssh $target_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

move_state_file ${target_ncn}

ok_report
