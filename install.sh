#!/bin/bash
set -e
systemctl restart basecamp
storage_img=/var/www/ephemeral/data/ceph/storage-ceph-58cdec2-1600459956994.squashfs
k8s_img=/var/www/ephemeral/data/k8s/kubernetes-06a008f-1600716578006.squashfs
kernel=/var/www/ephemeral/data/5.3.18-24.9-default-0.0.1-1.kernel
initrd=/var/www/ephemeral/data/initrd.img-0.0.1-1.xz
echo "Setting kernel link to $kernel"
ln -sf $kernel /var/www/kernel
echo "Setting initrd link to $initrd"
ln -sf $initrd /var/www/initrd.img.xz
echo "Setting image link to $storage_img"
ln -sf $storage_img /var/www/filesystem.squashfs
for x in 1 2 3
do
  echo "Power cycling ncn-s00$x-mgmt"
  ipmitool -I lanplus -U root -P $password -H ncn-s00$x-mgmt chassis bootdev pxe options=efiboot
  ipmitool -I lanplus -U root -P $password  -H ncn-s00$x-mgmt chassis power on
done
sleep 30
for x in 1 2 3
do
  until ping -c 1 ncn-s00$x 2>&1 > /dev/null
  do
    echo "waiting for ncn-s00$x to be up..."
    sleep 5
done
echo "ncn-s00$x is up"
done
sleep 180
echo "Setting image link to $k8s_img"
ln -sf $k8s_img /var/www/filesystem.squashfs
for x in 1 2 3
do
  echo "Power cycling ncn-m00$x-mgmt"
  ipmitool -I lanplus -U root -P $password -H ncn-m00$x-mgmt chassis bootdev pxe options=efiboot
  ipmitool -I lanplus -U root -P $password -H ncn-m00$x-mgmt chassis power on
done
echo "Power cycling workers"
ipmitool -I lanplus -U root -P $password -H ncn-w002-mgmt chassis bootdev pxe options=efiboot
ipmitool -I lanplus -U root -P $password -H ncn-w002-mgmt chassis power on
ipmitool -I lanplus -U root -P $password -H ncn-w003-mgmt chassis bootdev pxe options=efiboot
ipmitool -I lanplus -U root -P $password -H ncn-w003-mgmt chassis power on
