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

if [[ ${upgrade_ncn} == "ncn-s001" ]]; then
   state_name="S001_SET_CLOUD_INIT"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."

      VERBOSE=1 csi handoff bss-update-cloud-init --set user-data.runcmd=[\"/srv/cray/scripts/metal/install-bootloader.sh\",\"/srv/cray/scripts/metal/set-host-records.sh\",\"/srv/cray/scripts/metal/set-dhcp-to-static.sh\",\"/srv/cray/scripts/metal/set-dns-config.sh\",\"/srv/cray/scripts/metal/ntp-upgrade-config.sh\",\"/srv/cray/scripts/metal/set-bmc-bbs.sh\",\"/srv/cray/scripts/metal/disable-cloud-init.sh\",\"/srv/cray/scripts/common/update_ca_certs.py\",\"/srv/cray/scripts/metal/install-rpms.sh\"] --limit $UPGRADE_XNAME

      record_state "${state_name}" ${upgrade_ncn}
   else
      echo "====> ${state_name} has been completed"
   fi
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

${BASEDIR}/ncn-upgrade-wipe-rebuild.sh $upgrade_ncn

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
    for s in $(ceph orch ps | grep ${upgrade_ncn} | awk '{print $1}'); do  ceph orch daemon redeploy $s; done

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
    ssh ${upgrade_ncn} '/usr/share/doc/csm/upgrade/1.0.1/scripts/ceph/ceph-services-stage2.sh'
    ssh ${upgrade_ncn} '/srv/cray/scripts/metal/ntp-upgrade-config.sh'

    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi

. /usr/share/doc/csm/upgrade/1.0.1/scripts/ceph/lib/ceph-health.sh
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
        scp /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/create_rgw_buckets.sh $upgrade_ncn:/tmp
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
