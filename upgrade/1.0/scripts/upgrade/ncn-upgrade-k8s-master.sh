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

if [[ ${upgrade_ncn} == "ncn-m001" ]]; then
   state_name="BACKUP_M001_NET_CONFIG"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
      
      scp root@ncn-m001:/etc/sysconfig/network/ifcfg-lan0 .
      scp root@ncn-m001:/etc/sysconfig/network/ifroute-lan0 .
      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
   fi
fi

echo -e "${YELLOW}"
cat <<EOF
Open a new terminal window to the stable NCN to watch the etcd cluster status, as well as the Kubernetes node listing. This will be useful to watch the progress of the node being upgraded, so leave it up and running

watch 'etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/ca.crt  \
     --key=/etc/kubernetes/pki/etcd/ca.key \
     --endpoints=localhost:2379 member list; echo -e ""; kubectl get nodes'
EOF

read -p "Press any key to continue after above 'watch' command is running ..."
echo -e "${NOCOLOR}"

first_master_hostname=`curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | \
     jq -r '.[] | ."cloud-init"."meta-data"."first-master-hostname"'`
if [[ ${first_master_hostname} == ${upgrade_ncn} ]]; then   
   state_name="RECONFIGURE_FIRST_MASTER"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
      csi handoff bss-update-cloud-init --set meta-data.first-master-hostname=$STABLE_NCN --limit Global
      /usr/share/doc/csm/upgrade/1.0/scripts/k8s/promote-initial-master.sh
      
      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
   fi
fi

state_name="STOP_ETCD_SERVICE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    ssh $upgrade_ncn 'systemctl daemon-reload || systemctl stop etcd.service'
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

state_name="PREPARE_ETCD"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    export MEMBER_ID=$(etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/ca.crt \
     --key=/etc/kubernetes/pki/etcd/ca.key \
     --endpoints=localhost:2379 member list | \
     grep $upgrade_ncn | cut -d ',' -f1)

     etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/ca.crt \
     --key=/etc/kubernetes/pki/etcd/ca.key \
     --endpoints=localhost:2379 member remove $MEMBER_ID

     etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/ca.crt  \
      --key=/etc/kubernetes/pki/etcd/ca.key \
      --endpoints=localhost:2379 \
      member add $upgrade_ncn --peer-urls=https://$UPGRADE_IP_NMN:2380
    
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

state_name="DRAIN_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo -e "${GREEN}====> ${state_name} ... ${NOCOLOR}"
    ssh $upgrade_ncn "rpm --force -Uvh ${DOC_RPM_NEXUS_URL}"
    /usr/share/doc/csm/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $UPGRADE_NCN
    
    record_state "${state_name}" ${upgrade_ncn}
    echo
else
    echo -e "${GREEN}====> ${state_name} has beed completed ${NOCOLOR}"
fi

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

ssh $upgrade_ncn -t 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

echo -e "${YELLOW}"
cat <<EOF
If above test failed, try to fix it based on test output. Then run the test again:

ssh $upgrade_ncn 'GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate'

read -p "Press any key to continue ..."
echo -e "${NOCOLOR}"
