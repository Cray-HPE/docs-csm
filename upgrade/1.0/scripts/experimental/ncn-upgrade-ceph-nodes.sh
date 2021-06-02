#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
. ./upgrade-state.sh

upgrade_ncn=$1

. ./ncn-upgrade-common.sh ${upgrade_ncn}

state_name="CEPH_NODES_SET_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    
    csi handoff bss-update-cloud-init --set meta-data.wipe-ceph-osds=no --limit Global

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo "${state_name} has beed completed"
fi

if [[ ${upgrade_ncn} == "ncn-s001" ]]; then
   state_name="S001_SET_CLOUD_INIT"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "${state_name} ..."
      
      VERBOSE=1 csi handoff bss-update-cloud-init --set user-data.runcmd=[\"/srv/cray/scripts/metal/install-bootloader.sh\",\"/srv/cray/scripts/metal/set-host-records.sh\",\"/srv/cray/scripts/metal/set-dhcp-to-static.sh\",\"/srv/cray/scripts/metal/set-dns-config.sh\",\"/srv/cray/scripts/metal/ntp-upgrade-config.sh\",\"/srv/cray/scripts/metal/set-bmc-bbs.sh\",\"/srv/cray/scripts/metal/disable-cloud-init.sh\",\"/srv/cray/scripts/common/update_ca_certs.py\"] --limit $UPGRADE_XNAME

      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo "${state_name} has beed completed"
   fi
fi

state_name="BACKUP_CEPH_DATA"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    
    ssh ${upgrade_ncn} 'systemctl stop ceph.target;sleep 30;tar -zcvf /tmp/$(hostname)-ceph.tgz /var/lib/ceph /var/lib/containers /etc/ceph;systemctl start ceph.target'
    scp ${upgrade_ncn}:/tmp/${upgrade_ncn}-ceph.tgz .

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo "${state_name} has beed completed"
fi

./ncn-upgrade-k8s-nodes.sh $upgrade_ncn

state_name="INSTALL_UPGRADE_SCRIPT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."
    
    ssh-keygen -R ${upgrade_ncn} -f /root/.ssh/known_hosts
    ssh-keyscan -H ${upgrade_ncn} >> ~/.ssh/known_hosts
    ssh ${upgrade_ncn} 'rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm'

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo "${state_name} has beed completed"
fi

state_name="RESTORE_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."

    scp ./${upgrade_ncn}-ceph.tgz $upgrade_ncn:/
    ssh ${upgrade_ncn} 'cd /; tar -xvf ./$(hostname)-ceph.tgz; rm /$(hostname)-ceph.tgz'

    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo "${state_name} has beed completed"
fi

cat <<EOF
Steps 3-8 are not automated yet

watch "ceph orch ps | grep ${upgrade_ncn}; echo ''; ceph osd tree"

ceph cephadm get-pub-key > ~/ceph.pub

ssh-copy-id -f -i ~/ceph.pub root@${upgrade_ncn}

ceph orch host add ${upgrade_ncn}

ceph orch daemon redeploy mon.${upgrade_ncn}

for s in $(ceph orch ps | grep ${upgrade_ncn} | awk '{print $1}'); do  ceph orch daemon start $s; done

EOF
read -p "Read above steps and press any key to continue ..."

state_name="POST_CEPH_IMAGE_UPGRADE_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "${state_name} ..."

    ssh ${upgrade_ncn} '/usr/share/doc/csm/upgrade/1.0/scripts/ceph/ceph-services-stage2.sh'
    ssh ${upgrade_ncn} '/srv/cray/scripts/metal/ntp-upgrade-config.sh'


    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo "${state_name} has beed completed"
fi

ssh $upgrade_ncn 'GOSS_BASE=/opt/cray/tests/install goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'