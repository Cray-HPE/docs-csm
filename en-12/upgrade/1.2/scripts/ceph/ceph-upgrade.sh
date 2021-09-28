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

###
# Part 1.  Prep work
###

export file="/etc/cray/ceph/_upgraded"
export pre_pull_images_file="/etc/cray/ceph/images_pre_pulled"
export convert_rgw_file="/etc/cray/ceph/radosgw_converted"
export upgrade_init_file="/etc/cray/ceph/upgrade_initialized"
export upgrade_mons_file="/etc/cray/ceph/mons_upgraded"
export upgrade_mgrs_file="/etc/cray/ceph/mgrs_upgraded"
export distribute_keys_file="/etc/cray/ceph/keys_distributed"
export setup_orch_file="/etc/cray/ceph/converted_to_orch"
export upgrade_osds_file="/etc/cray/ceph/osds_upgraded"
export upgrade_mds_file="/etc/cray/ceph/mds_upgraded"
export upgrade_rgws_file="/etc/cray/ceph/rgws_upgraded"
export registry="${1:-registry.local}"
num_storage_nodes=$(craysys metadata get num-storage-nodes)

if [[ $? != 0 ]]
then
  echo "Cloud init data not present. Exiting upgrade.."
  exit 1
fi

if ceph orch ps >  /dev/null 2>&1; then
  echo "Ceph as already been upgraded"
  exit 0
fi

. ./lib/ceph-health.sh
. ./lib/mark_step_complete.sh
. ./lib/k8s-scale-utils.sh
. ./lib/ceph-image-pull.sh
. ./lib/convert-radosgw.sh
. ./lib/ceph-upgrade-init.sh
. ./lib/ceph-upgrade-mons.sh
. ./lib/ceph-upgrade-mgrs.sh
. ./lib/cephadm-keys.sh
. ./lib/ceph-orch-tasks.sh
. ./lib/ceph-upgrade-osds.sh
. ./lib/update_container_images.sh
. ./lib/ceph-upgrade-mdss.sh
. ./lib/ceph-upgrade-rgws.sh

if [ ! -d "/etc/cray" ]; then
  mkdir /etc/cray
fi

if [ ! -d "/etc/cray/ceph" ]; then
 mkdir /etc/cray/ceph
fi

function retry_enable_service() {
  host=$1
  service=$2
  echo "Retrying to enabling service $service on $host"
  rc=1
  local cnt=0
  until [ "$rc" -eq 0 ]; do
    cnt=$((cnt+1))
    if [ "$cnt" -eq 5 ]; then
      echo "ERROR: Unable to enable $service on $host, halting upgrade until this is repaired."
      exit 1
    fi
    output=$(ssh "$host" "systemctl enable $service")
    rc=$?
    if [ "$rc" -eq 0 ]; then
      break
    else
      echo "Sleeping 5 seconds before re-trying to enable $service on $host"
      sleep 5
    fi
  done
}

for node in $(seq 1 "$num_storage_nodes"); do
 nodename=$(printf "ncn-s%03d" "$node")
 ssh-keyscan -H "$nodename" >> ~/.ssh/known_hosts
done

for node in $(seq 1 "$num_storage_nodes"); do
 nodename=$(printf "ncn-s%03d.nmn" "$node")
 ssh-keyscan -H "$nodename" >> ~/.ssh/known_hosts
done

if [ ! -f "$upgrade_mons_file" ] && [ -f "$convert_rgw_file" ]; then
  rm $pre_pull_images_file
  rm $upgrade_mons_file
fi

if [ -f "$pre_pull_images_file" ]; then
  echo "Images have already been pre-pulled"
else
  echo "Pre-pulling Ceph images"
  pre_pull_ceph_images
  mark_initialized $pre_pull_images_file
fi

echo "Scaling down cephfs clients (if needed)"
scale_down_cephfs_clients

if [ -f "$convert_rgw_file" ]; then
  echo "Radosgw has already been converted"
else
  echo "Converting radosgw to a cephadm compatible config"
  convert_radosgw
  echo "Restarting radosgw daemons"
  restart_radosgw_daemons
  mark_initialized $convert_rgw_file
fi

if [ -f "$upgrade_init_file" ]; then
  echo "This cephadm preparation has already been completed"
else
  echo "Preparing cephadm to upgrade Ceph"
  ceph_upgrade_init
  echo "Sleeping 10 second"
  mark_initialized $upgrade_init_file
