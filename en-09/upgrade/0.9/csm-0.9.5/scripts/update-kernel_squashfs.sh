#!/usr/bin/env bash

# Identify the bootraid.
BOOTRAID="$(awk '/LABEL=BOOTRAID/ {print $2}' /etc/fstab.metal)"

# Make sure the boot raid is not mounted first. This might fail and that is ok because that probably just means it
# was not mounted in the first place.
umount "$BOOTRAID"

set -e

version_full=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-default | tail -n 1)
version_base="${version_full%%-*}"
version_suse="${version_full##*-}"
version_suse="${version_suse%.*.*}"
version="$version_base-$version_suse-default"
initrd=/tmp/initrd.img.xz
kernel=/boot/vmlinuz-$version

set -x

# If this is a master node this file will get in the way as it will make what needs to be a generic initrd specific
# to this node and that will not work.
rm -f /etc/dracut.conf.d/05-metal.conf

# Produce a new initrd from the new kernel.
dracut --xz --force \
    --omit 'cifs ntfs-3g btrfs nfs fcoe iscsi modsign fcoe-uefi nbd dmraid multipath dmsquash-live-ntfs' \
    --omit-drivers 'ecb md5 hmac' \
    --add 'mdraid' \
    --force-add 'dmsquash-live livenet mdraid' \
    --install 'rmdir wipefs sgdisk vgremove less' \
    --persistent-policy by-label --show-modules --ro-mnt --no-hostonly --no-hostonly-cmdline \
    --kver "${version}" \
    --printsize "$initrd"

# This should return 0 and show the files.
ls "$kernel" "$initrd"

# Put back the removed file.
cp /run/rootfsbase/etc/dracut.conf.d/05-metal.conf /etc/dracut.conf.d/05-metal.conf

###
### Kernel/initrd updates.
###

# Mount the bootraid.
mount -L BOOTRAID -T /etc/fstab.metal

# Copy the initrd.
cp -pv "$initrd" "$BOOTRAID/boot/$(grep initrdefi $BOOTRAID/boot/grub2/grub.cfg | awk '{print $2}' | awk -F'/' '{print $NF}')"

# Copy the kernel.
cp -pv "$kernel" "$BOOTRAID/boot/kernel"

# Verify

###
### SquashFS updates.
###

# Mount the running system as read/write
mount -o remount,rw /run/initramfs/live

# Copy them the kernel into place
cp -pv "$BOOTRAID/boot/kernel" /run/initramfs/live/LiveOS

# Copy the initrd into place
cp -pv "$initrd" /run/initramfs/live/LiveOS/

# Remount as read-only
mount -o remount,ro /run/initramfs/live


# Cleanup
umount "$BOOTRAID"