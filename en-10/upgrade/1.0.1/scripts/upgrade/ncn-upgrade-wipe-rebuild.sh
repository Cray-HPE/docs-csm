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

echo " ****** DATA LOSS ON ${upgrade_ncn} - FRESH OS INSTALL UPON REBOOT ******"
echo " ****** BACKUP DATA ON ${upgrade_ncn} TO USB OR OTHER SAFE LOCATION ******"
echo " ****** DATA MANAGED BY K8S/CEPH WILL BE BACKED UP/RESTORED AUTOMATICALLY ******"
read -p "Read and act on above steps. Press Enter key to continue ..."
# Record this state locally instead of using is_state_recorded(),
# because it does not hurt to re-do the ssh keys, and it is the
# kind of thing which may need to be re-done in case of problems.
ssh_keys_done=0

state_name="CSI_HANDOFF_BSS_UPDATE_PARAM"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    if [[ $upgrade_ncn == ncn-s* ]];then
        csi handoff bss-update-param \
        --set metal.server=http://rgw-vip.nmn/ncn-images/ceph/${CEPH_VERSION} \
        --set rd.live.squashimg=filesystem.squashfs \
        --set metal.no-wipe=1 \
        --kernel s3://ncn-images/ceph/${CEPH_VERSION}/kernel \
        --initrd s3://ncn-images/ceph/${CEPH_VERSION}/initrd \
        --limit $UPGRADE_XNAME
     else
        csi handoff bss-update-param \
        --set metal.server=http://rgw-vip.nmn/ncn-images/k8s/${KUBERNETES_VERSION} \
        --set rd.live.squashimg=filesystem.squashfs \
        --set metal.no-wipe=0 \
        --kernel s3://ncn-images/k8s/${KUBERNETES_VERSION}/kernel \
        --initrd s3://ncn-images/k8s/${KUBERNETES_VERSION}/initrd \
        --limit $UPGRADE_XNAME
     fi

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WIPE_NODE_DISK"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    if [[ $upgrade_ncn == ncn-s* ]]; then
    cat <<'EOF' > wipe_disk.sh
    set -e
    for d in $(lsblk | grep -B2 -F md1 | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
EOF
    elif [[ $upgrade_ncn == ncn-m* ]]; then
    cat <<'EOF' > wipe_disk.sh
    usb_device=$(lsblk -b -l -o TRAN,PATH | grep usb)
    usb_rc=$?
    set -e
    if [[ "$usb_rc" -eq 0 ]]; then
      usb_device_path=$(echo $usb_device | awk '{print $2}')
      if blkid -p $usb_device_path; then
        have_mnt=0
        for mnt_point in /mnt/rootfs /mnt/sqfs /mnt/livecd /mnt/pitdata; do
          if mountpoint $mnt_point; then
            have_mnt=1
            umount $mnt_point
          fi
        done
        if [ "$have_mnt" -eq 1 ]; then
          eject $usb_device_path
        fi
      fi
    fi
    umount /var/lib/etcd /var/lib/sdu || true
    for md in /dev/md/*; do mdadm -S $md || echo nope ; done
    vgremove -f --select 'vg_name=~metal*' || true
    pvremove /dev/md124 || true
    wipefs --all --force /dev/sd* /dev/disk/by-label/* || true
    sgdisk --zap-all /dev/sd*
EOF
    else
    cat <<'EOF' > wipe_disk.sh
    lsblk | grep -q /var/lib/sdu
    sdu_rc=$?
    vgs | grep -q metal
    vgs_rc=$?
    set -e
    systemctl disable kubelet.service || true
    systemctl stop kubelet.service || true
    systemctl disable containerd.service || true
    systemctl stop containerd.service || true
    umount /var/lib/containerd /var/lib/kubelet || true
    if [[ "$sdu_rc" -eq 0 ]]; then
      umount /var/lib/sdu || true
    fi
    for md in /dev/md/*; do mdadm -S $md || echo nope ; done
    if [[ "$vgs_rc" -eq 0 ]]; then
      vgremove -f --select 'vg_name=~metal*' || true
      pvremove /dev/md124 || true
    fi
    wipefs --all --force /dev/sd* /dev/disk/by-label/* || true
    sgdisk --zap-all /dev/sd*
EOF
    fi
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
IPMI_USERNAME=$(kubectl exec -it -n vault -c vault cray-vault-1 -- sh -c "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | jq -r '.data.Username')
export IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault cray-vault-1 -- sh -c "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | jq -r '.data.Password')
# during worker upgrade, one vault pod might be offline, so we just try another one
if [[ -z ${IPMI_USERNAME} ]]; then
    IPMI_USERNAME=$(kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | jq -r '.data.Username')
    export IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; vault kv get -format=json secret/hms-creds/$UPGRADE_MGMT_XNAME" | jq -r '.data.Password')
fi

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

echo
echo " ************ IMPORTANT NOTE ************"
echo " ****** IF ANY MANUAL INTERVENTION IS REQUIRED HERE ******"
echo " ****** STOP CURRENT SCRIPT FIRST ******"
echo

state_name="WAIT_FOR_NCN_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
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
            ssh "${upgrade_ncn}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'grep Cloud-init /var/log/messages | grep -q finished' &> /dev/null && break
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

if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
    state_name="RESTORE_M001_NET_CONFIG"
    state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."

        if [[ $ssh_keys_done == "0" ]]; then
            ssh_keygen_keyscan "${upgrade_ncn}"
            ssh_keys_done=1
        fi
        scp ifcfg-lan0 root@ncn-m001:/etc/sysconfig/network/
        ssh root@ncn-m001 'wicked ifreload lan0'
        record_state "${state_name}" ${upgrade_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi

if [[ ${upgrade_ncn} != ncn-s* ]]; then
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
fi

if [[ ${upgrade_ncn} != ncn-s* ]]; then
    state_name="NTP_SETUP"
    state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."

        if [[ $ssh_keys_done == "0" ]]; then
            ssh_keygen_keyscan "${upgrade_ncn}"
            ssh_keys_done=1
        fi

        echo "Ensuring cloud-init on $upgrade_ncn is healthy"
        if ! ssh $upgrade_ncn 'cloud-init query -a > /dev/null 2>&1' ; then
            echo "cloud-init on $upgrade_ncn is not healthy -- re-running 'cloud-init init' to repair cached data"
            ssh $upgrade_ncn 'cloud-init init > /dev/null 2>&1'
        fi
        
        # only tinker with ntp if we are coming from 0.9.x
        if [[ "$CSM1_EXISTS" == "false" ]]; then
          ssh $upgrade_ncn '/srv/cray/scripts/metal/ntp-upgrade-config.sh'
        fi

        record_state "${state_name}" ${upgrade_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi
