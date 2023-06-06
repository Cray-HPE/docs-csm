#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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
state_recorded=$(is_state_recorded "${state_name}" "$target_ncn")
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    loop_idx=0
    in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
    if [[ "$in_sync" == "no" ]]; then
        ssh "$target_ncn" chronyc makestep
        sleep 5
        in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
        # wait up to 90s for the node to be in sync
        while [[ $loop_idx -lt 18 && "$in_sync" == "no" ]]; do
            sleep 5
            in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
            loop_idx=$(( loop_idx+1 ))
        done
        if [[ "$in_sync" == "no" ]]; then
            exit 1
        else
            record_state "${state_name}" "${target_ncn}"
        fi
    else
        record_state "${state_name}" "${target_ncn}"
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi


state_name="SET rd.live.dir AND rd.live.overlay.reset"
state_recorded=$(is_state_recorded "${state_name}" "${target_ncn}")
if [[ ${state_recorded} == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ -z ${CSM_RELEASE} ]]; then
        echo 2>& "CSM_RELEASE is not set!"
        exit 1
    fi
    csi handoff bss-update-param --delete rd.live.dir --limit "${TARGET_XNAME}"
    csi handoff bss-update-param --set rd.live.dir=${CSM_RELEASE} --limit "${TARGET_XNAME}"
    csi handoff bss-update-param --delete rd.live.overlay.reset --limit "${TARGET_XNAME}"
    csi handoff bss-update-param --set rd.live.overlay.reset=1 --limit "${TARGET_XNAME}"
  } >> "${LOG_FILE}" 2>&1
    record_state "${state_name}" "${target_ncn}"
else
    echo "====> ${state_name} has been completed"
fi


state_name="SHUTDOWN_SERVICES"
state_recorded=$(is_state_recorded "${state_name}" "${target_ncn}")
if [[ ${state_recorded} == "0" ]]; then
    rm -f "${basedir}/standdown.sh"
    echo "====> ${state_name} ..."
    {
        if [[ ${target_ncn} == ncn-s* ]]; then
            cat << 'EOF' > "${basedir}/standdown.sh"
#!/bin/bash
set -ou pipefail
function wait_on_dev {
    local dev=$1
    local count=${2:-0}
    while lsof | grep -q "${dev}" ; do
        [[ ${count} == 10 ]] && echo >&2 "Waited for ${count} seconds to no avail." && return 1
        echo "Waiting on ${dev} usage to reach 0"
        count=$((count + 1))
        sleep 1
    done
    echo "Nothing is using ${dev}"
}
echo 'Removing metalvg since storage nodes do not rebuild with metal.no-wipe=0'
systemctl stop ceph.target
systemctl stop registry.container.service
wait_on_dev /etc/ceph
wait_on_dev /var/lib/ceph
wait_on_dev /var/lib/containers
umount /etc/ceph /var/lib/ceph /var/lib/containers || true
sleep 10
lvremove -f --select 'lvname=~CEPH*' || true
lvremove -f --select 'lvname=~CONTAIN' || true
vgremove -f --select 'vgname=~metalvg*' || true
wipefs --all --force /dev/mapper/metalvg*
echo 'Disabling the bootloader by removing it'
rm -rf /metal/recovery/*
echo 'Deactivating disk boot entries to force netbooting for rebuilding ... '
to_delete="$(efibootmgr | grep -P '(UEFI OS|cray)' | awk -F'[^0-9]*' '{print $0}' | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*')"
if [ "${to_delete}" ]; then
    for item in ${to_delete}; do
        efibootmgr # print before
        efibootmgr -b ${item} -B
        efibootmgr # print after
    done
fi
echo 'Setting next boot to PXE ... '
ipmitool chassis bootdev pxe options=efiboot
EOF
        elif [[ ${target_ncn} == ncn-m* ]]; then
            cat << 'EOF' > "${basedir}/standdown.sh"
#!/bin/bash
set -ou pipefail
echo 'unmounting USB(s) ... '
usb_device_path=$(lsblk -b -l -o TRAN,PATH | awk /usb/'{print $2}')
usb_rc=$?
set -e
if [[ "$usb_rc" -eq 0 ]]; then
  if blkid -p ${usb_device_path}; then
    have_mnt=0
    echo 'unmounting discovered USB mountpoints ... '
    for mnt_point in /mnt/rootfs /mnt/sqfs /mnt/livecd /mnt/pitdata; do
      if mountpoint "${mnt_point}"; then
        have_mnt=1
        umount -v "${mnt_point}"
      fi
    done
    if [[ ${have_mnt} -eq 1 ]]; then
      echo "ejecting discovered USB: [${usb_device_path}]"
      eject ${usb_device_path}
    fi
  fi
fi
umount -v /var/lib/etcd /var/lib/sdu || true

echo 'Disabling the bootloader by removing it'
rm -rf /metal/recovery/*
echo 'Deactivating disk boot entries to force netbooting for rebuilding ... '
to_delete="$(efibootmgr | grep -P '(UEFI OS|cray)' | awk -F'[^0-9]*' '{print $0}' | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*')"
if [ "${to_delete}" ]; then
    for item in ${to_delete}; do
        efibootmgr # print before
        efibootmgr -b ${item} -B
        efibootmgr # print after
    done
fi
echo 'Setting next boot to PXE ... '
ipmitool chassis bootdev pxe options=efiboot
EOF
        else
            cat << 'EOF' > "${basedir}/standdown.sh"
#!/bin/bash
set -ou pipefail
lsblk | grep -q /var/lib/sdu
sdu_rc=$?
vgs | grep -q metal
vgs_rc=$?
set -e
echo 'Disabling and stopping kubernetes and containerd daemons ... '
systemctl disable kubelet.service || true
systemctl stop kubelet.service || true
systemctl disable containerd.service || true
systemctl stop containerd.service || true
umount -v /var/lib/containerd /var/lib/kubelet || true
if [[ ${sdu_rc} -eq 0 ]]; then
  umount -v /var/lib/sdu || true
fi

echo 'Disabling the bootloader by removing it'
rm -rf /metal/recovery/*
echo 'Deactivating disk boot entries to force netbooting for rebuilding ... '
to_delete="$(efibootmgr | grep -P '(UEFI OS|cray)' | awk -F'[^0-9]*' '{print $0}' | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*')"
if [ "${to_delete}" ]; then
    for item in ${to_delete}; do
        efibootmgr # print before
        efibootmgr -b ${item} -B
        efibootmgr # print after
    done
fi
echo 'Setting next boot to PXE ... '
ipmitool chassis bootdev pxe options=efiboot
EOF
        fi
        if [[ -f ${basedir}/standdown.sh ]]; then
            chmod +x "${basedir}/standdown.sh"
            scp "${basedir}/standdown.sh" "${target_ncn}:/tmp/standdown.sh"
            ssh "${target_ncn}" '/tmp/standdown.sh'
        else
            echo >&2 "${target_ncn} has nothing to standdown! This is not expected."
            exit 1
        fi

    } >> "${LOG_FILE}" 2>&1
    record_state "${state_name}" "${target_ncn}"
else
    echo "====> ${state_name} has been completed"
fi

bootscript_last_epoch=$(curl -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/endpoint-history?name=$TARGET_XNAME" \
            | jq '.[]| select(.endpoint=="bootscript")|.last_epoch' 2> /dev/null)

state_name="POWER_CYCLE_NCN"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
if [[ ${state_recorded} == "0" ]]; then
    echo "====> ${state_name} ..."
    {
        if [[ ${target_ncn} == ncn-m* ]]; then
            # try to power cycle master node via ssh
            ssh "${target_ncn}" 'nohup sleep 5;ipmitool chassis power cycle >> /root/power_cycle.log 2>&1 &'
            sleep 5
            # wait for 30s to confirm the node is down
            # retry until it is actually down
            counter=0
            printf "%s" "waiting for poweroff: ${target_ncn} ..."
            while ping -c 1 -n -w 1 "${target_ncn}" &> /dev/null
            do
                printf "%c" "."
                counter=$((counter+1))
                if [ $counter -gt 30 ]; then
                    counter=0
                    ssh "${target_ncn}" 'nohup ipmitool chassis power cycle >> /root/power_cycle.log 2>&1 &'
                    echo "power off timeout, power cycle again"
                fi
                sleep 1
            done
        else
            target_ncn_mgmt_host="${target_ncn}-mgmt"
            echo "mgmt IP/Host: ${target_ncn_mgmt_host}"

            # retrieve IPMI username/password from vault
            VAULT_TOKEN=$(kubectl get secrets cray-vault-unseal-keys -n vault -o jsonpath='{.data.vault-root}' | base64 -d)
            # Make sure we got a vault token
            [[ -n ${VAULT_TOKEN} ]]

            # During worker upgrades, one vault pod might be offline, so we look for one that works.
            # List names of all Running vault pods, grep for just the cray-vault-# pods, and try them in
            # turn until one of them has the IPMI credentials.
            IPMI_USERNAME=""
            IPMI_PASSWORD=""
            for VAULT_POD in $(kubectl get pods -n vault --field-selector status.phase=Running --no-headers \
                                -o custom-columns=:.metadata.name | grep -E "^cray-vault-(0|[1-9][0-9]*)$") ; do
                IPMI_USERNAME=$(kubectl exec -it -n vault -c vault "${VAULT_POD}" -- sh -c \
                    "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo ${VAULT_TOKEN}`; \
                    vault kv get -format=json secret/hms-creds/${TARGET_MGMT_XNAME}" | 
                    jq -r '.data.Username')
                # If we are not able to get the username, no need to try and get the password.
                [[ -n ${IPMI_USERNAME} ]] || continue
                IPMI_PASSWORD=$(kubectl exec -it -n vault -c vault "${VAULT_POD}" -- sh -c \
                    "export VAULT_ADDR=http://localhost:8200; export VAULT_TOKEN=`echo ${VAULT_TOKEN}`; \
                    vault kv get -format=json secret/hms-creds/${TARGET_MGMT_XNAME}" | 
                    jq -r '.data.Password')
                export IPMI_PASSWORD
                break
            done
            # Make sure we found a pod that worked
            [[ -n ${IPMI_USERNAME} ]]

            # power cycle node
            ipmitool -I lanplus -U "${IPMI_USERNAME}" -E -H "${target_ncn_mgmt_host}" chassis power off
            sleep 20
            ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power status
            ipmitool -I lanplus -U ${IPMI_USERNAME} -E -H $target_ncn_mgmt_host chassis power on
        fi
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
            if [[ ${target_ncn} == ncn-m* ]]; then
                echo "Boot timeout, power cycle ${target_ncn} from another node via ipmitool"
                exit 1
            fi
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


state_name="UNSET rd.live.overlay.reset AND SET metal.wipe=1"
state_recorded=$(is_state_recorded "${state_name}" "${target_ncn}")
if [[ ${state_recorded} == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ -z ${CSM_RELEASE} ]]; then
        echo 2>& "CSM_RELEASE is not set!"
        exit 1
    fi
    # Validate SLS health before calling csi handoff bss-update-*, since
    # it relies on SLS
    check_sls_health

    set +e
    while true ; do 
        csi handoff bss-update-param --set metal.no-wipe=1 --limit "${TARGET_XNAME}"
        wipe_return=$?
        csi handoff bss-update-param --delete rd.live.overlay.reset --limit "${TARGET_XNAME}"
        reset_return=$?
        if [[ ${wipe_return} -eq 0 ]] && [[ $reset_return -eq 0 ]]; then
            break
        else
            sleep 5
        fi
    done
    set -e
  } >> "${LOG_FILE}" 2>&1
    record_state "${state_name}" "${target_ncn}"
else
    echo "====> ${state_name} has been completed"
fi


state_name="FORCE_TIME_SYNC"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
TOKEN=$(curl -s -S -d grant_type=client_credentials \
                   -d client_id=admin-client \
                   -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
                   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    {
    ssh_keygen_keyscan "${target_ncn}"
    ssh_keys_done=1
    ssh "$target_ncn" "TOKEN=$TOKEN /srv/cray/scripts/common/chrony/csm_ntp.py"
    loop_idx=0
    in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
    if [[ "$in_sync" == "no" ]]; then
        ssh "$target_ncn" chronyc makestep
        sleep 5
        in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
        # wait up to 90s for the node to be in sync
        while [[ $loop_idx -lt 18 && "$in_sync" == "no" ]]; do
            sleep 5
            in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
            loop_idx=$(( loop_idx+1 ))
        done
        if [[ "$in_sync" == "yes" ]]; then
            record_state "${state_name}" "${target_ncn}"
        fi
        # else wait until the end of the script to fail
    else
        record_state "${state_name}" "${target_ncn}"
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi


{
    # Validate SLS health before calling csi handoff bss-update-*, since
    # it relies on SLS
    check_sls_health

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
        ssh ${TARGET_NCN} 'cray init --no-auth --overwrite --hostname https://api-gw-service-nmn.local --tenant ""'
        } >> ${LOG_FILE} 2>&1
        record_state "${state_name}" ${target_ncn}
    else
        echo "====> ${state_name} has been completed"
    fi
fi

if [[ "$in_sync" == "no" ]]; then
    echo "The clock for ${target_ncn} is not in sync. Please verify $target_ncn:/etc/chrony.d/cray.conf"
    echo "contains a server that is reachable. See also: chronyc sources -v"
    exit 1
fi
