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

# Record this state locally instead of using is_state_recorded(),
# because it does not hurt to re-do the ssh keys, and it is the
# kind of thing which may need to be re-done in case of problems.
ssh_keys_done=0

state_name="CEPH_NODES_SET_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    csi handoff bss-update-cloud-init --set meta-data.wipe-ceph-osds=no --limit Global

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="BACKUP_CEPH_DATA"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    ssh ${upgrade_ncn} 'systemctl stop ceph.target;sleep 30;tar -zcvf /tmp/$(hostname)-ceph.tgz /var/lib/ceph /var/lib/containers /etc/ceph;systemctl start ceph.target'
    scp ${upgrade_ncn}:/tmp/${upgrade_ncn}-ceph.tgz .

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="CSI_HANDOFF_BSS_UPDATE_PARAM"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    csi handoff bss-update-param \
    --set metal.server=http://rgw-vip.nmn/ncn-images/ceph/${CEPH_VERSION} \
    --set rd.live.squashimg=filesystem.squashfs \
    --set metal.no-wipe=1 \
    --kernel s3://ncn-images/ceph/${CEPH_VERSION}/kernel \
    --initrd s3://ncn-images/ceph/${CEPH_VERSION}/initrd \
    --limit $UPGRADE_XNAME

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WIPE_NODE_DISK"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    cat <<'EOF' > wipe_disk.sh
    set -e
    for d in $(lsblk | grep -B2 -F md1 | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
EOF
    chmod +x wipe_disk.sh
    scp wipe_disk.sh $upgrade_ncn:/tmp/wipe_disk.sh
    ssh $upgrade_ncn '/tmp/wipe_disk.sh'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

upgrade_ncn_mgmt_host="${upgrade_ncn}-mgmt"
if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
    upgrade_ncn_mgmt_host=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ncn-m001 "ipmitool lan print | grep 'IP Address' | grep -v 'Source'"  | awk -F ": " '{print $2}')
fi
echo "mgmt IP/Host: ${upgrade_ncn_mgmt_host}"

# retrieve IPMI username/password from vault
VAULT_TOKEN=$(kubectl get secrets cray-vault-unseal-keys -n vault -o jsonpath={.data.vault-root} | base64 -d)
# Make sure we got a vault token
[[ -n ${VAULT_TOKEN} ]]

# During worker upgrades, one vault pod might be offline, so we look for one that works.
# List names of all Running vault pods, grep for just the cray-vault-# pods, and try them in
# turn until one of them has the IPMI credentials.
IPMI_USERNAME=""
IPMI_PASSWORD=""
for VAULT_POD in $(kubectl get pods -n vault --field-selector status.phase=Running --no-headers \
                    -o custom-columns=:.metadata.name | grep -E "^cray-vault-(0|[1-9][0-9]*)$") ; do
    IPMI_USERNAME=$(kubectl exec -it -n vault -c vault ${VAULT_POD} -- sh -c \
        "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; \
        vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | 
        jq -r '.data.Username')
    # If we are not able to get the username, no need to try and get the password.
    [[ -n ${IPMI_USERNAME} ]] || continue
    export IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault ${VAULT_POD} -- sh -c \
        "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; \
        vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | 
        jq -r '.data.Password')
    break
done
# Make sure we found a pod that worked
[[ -n ${IPMI_USERNAME} ]]

state_name="SET_PXE_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis bootdev pxe options=efiboot

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="POWER_CYCLE_NCN"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    # power cycle node
    ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis power off
    sleep 20
    ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis power status
    ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis power on

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WAIT_FOR_NCN_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    # inline tips for watching boot logs
    cat <<EOF
TIPS:
    operations/conman/ConMan.md has instructions for watching boot/console output of a node
