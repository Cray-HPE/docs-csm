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
. ${basedir}/upgrade-state.sh
trap 'err_report' ERR
target_ncn=$1

. ${basedir}/ncn-common.sh ${target_ncn}

state_name="CSI_VALIDATE_BSS_NTP"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" && $2 != "--rebuild" ]]; then
    echo "====> ${state_name} ..."
    {

    if ! cray bss bootparameters list --hosts $TARGET_XNAME --format json | jq '.[] |."cloud-init"."user-data".ntp' | grep -q '/etc/chrony.d/cray.conf'; then
        echo "${target_ncn} is missing NTP data in BSS. Please see the procedure which can be found in the 'Known Issues and Bugs' section titled 'Fix BSS Metadata' on the 'Configure NTP on NCNs' page of the CSM documentation."
        exit 1
    else
        record_state "${state_name}" ${target_ncn}
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi

state_name="ELIMINATE_NTP_CLOCK_SKEW"
state_recorded=$(is_state_recorded "${state_name}" "${target_ncn}")
if [[ $state_recorded == "0" && $2 != "--rebuild" ]]; then
    echo "====> ${state_name} ..."
    {
    # ensure the correct template is in place and any problematic files are found
    if ! /srv/cray/scripts/common/chrony/csm_ntp.py; then
        echo "${target_ncn} csm_ntp failed"
        exit 1
    else
        record_state "${state_name}" "${target_ncn}"
    fi

    # if the node is not in sync after a minute, fail
    if ! chronyc waitsync 6 0.5 0.5 10; then
        echo "${target_ncn} the clock is not in sync.  Wait a bit more or try again."
        exit 1
    else
        record_state "${state_name}" "${target_ncn}"
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi

state_name="WIPE_NODE_DISK"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ -z $NONINTERACTIVE ]]; then
        echo " ****** DATA LOSS ON ${target_ncn} - FRESH OS INSTALL UPON REBOOT ******"  >/dev/tty
        echo " ****** BACKUP DATA ON ${target_ncn} TO USB OR OTHER SAFE LOCATION ******" >/dev/tty
        echo " ****** DATA MANAGED BY K8S/CEPH WILL BE BACKED UP/RESTORED AUTOMATICALLY ******" >/dev/tty
        echo "Read and act on above steps. Press Enter key to continue ..." >/dev/tty
        read
    fi

    if [[ $target_ncn == ncn-s* ]]; then
    cat <<'EOF' > wipe_disk.sh
    set -e
    for d in $(lsblk | grep -B2 -F md1 | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
EOF
    elif [[ $target_ncn == ncn-m* ]]; then
    cat <<'EOF' > wipe_disk.sh
    usb_device_path=$(lsblk -b -l -o TRAN,PATH | awk /usb/'{print $2}')
    usb_rc=$?
    set -e
    if [[ "$usb_rc" -eq 0 ]]; then
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
    # Select the devices we care about; RAID, SATA, and NVME devices/handles (but *NOT* USB)
    disk_list=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(raid|sata|nvme|sas)' | sort -u | awk '{print "/dev/"$2}' | tr '\n' ' ')
    for disk in $disk_list; do
        wipefs --all --force wipefs --all --force "$disk" || true
        sgdisk --zap-all "$disk"
    done
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
    scp wipe_disk.sh $target_ncn:/tmp/wipe_disk.sh
    ssh $target_ncn '/tmp/wipe_disk.sh'
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi
{
    target_ncn_mgmt_host="${target_ncn}-mgmt"
    if [[ ${target_ncn} == "ncn-m001" ]]; then
        target_ncn_mgmt_host=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ncn-m001 "ipmitool lan print | grep 'IP Address' | grep -v 'Source'"  | awk -F ": " '{print $2}')
    fi
    echo "mgmt IP/Host: ${target_ncn_mgmt_host}"

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
            vault kv get -format=json secret/hms-creds/$TARGET_MGMT_XNAME" | 
            jq -r '.data.Username')
        # If we are not able to get the username, no need to try and get the password.
        [[ -n ${IPMI_USERNAME} ]] || continue
        export IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault ${VAULT_POD} -- sh -c \
            "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo $VAULT_TOKEN`; \
            vault kv get -format=json secret/hms-creds/$TARGET_MGMT_XNAME" | 
            jq -r '.data.Password')
        break
    done
    # Make sure we found a pod that worked
    [[ -n ${IPMI_USERNAME} ]]
} >> ${LOG_FILE} 2>&1
state_name="SET_PXE_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
        ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis bootdev pxe options=efiboot
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

