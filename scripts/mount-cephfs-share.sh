#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

upgrade_dir=/etc/cray/upgrade/csm
fstab=/etc/fstab

function move-rbd-mount {
  if grep -q "csm_scratch_img ${upgrade_dir}" ${fstab}; then
    new_mount=/mnt/csm-1.3-rbd
    echo "Found previous CSM release rbd mount, moving to ${new_mount}..."
    mkdir -p ${new_mount}
    if mountpoint ${upgrade_dir} > /dev/null 2>&1; then
      echo "Unmounting ${upgrade_dir}..."
      umount ${upgrade_dir}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: CSM rbd device failed to unmount! The above error should be"
        echo "       investigated/addressed, then re-run this script."
        exit 1
      fi
    else
      echo "${upgrade_dir} is not mounted, no need to unmount."
    fi
    echo "Replacing ${upgrade_dir} with ${new_mount} in ${fstab}..."
    sed -i "s|/etc/cray/upgrade/csm|${new_mount}|" ${fstab}
    echo "Mounting ${new_mount} to preserve previous upgrade content..."
    mount ${new_mount}
  else
    echo "Didn't find previous CSM release rbd mount, proceeding..."
  fi
}

function unmount_admin_tools_s3fs {
  s3fs_mount=/var/lib/admin-tools
  if grep -q "^admin-tools ${s3fs_mount}" ${fstab}; then
    echo "Found s3fs mount at ${s3fs_mount}, removing..."
    if mountpoint ${s3fs_mount} > /dev/null 2>&1; then
      echo "Unmounting ${s3fs_mount}..."
      umount ${s3fs_mount}
    else
      echo "${s3fs_mount} is not mounted, no need to unmount."
    fi
    echo "Removing ${s3fs_mount} from ${fstab}..."
    sed -i "/^admin-tools.*fuse.s3fs/d" ${fstab}
  else
    echo "Didn't find s3fs mount at ${s3fs_mount}, proceeding..."
  fi
}

function wait_for_running_daemons() {
  daemon_type=$1
  num_daemons=$2
  cnt=0
  while true; do
    if [[ $cnt -eq 60 ]]; then
      echo "ERROR: Giving up on waiting for $num_daemons $daemon_type daemons to be running..."
      break
    fi
    output=$(ceph orch ps --service_name $daemon_type -f json-pretty | jq -r '.[] | select(.status_desc=="running") | .service_name')
    if [[ $? -eq 0 ]]; then
      num_active=$(echo "$output" | wc -l)
      if [[ $num_active -eq $num_daemons ]]; then
        echo "Found $num_daemons running $daemon_type daemons -- continuing..."
        break
      fi
    fi
    sleep 5
    echo "Sleeping for five seconds waiting for $num_daemons running $daemon_type daemons..."
    cnt=$((cnt + 1))
  done
}

function create-admin-tools-cephfs-share {
  if [[ "$(ceph fs status admin-tools --format json-pretty 2> /dev/null | jq -r .clients[].fs)" != "admin-tools" ]]; then
    echo "Setting cephfs 'enable_multiple' flag to true..."
    ceph fs flag set enable_multiple true
    echo "Creating admin-tools ceph fs share..."
    ceph config generate-minimal-conf > /etc/ceph/new_ceph.conf
    cp /etc/ceph/new_ceph.conf /etc/ceph/ceph.conf
    rm /etc/ceph/new_ceph.conf
    ceph fs volume create admin-tools --placement="3 ncn-s001 ncn-s002 ncn-s003"
    wait_for_running_daemons mds.admin-tools 3
    echo "Creating admin-tools keyring..."
    ceph fs authorize admin-tools client.admin-tools / rw
    ceph auth export client.admin-tools -o /etc/ceph/ceph.client.admin-tools.keyring
  else
    echo "admin-tools ceph fs share already created..."
  fi

  if ! grep "mds_namespace=admin-tools" ${fstab} > /dev/null; then
    echo "Adding fstab entry for cephfs share..."
    mon_ips=$(ceph mon dump -f json-pretty 2> /dev/null | jq -r '[.mons[].public_addrs.addrvec[] | select(.type == "v1") | .addr] | join(",")')
    echo "" >> ${fstab}
    echo "${mon_ips}:/ /etc/cray/upgrade/csm ceph _netdev,name=admin-tools,relatime,defaults,mount_timeout=60,noauto,mds_namespace=admin-tools 1 1" >> ${fstab}
  else
    echo "fstab entry for cephfs already present..."
  fi

  echo "Calling systemctl daemon-reload to ensure changes to ${fstab} are loaded..."
  systemctl daemon-reload

  umount -f ${upgrade_dir} > /dev/null 2>&1
  mkdir -p ${upgrade_dir} > /dev/null 2>&1
  mount ${upgrade_dir}

  if [[ $? -ne 0 ]]; then
    echo "ERROR: CSM share failed to mount!"
    exit 1
  fi
}

if [[ "$(hostname)" =~ "ncn-m" ]]; then
  move-rbd-mount
  unmount_admin_tools_s3fs
  create-admin-tools-cephfs-share
  echo "Done! ${upgrade_dir} is mounted as a cephfs share!"
else
  echo "ERROR -- this script is meant to run on a master node."
fi