EOF
    # wait for boot
    counter=0
    printf "%s" "waiting for boot: $upgrade_ncn ..."
    while ! ping -c 1 -n -w 1 $upgrade_ncn &> /dev/null
    do
        printf "%c" "."
        counter=$((counter+1))
        if [ $counter -gt 30 ]; then
            counter=0
            ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis power cycle
            echo "Boot timeout, power cycle again"
        fi
        sleep 20
    done
    printf "\n%s\n" "$upgrade_ncn is booted and online"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WAIT_FOR_CLOUD_INIT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    sleep 60
    # wait for cloud-init
    # ssh commands are expected to fail for a while, so we temporarily disable set -e
    set +e
    printf "%s" "waiting for cloud-init: $upgrade_ncn ..."
    while true ; do
        if ssh_keygen_keyscan "${upgrade_ncn}" &> /dev/null ; then
            ssh_keys_done=1
            ssh "${upgrade_ncn}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'cat /var/log/cloud-init-output.log | grep "The system is finally up"' &> /dev/null && break
        fi
        printf "%c" "."
        sleep 20
    done
    # Restore set -e
    set -e
    printf "\n%s\n"  "$upgrade_ncn finished cloud-init"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="SET_BSS_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    csi handoff bss-update-param --set metal.no-wipe=1 --limit $UPGRADE_XNAME

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi


state_name="CRAY_INIT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    ssh ${UPGRADE_NCN} 'cray init --no-auth --overwrite --hostname https://api-gw-service-nmn.local'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
    fi

state_name="INSTALL_UPGRADE_SCRIPT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="RESTORE_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi
    scp ./${upgrade_ncn}-ceph.tgz $upgrade_ncn:/
    ssh ${upgrade_ncn} 'cd /; tar -xvf ./$(hostname)-ceph.tgz; rm /$(hostname)-ceph.tgz'
    ssh ${upgrade_ncn} '/srv/cray/scripts/common/pre-load-images.sh'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

# sleep 30s before redeploy ceph
sleep 30

state_name="REDEPLOY_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ceph cephadm get-pub-key > ~/ceph.pub
    ssh-copy-id -f -i ~/ceph.pub root@${upgrade_ncn}
    ceph orch host add ${upgrade_ncn}
    sleep 20
    ceph orch daemon redeploy mon.${upgrade_ncn}
    sleep 20
    for s in $(ceph orch ps | grep ${upgrade_ncn} | awk '{print $1}'); do  ceph orch daemon start $s; done

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="POST_CEPH_IMAGE_UPGRADE_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    if [[ $ssh_keys_done == "0" ]]; then
        ssh_keygen_keyscan "${upgrade_ncn}"
        ssh_keys_done=1
    fi

    if [[ ${upgrade_ncn} =~ ncn-s00[1-3] ]]; then
        scp /etc/kubernetes/admin.conf ${upgrade_ncn}:/etc/kubernetes
    fi

    ssh ${upgrade_ncn} '/usr/share/doc/csm/upgrade/1.2/scripts/ceph/ceph-services-stage2.sh'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

. /usr/share/doc/csm/upgrade/1.2/scripts/ceph/lib/ceph-health.sh
wait_for_health_ok

if [[ ${upgrade_ncn} == "ncn-s001" ]]; then
    state_name="POST_CEPH_IMAGE_UPGRADE_BUCKETS"
    state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."

        if [[ $ssh_keys_done == "0" ]]; then
            ssh_keygen_keyscan "${upgrade_ncn}"
            ssh_keys_done=1
        fi
        scp /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/create_rgw_buckets.sh $upgrade_ncn:/tmp
        ssh ${upgrade_ncn} '/tmp/create_rgw_buckets.sh'

        record_state "${state_name}" ${upgrade_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi

cat <<EOF

NOTE:
    If below test failed, try to fix it based on test output. Then run current script again
EOF

if [[ $ssh_keys_done == "0" ]]; then
    ssh_keygen_keyscan "${upgrade_ncn}"
    ssh_keys_done=1
fi
ssh $upgrade_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

ok_report
