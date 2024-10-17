#!/bin/bash

#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
function usage() {
  usage="
  Ceph should automatically create OSDs and this script should ONLY be used
  when ceph is not adding OSDs to disks that are removable.
  This script is only designed to be used in cases where removable disks are
  not being utilized. Please see Ceph Troubleshooting documentation OSDs are not
  created on non-removable disks.

  Usage:
  On the device where the OSD should be added, run this script:
  './$(basename "$0") /dev/<disk>'
  './$(basename "$0") /dev/<disk> --force' to create the OSD on the device specified.

  "
  echo -e "--- USAGE ---\n${usage}"
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

NODE=$(hostname)
DEVICE=$1
force="${2:-False}"

# This script needs to be run from a storage node
if ! [[ ${NODE} =~ ^ncn-s ]]; then
  usage
  echo "This script needs to be run on the storage node where the OSD is to be added. This is running on ${NODE}. exiting ..."
  exit 0
fi

# check a valid device was provided
lsblk ${DEVICE}
if [[ $? -ne 0 ]]; then
  echo "ERROR ${DEVICE} is not a block device. Cannot create OSD on device"
  exit 1
fi

if lsblk ${DEVICE} | grep -q lvm; then
  echo "ERROR an lvm is present on ${DEVICE}. This is not expected when creating a new OSD on a disk."
  exit 1
fi

# print warning
echo "This script will create a new OSD on ${NODE}:${DEVICE}."
if [[ ${force} != "--force" ]]; then
  echo "If you would like to proceed putting an OSD on ${NODE}:${DEVICE}, then rerun this script with '--force'"
  exit 0
fi

# if bootstrap osd keyring file doesn't exist, then export it to file
if [ ! -f /var/lib/ceph/bootstrap-osd/ceph.keyring ]; then
  if [ ! -d /var/lib/ceph/bootstrap-osd ]; then
    mkdir /var/lib/ceph/bootstrap-osd
  fi
  if ceph auth list | grep -q client.bootstrap-osd; then
    ceph auth get client.bootstrap-osd > /var/lib/ceph/bootstrap-osd/ceph.keyring
  else
    echo "ERROR ceph client.bootstrap-osd keyring was not found in ceph auth. This is not expected."
    exit 1
  fi
fi

# prepare disk with a ceph lvm so an OSD can be created on it
cephadm ceph-volume --keyring /var/lib/ceph/bootstrap-osd/ceph.keyring lvm prepare --data ${DEVICE} --bluestore
if [[ $? -ne 0 ]]; then
  echo "ERROR Failed to create ceph lvm on ${DEVICE}. Look at the error in output above."
  exit 1
fi

rc=0
# ceph orch commands need to be run from ncn-s00[1-3]
if [[ ${NODE} == @("ncn-s001"|"ncn-s002"|"ncn-s003") ]]; then
  ceph orch daemon add osd ${NODE}:${DEVICE}
  rc=$?
else
  ssh ncn-s001 "ceph orch daemon add osd ${NODE}:${DEVICE}"
  rc=$?
fi

if [[ $rc -ne 0 ]]; then
  echo "ERROR Failed to create osd on ${NODE}:${DEVICE}. Look at the error in the output above."
  echo "The command used to create an OSD is 'ceph orch daemon add osd ${NODE}:${DEVICE}'. This needs to be run from ncn-s00[1-3]. You can try to run this command manually."
  exit 1
else
  echo "Successfully created an osd on ${NODE}:${DEVICE}"
fi
