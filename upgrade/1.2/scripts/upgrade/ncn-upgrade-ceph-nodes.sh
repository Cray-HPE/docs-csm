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
basedir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${basedir}/../common/upgrade-state.sh
trap 'err_report' ERR

target_ncn=$1

. ${basedir}/../common/ncn-common.sh ${target_ncn}

# Record this state locally instead of using is_state_recorded(),
# because it does not hurt to re-do the SSH keys, and it is the
# kind of thing which may need to be re-done in case of problems.
ssh_keys_done=0

state_name="CEPH_NODES_SET_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    csi handoff bss-update-cloud-init --set meta-data.wipe-ceph-osds=no --limit Global
    
    csi handoff bss-update-param \
        --set metal.no-wipe=1 \
        --limit $TARGET_XNAME
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_CEPH_DATA"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi

    ## TEMP - Remove ceph v15.2.12 from images before backups - CASMINST-4099
    if [[ $(ssh ${target_ncn} "podman images --format json|jq '.[].Names|.[]'|grep -q 15.2.12") ]]
    then
      ssh ${target_ncn} 'podman rmi -af'
    fi
    ## END TEMP - CASMINST-4099

    ssh ${target_ncn} 'systemctl stop ceph.target;sleep 30;podman prune -af;tar -zcvf /tmp/$(hostname)-ceph.tgz /var/lib/ceph /var/lib/containers /etc/ceph;systemctl start ceph.target'
    scp ${target_ncn}:/tmp/${target_ncn}-ceph.tgz .
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

${basedir}/../common/ncn-rebuild-common.sh $target_ncn

state_name="INSTALL_TARGET_SCRIPT"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi
    scp /root/docs-csm-latest.noarch.rpm $target_ncn:/root/docs-csm-latest.noarch.rpm
    ssh $target_ncn "rpm --force -Uvh /root/docs-csm-latest.noarch.rpm"
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="RESTORE_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi
    scp ./${target_ncn}-ceph.tgz $target_ncn:/
    ssh ${target_ncn} 'cd /; tar -xvf ./$(hostname)-ceph.tgz; rm /$(hostname)-ceph.tgz'
    ssh ${target_ncn} '/srv/cray/scripts/common/pre-load-images.sh'
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="REDEPLOY_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    # sleep 30s before redeploy ceph
    sleep 30
    ## Added
    ceph cephadm get-pub-key > ~/ceph.pub
    ssh-copy-id -f -i ~/ceph.pub root@${target_ncn}
    ceph orch host add ${target_ncn}
    sleep 20
    for s in $(ceph orch ps | grep ${target_ncn} | awk '{print $1}'); do  ceph orch daemon redeploy $s; done    
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CEPH_IMAGE_UPGRADE_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${target_ncn}"
        ssh_keys_done=1
    fi

    if [[ ${target_ncn} =~ ncn-s00[1-3] ]]; then
        scp /etc/kubernetes/admin.conf ${target_ncn}:/etc/kubernetes
    fi

    ssh ${target_ncn} '/usr/share/doc/csm/upgrade/1.2/scripts/ceph/ceph-services-stage2.sh'
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

{
. /usr/share/doc/csm/upgrade/1.2/scripts/ceph/lib/ceph-health.sh
wait_for_health_ok ${target_ncn}

# Wait for rgw to start before executing goss tests
target_ncn=ncn-s001
rgw_counter=0
until [[ $(ceph orch ps --daemon_type rgw ${target_ncn} --format json-pretty|jq -r '.[].status_desc') == "running" ]]
do
  sleep 30
  let rgw_counter+=1
  if rgw_counter -gt 10
  then
    exit 1
  fi
done
} >> ${LOG_FILE} 2>&1

if [[ ${target_ncn} == "ncn-s001" ]]; then
    state_name="POST_CEPH_IMAGE_UPGRADE_BUCKETS"
    state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."
        {
        if [[ $ssh_keys_done == "0" ]]; then
            ssh_keygen_keyscan "${target_ncn}"
            ssh_keys_done=1
        fi
        scp /usr/share/doc/csm/upgrade/1.2/scripts/ceph/create_rgw_buckets.sh $target_ncn:/tmp
        ssh ${target_ncn} '/tmp/create_rgw_buckets.sh'
        } >> ${LOG_FILE} 2>&1
        record_state "${state_name}" ${target_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF

if [[ $ssh_keys_done == "0" ]]; then
    ssh_keygen_keyscan "${target_ncn}"
    ssh_keys_done=1
fi
ssh $target_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate' 

move_state_file ${target_ncn}

ok_report
