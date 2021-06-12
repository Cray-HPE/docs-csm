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

state_name="CEPH_NODES_SET_NO_WIPE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    csi handoff bss-update-cloud-init --set meta-data.wipe-ceph-osds=no --limit Global

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has beed completed"
fi

if [[ ${upgrade_ncn} == "ncn-s001" ]]; then
   state_name="S001_SET_CLOUD_INIT"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      
      VERBOSE=1 csi handoff bss-update-cloud-init --set user-data.runcmd=[\"/srv/cray/scripts/metal/install-bootloader.sh\",\"/srv/cray/scripts/metal/set-host-records.sh\",\"/srv/cray/scripts/metal/set-dhcp-to-static.sh\",\"/srv/cray/scripts/metal/set-dns-config.sh\",\"/srv/cray/scripts/metal/ntp-upgrade-config.sh\",\"/srv/cray/scripts/metal/set-bmc-bbs.sh\",\"/srv/cray/scripts/metal/disable-cloud-init.sh\",\"/srv/cray/scripts/common/update_ca_certs.py\"] --limit $UPGRADE_XNAME

      record_state "${state_name}" ${upgrade_ncn}
   else
      echo "====> ${state_name} has beed completed"
   fi
fi

state_name="BACKUP_CEPH_DATA"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    ssh ${upgrade_ncn} 'systemctl stop ceph.target;sleep 30;tar -zcvf /tmp/$(hostname)-ceph.tgz /var/lib/ceph /var/lib/containers /etc/ceph;systemctl start ceph.target'
    scp ${upgrade_ncn}:/tmp/${upgrade_ncn}-ceph.tgz .

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has beed completed"
fi

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

state_name="INSTALL_UPGRADE_SCRIPT"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    
    ssh-keygen -R ${upgrade_ncn} -f /root/.ssh/known_hosts
    ssh-keyscan -H ${upgrade_ncn} >> ~/.ssh/known_hosts
    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has beed completed"
fi

state_name="RESTORE_CEPH"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    scp ./${upgrade_ncn}-ceph.tgz $upgrade_ncn:/
    ssh ${upgrade_ncn} 'cd /; tar -xvf ./$(hostname)-ceph.tgz; rm /$(hostname)-ceph.tgz'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has beed completed"
fi

cat <<EOF
Open another terminal on stable ncn and run:
    watch "ceph orch ps | grep ${upgrade_ncn}; echo ''; ceph osd tree"
EOF
read -p "Read above steps and press any key to continue ..."

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
    echo "====> ${state_name} has beed completed"
fi

cat <<EOF
Run: watch "ceph -s"

- Make sure ceph health is OK
- If ceph health is HEALTH_WARN and the cause is clock skew, you can still continue and next steps will attempt to fix it for you
EOF
read -p "After ceph health is ok then press any key to continue ..."

state_name="POST_CEPH_IMAGE_UPGRADE_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."

    ssh ${upgrade_ncn} '/usr/share/doc/csm/upgrade/1.0/scripts/ceph/ceph-services-stage2.sh'
    ssh ${upgrade_ncn} '/srv/cray/scripts/metal/ntp-upgrade-config.sh'


    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has beed completed"
fi

ssh $upgrade_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

cat <<EOF
NOTE:
    If above test failed, try to fix it based on test output. Then run the test again:

    ssh $upgrade_ncn 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'
EOF
read -p "Press any key to continue ..."