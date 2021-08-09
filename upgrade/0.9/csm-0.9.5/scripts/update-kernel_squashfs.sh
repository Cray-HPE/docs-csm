#!/usr/bin/env bash

# Identify the bootraid.
BOOTRAID="$(awk '/LABEL=BOOTRAID/ {print $2}' /etc/fstab.metal)"

# Make sure the boot raid isn't mounted first. This might fail and that's ok.
umount "$BOOTRAID"

set -e

version_full=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-default | tail -n 1)
version_base="${version_full%%-*}"
version_suse="${version_full##*-}"
version_suse="${version_suse%.*.*}"
version="$version_base-$version_suse-default"
initrd=/boot/initrd-$version
kernel=/boot/vmlinuz-$version

set -x

# This should return 0 and show the files.
ls "$kernel" "$initrd"

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
cp -pv "$(ls $BOOTRAID/boot/initrd*)" /run/initramfs/live/LiveOS/

# Remount as read-only
mount -o remount,ro /run/initramfs/live


# Cleanup
umount "$BOOTRAID"