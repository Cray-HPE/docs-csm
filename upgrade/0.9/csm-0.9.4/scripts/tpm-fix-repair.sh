#!/usr/bin/env bash

# Copyright 2021 Hewlett Packard Enterprise Development LP

set -o errexit
set -o pipefail
set -o xtrace

mountpoint=/metal/boot

trim() {
    local var="$*"
    var="${var#${var%%[![:space:]]*}}"   # remove leading whitespace characters
    var="${var%${var##*[![:space:]]}}"   # remove trailing whitespace characters
    printf "%s" "$var"
}

function setup {
    [ -d $mountpoint ] || mkdir -pv $mountpoint
    mount -v -L BOOTRAID $mountpoint || echo 'continuing..'
    mv $mountpoint/boot/grub2/grub.cfg $mountpoint/boot/grub2/grub.cfg.bak ||
        echo 'already moved'
}

function install {
    # Get the kernel command we used to boot.
    local init_cmdline=$(cat /proc/cmdline)
    local disk_cmdline=''
    for cmd in $init_cmdline; do
        # cleans up first argument when running this script on an grub-booted system
        if [[ $cmd =~ kernel$ ]]; then
            cmd=$(basename "$(echo $cmd  | awk '{print $1}')")
        fi
        # removes all metal vars, and escapes anything that iPXE was escaping
        # (i.e. ds=nocloud-net;s=http://$url will get the ; escaped)
        # removes netboot vars
        if [[ ! $cmd =~ ^metal. ]] && [[ ! $cmd =~ ^ip=.*:dhcp ]] && [[ ! $cmd =~ ^bootdev= ]]; then
            disk_cmdline="$(trim $disk_cmdline) ${cmd//;/\\;}"
        fi
    done

    # ensure no-wipe is now set for disk-boots.
    disk_cmdline="$disk_cmdline metal.no-wipe=1"

    # Get the name of the initrd from the command line as it could be dyamic.
    #initrd=$(getarg initrd=) # need getarg, but loading library over pdsh fails
    [ -z "${initrd}" ] && initrd="initrd.img.xz"

    # Make our grub.cfg file.
    cat << EOF > $mountpoint/boot/grub2/grub.cfg
# PATCHED WITH CAST-26421
set timeout=10
set default=0 # Set the default menu entry
menuentry "Linux" --class sles --class gnu-linux --class gnu {
    set gfxpayload=keep
    insmod gzio
    insmod part_gpt
    insmod diskfilter
    insmod mdraid1x
    insmod ext2
    insmod xfs
    rmmod tpm
    echo	'Loading Linux  ...'
    linuxefi \$prefix/../$disk_cmdline domdadm
    echo	'Loading initial ramdisk ...'
    initrdefi \$prefix/../$initrd
}
EOF
}

function clean {
    umount $mountpoint
    echo 'done; BOOTRAID is patched with CAST-26421'
}

setup
install
clean