fi

### Begin run on each mon/mgr

if [ -f "$upgrade_mons_file" ]; then
  echo "The Ceph mon daemons have been upgraded"
else
  echo "Upgrading Ceph mons"
  upgrade_ceph_mons
  ## Check if everything was converted
  ## FIXME - ceph orch is not available yet.
  #echo "Validating ceph-mon has been converted"
  #ceph -f json-pretty orch ps|jq -r '.[]|select(.daemon_type|test("mon"))|.hostname'
  #ceph -f json-pretty orch ps|jq -r '.[]|select(.hostname|test("ncn-s001"))|.daemon_type'
  mark_initialized $upgrade_mons_file
fi


if [ -f "$upgrade_mgrs_file" ]; then
  echo "The Ceph mgr daemons have been upgraded"
else
  echo "Upgrading Ceph"
  upgrade_ceph_mgrs
  #Add check for mgrs here (find else repeat)
  mark_initialized $upgrade_mgrs_file
fi


### End run on each mon/mgr

if [ -f "$distribute_keys_file" ]; then
  echo "This Ceph cluster keys have already been distributed"
else
  echo "Creating and distributing keys for cephadm"
  create_cephadm_keys
  mark_initialized $distribute_keys_file
fi

if [ -f "$setup_orch_file" ]; then
  echo "This Ceph cluster has been converted to ceph-orchestrator"
else
  echo "Upgrading Ceph"
  ceph_orch_tasks
  wait_for_orch_hosts
  mark_initialized $setup_orch_file
fi

ceph -s

if [ -f "$upgrade_osds_file" ]; then
  echo "The OSD daemons have been upgraded"
else
  echo "Upgrading Ceph OSDs..."
  upgrade_osds
  wait_for_osds
  mark_initialized $upgrade_osds_file
fi

update_image_values

echo "Disable stray host/daemon warnings"
ceph config set mgr mgr/cephadm/warn_on_stray_hosts false
ceph config set mgr mgr/cephadm/warn_on_stray_daemons false

echo "Sleeping 30 seconds to allow daemons to begin launching..."
sleep 30

wait_for_running_daemons mon 3
wait_for_running_daemons mgr 3

if [ -f "$upgrade_mds_file" ]; then
  echo "The MDS daemons have been upgraded"
else
  echo "Upgrading MDS(s)..."
  upgrade_mds
  mark_initialized $upgrade_mds_file
fi

if [ -f "$upgrade_rgws_file" ]; then
  echo "The radosgw daemons have been upgraded"
else
  echo "Upgrading radosgw to 15.2.8"
  upgrade_rgws
  wait_for_running_daemons rgw 3
  echo "Enabling STS"
  enable_sts
  mark_initialized $upgrade_rgws_file
fi

echo "Enable Ceph orch to manage all services"
ceph orch apply mon --placement="3 $(ceph node ls|jq -r '.mon|keys| join(" ")')"
ceph orch apply mgr --placement="3 $(ceph node ls|jq -r '.mon|keys| join(" ")')"

echo "Enable stray host warnings"
ceph config set mgr mgr/cephadm/warn_on_stray_hosts true
ceph config set mgr mgr/cephadm/warn_on_stray_daemons true

wait_for_health_ok

echo "Scaling up cephfs clients"
scale_up_cephfs_clients

echo "Enabling all Ceph services to start on boot"
for host in $(ceph node ls| jq -r '.osd|keys[]'); do
  echo "Enabling services on host: $host"
  ssh "$host" 'for service in $(cephadm ls |jq -r .[].systemd_unit|grep $(ceph status -f json-pretty |jq -r .fsid));do echo "Enabling service $service on $(hostname)"; systemctl enable $service; done'
  echo "Verifying services on host: $host"
  output=$(ssh "$host" 'for service in $(cephadm ls |jq -r .[].systemd_unit|grep $(ceph status -f json-pretty |jq -r .fsid));do echo $service; systemctl is-enabled $service; done')
  cnt=0
  client_array=( $output )
  array_length=${#client_array[@]}
  while [[ "$cnt" -lt "$array_length" ]]; do
    service="${client_array[$cnt]}"
    cnt=$((cnt+1))
    status="${client_array[$cnt]}"
    cnt=$((cnt+1))
    echo "${service}: $status"
    if [ "$status" == "disabled" ]; then
      retry_enable_service $host $service
    fi
  done
done