bootscript_last_epoch=$(curl -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history?name=$TARGET_XNAME" \
            | jq '.[]| select(.endpoint=="bootscript")|.last_epoch' 2> /dev/null)

state_name="POWER_CYCLE_NCN"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
        # power cycle node
        ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power off
        sleep 20
        ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power status
        ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power on
    } >> ${LOG_FILE} 2>&1
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WAIT_FOR_NCN_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    # inline tips for watching boot logs
    cat <<EOF
TIPS:
    operations/conman/ConMan.md has instructions for watching boot/console output of a node
EOF
    # wait for boot
    counter=0
    printf "%s" "waiting for boot: $target_ncn ..."
    while true
    do
        {
        set +e
        while true
        do
            tmp_bootscript_last_epoch=$(curl -s -k -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${TOKEN}" \
                "https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history?name=$TARGET_XNAME" \
                | jq '.[]| select(.endpoint=="bootscript")|.last_epoch' 2> /dev/null)
            if [[ $? -eq 0 ]]; then
                break
            fi
        done
        set -e
        } >> ${LOG_FILE} 2>&1
        if [[ $tmp_bootscript_last_epoch -ne $bootscript_last_epoch ]]; then
            echo "bootscript fetched"
            break
        fi

        printf "%c" "."
        counter=$((counter+1))
        if [ $counter -gt 300 ]; then
            counter=0
            ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power cycle
            echo "Boot timeout, power cycle again"
        fi
        sleep 2
    done
    printf "\n%s\n" "$target_ncn is booted and online"
    
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

state_name="WAIT_FOR_CLOUD_INIT"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    sleep 60
    # wait for cloud-init
    # ssh commands are expected to fail for a while, so we temporarily disable set -e
    set +e
    printf "%s" "waiting for cloud-init: $target_ncn ..."
    while true ; do
        if ssh_keygen_keyscan "${target_ncn}" &> /dev/null ; then
            ssh_keys_done=1
            ssh "${target_ncn}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'cat /var/log/cloud-init-output.log | grep "The system is finally up"' &> /dev/null && break
        fi
        printf "%c" "."
        sleep 20
    done
    # Restore set -e
    set -e
    printf "\n%s\n"  "$target_ncn finished cloud-init"
    
    record_state "${state_name}" ${target_ncn}
else
    echo "====> ${state_name} has been completed"
fi

if [[ $target_ncn != ncn-s* ]]; then
    {
        wait_for_kubernetes $target_ncn
    } >> ${LOG_FILE} 2>&1
fi 

{
    set +e
    while true ; do    
        csi handoff bss-update-param --set metal.no-wipe=1 --limit $TARGET_XNAME
        if [[ $? -eq 0 ]]; then
            break
        else
            sleep 5
        fi
    done
    set -e
} >> ${LOG_FILE} 2>&1

if [[ ${target_ncn} == "ncn-m001" ]]; then
    state_name="RESTORE_M001_NET_CONFIG"
    state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."
        {
            if [[ $ssh_keys_done == "0" ]]; then
                ssh_keygen_keyscan "${target_ncn}"
                ssh_keys_done=1
            fi
            scp ifcfg-lan0 root@ncn-m001:/etc/sysconfig/network/
            ssh root@ncn-m001 'wicked ifreload lan0'
        } >> ${LOG_FILE} 2>&1
        record_state "${state_name}" ${target_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi

if [[ ${target_ncn} != ncn-s* ]]; then
    state_name="CRAY_INIT"
    state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
    if [[ $state_recorded == "0" ]]; then
        echo "====> ${state_name} ..."
        {
        if [[ $ssh_keys_done == "0" ]]; then
            ssh_keygen_keyscan "${target_ncn}"
            ssh_keys_done=1
        fi
        ssh ${TARGET_NCN} 'cray init --no-auth --overwrite --hostname https://api-gw-service-nmn.local'
        } >> ${LOG_FILE} 2>&1
        record_state "${state_name}" ${target_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi
