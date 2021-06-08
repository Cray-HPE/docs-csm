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

state_name="CSI_HANDOFF_BSS_UPDATE_PARAM"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
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
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

echo -e "${YELLOW}"
cat <<EOF
Watch the console for the node being rebuilt by exec'ing into the conman pod and connect to the console (press &. to exit).

kubectl -n services exec -it $(kubectl get po -n services | grep conman | awk '{print $1}') -- /bin/sh -c 'conman -j $UPGRADE_XNAME'
EOF

read -p "Press any key to continue after above 'watch' command is running ..."
echo -e "${NOCOLOR}"

state_name="WIPE_NODE_DISK"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    if [[ $upgrade_ncn == ncn-s* ]]; then
    cat <<'EOF' > wipe_disk.sh
    set -e
    for d in $(lsblk | grep -B2 -F md1  | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
EOF
    elif [[ $upgrade_ncn == ncn-m* ]]; then
    cat <<'EOF' > wipe_disk.sh
    set -e
    umount /var/lib/etcd /var/lib/sdu || true
    for md in /dev/md/*; do mdadm -S $md || echo nope ; done
    vgremove -f --select 'vg_name=~metal*' || true
    pvremove /dev/md124 || true
    wipefs --all --force /dev/sd* /dev/disk/by-label/* || true
    sgdisk --zap-all /dev/sd* 
EOF
    else
    cat <<'EOF' > wipe_disk.sh
    set -e
    umount /var/lib/containerd /var/lib/kubelet /var/lib/sdu || true
    for md in /dev/md/*; do mdadm -S $md || echo nope ; done
    vgremove -f --select 'vg_name=~metal*'
    pvremove /dev/md124 || true
    wipefs --all --force /dev/sd* /dev/disk/by-label/* || true
    sgdisk --zap-all /dev/sd* 
EOF
    fi
    chmod +x wipe_disk.sh
    scp wipe_disk.sh $UPGRADE_NCN:/tmp/wipe_disk.sh
    ssh $UPGRADE_NCN '/tmp/wipe_disk.sh'
    
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

upgrade_ncn_mgmt_host="$UPGRADE_NCN-mgmt"

state_name="SET_PXE_BOOT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
        echo -e "${YELLOW}"
        read -p "mgmt IP/Host of ncn-m001:" upgrade_ncn_mgmt_host
        echo -e "${NOCOLOR}"
    fi
    ipmitool -I lanplus -U root -P initial0 -H $upgrade_ncn_mgmt_host chassis bootdev pxe options=efiboot

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

state_name="SET_BSS_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    echo -e "${YELLOW}"
    cat <<EOF
    Welcome to PXE wonderland, you may have to power cycle sometimes before it boots.

    power cycle:

        ipmitool -I lanplus -U root -P initial0 -H $upgrade_ncn_mgmt_host chassis power cycle

    NOTE: run above command in a different terminal on stable ncn to boot $UPGRADE_NCN
EOF

    read -p "Press any key to continue after a node is booted and cloud-init reached target ..."
    echo -e "${NOCOLOR}"

    csi handoff bss-update-param --set metal.no-wipe=1 --limit $UPGRADE_XNAME
    
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
   state_name="RESTORE_M001_NET_CONFIG"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
      
      ssh-keygen -R ncn-m001 -f /root/.ssh/known_hosts
      ssh-keyscan -H ncn-m001 >> ~/.ssh/known_hosts
      scp ifcfg-lan0 root@ncn-m001:/etc/sysconfig/network/ifcfg-lan0
      scp ifroute-lan0 root@ncn-m001:/etc/sysconfig/network/ifroute-lan0
      ssh root@ncn-m001 'wicked ifreload lan0'
      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
   fi
fi

if [[ ${upgrade_ncn} != ncn-s* ]]; then
   state_name="CRAY_INIT"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
      
      ssh-keygen -R $UPGRADE_NCN -f /root/.ssh/known_hosts
      ssh-keyscan -H $UPGRADE_NCN >> ~/.ssh/known_hosts
      ssh $UPGRADE_NCN 'cray init --no-auth --overwrite --hostname https://api-gw-service-nmn.local'
      
      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
   fi
fi

if [[ ${upgrade_ncn} != ncn-s* ]]; then
   state_name="NTP_SETUP"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
      
      ssh-keygen -R $UPGRADE_NCN -f /root/.ssh/known_hosts
      ssh-keyscan -H $UPGRADE_NCN >> ~/.ssh/known_hosts
      ssh $UPGRADE_NCN '/srv/cray/scripts/metal/ntp-upgrade-config.sh'
      
      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
   fi
fi