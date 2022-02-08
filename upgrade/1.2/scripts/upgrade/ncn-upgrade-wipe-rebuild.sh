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

if [[ -z $NONINTERACTIVE ]]; then
    echo " ****** DATA LOSS ON ${upgrade_ncn} - FRESH OS INSTALL UPON REBOOT ******"
    echo " ****** BACKUP DATA ON ${upgrade_ncn} TO USB OR OTHER SAFE LOCATION ******"
    echo " ****** DATA MANAGED BY K8S/CEPH WILL BE BACKED UP/RESTORED AUTOMATICALLY ******"
    read -p "Read and act on above steps. Press Enter key to continue ..."
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
    
    csi handoff bss-update-param --set metal.no-wipe=0 --limit $UPGRADE_XNAME
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

bootscript_last_epoch=$(curl -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history?name=$UPGRADE_XNAME" \
            | jq '.[]| select(.endpoint=="bootscript")|.last_epoch')

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
    while true
    do
        tmp_bootscript_last_epoch=$(curl -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history?name=$UPGRADE_XNAME" \
            | jq '.[]| select(.endpoint=="bootscript")|.last_epoch')
        if [[ $tmp_bootscript_last_epoch -ne $bootscript_last_epoch ]]; then
            echo "bootscript fetched"
            break
        fi

        printf "%c" "."
        counter=$((counter+1))
        if [ $counter -gt 300 ]; then
            counter=0
            ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $upgrade_ncn_mgmt_host chassis power cycle
            echo "Boot timeout, power cycle again"
        fi
        sleep 2
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

if [[ $upgrade_ncn != ncn-s* ]]; then
    wait_for_kubernetes $upgrade_ncn
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