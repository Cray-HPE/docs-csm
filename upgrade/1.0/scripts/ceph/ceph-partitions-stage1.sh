#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

disks=$(lsblk | grep -B2 -F md1  | grep ^s | awk '{print $1}')
disk1=$(echo $disks | awk '{print $1}')
disk2=$(echo $disks | awk '{print $2}')

echo "Creating dedicated partition for /var/lib/ceph"
parted /dev/$disk1 mkpart ext4 401GB 470G
mkfs.ext4 /dev/${disk1}4
echo "Stopping all Ceph services"
systemctl stop ceph.target
echo "Sleeping for thirty seconds to let things stop"
sleep 30
mount /dev/${disk1}4 /mnt
cp -rp /var/lib/ceph/* /mnt
umount /mnt
mount /dev/${disk1}4 /var/lib/ceph
echo "Starting Ceph services"
systemctl start ceph.target

echo "Creating dedicated partition for /var/lib/containers"
parted /dev/$disk2 mkpart ext4 401GB 470G
mkfs.ext4 /dev/${disk2}4
mkdir /var/lib/containers
mount /dev/${disk2}4 /var/lib/containers
chown -R ceph:ceph /var/lib/containers
