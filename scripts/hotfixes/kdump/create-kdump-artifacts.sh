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
set -euo pipefail

# Source common dracut parameters.
. "$(dirname $0)/dracut-lib.sh"

# show the line that we failed and on and exit non-zero

trap 'catch $? $LINENO; cleanup; exit 1' ERR

# if the script is interrupted, run the cleanup function
trap 'cleanup' INT EXIT

# catch() prints what line the script failed on, runs the cleanup function, and then exits non-zero
catch() {
    # Show what line the error occurred on because it can be difficult to detect in a dracut environment
    echo "CATCH: exit code $1 occurred on line $2 in $(basename "${0}")"
    cleanup
    exit 1
}


# cleanup() removes temporary files, puts things back where they belong, etc.
cleanup() {
    echo "CLEANUP: cleanup function running ..."

    # Restore the dracut config if it was removed.
    [ ! -f /etc/dracut.conf.d/05-metal.conf ] && cp -v /run/rootfsbase/etc/dracut.conf.d/05-metal.conf /etc/dracut.conf.d/05-metal.conf

    # Stops re-running this script on reboot
    # TODO: This script should move to the pipeline, and the service can then be removed (MTL-1830).
    systemctl disable kdump-cray
}


# check_size() offers a CAUTION message if the initrd is larger then 20MB
# this is just a soft warning since several factors can influence running out of memory including:
# crashkernel= parameters, drivers that are loaded, modules that are loaded, etc.
# so it's more of a your mileage may vary message
check_size() {

    local initrd="$1"
    local max=20000000 # kdump initrds larger than 20M may run into issues with memory
    
    if [[ "$(stat --format=%s $initrd)" -ge "$max" ]]; then
        echo >&2 "CAUTION: initrd might be too large ($(stat --format=%s $initrd)) and may exceed available memory (OOM) if used"
    else
        echo "initrd size is $(stat --format=%s $initrd) bytes"
    fi
}


# FIXME: Remove this function, see notes on each block of code contained for prerequites for removal.
function update_fstab {

    local initrd="$1"
    local sqfs_label="${2:-'SQFSRAID'}"
    local live_dir="${3:-'LiveOS'}"

    echo "Unpacking generated initrd [$initrd] to amend fstab ..."

    local temp=/tmp/ktmp

    [ -d $temp ] && rm -rf $temp
    mkdir -p $temp
    pushd $temp || exit 1
    /usr/lib/dracut/skipcpio ${initrd} | xzcat | cpio -id
    
    # This hack removes the automated entry for mnt0, we have been unable to resolve where it came from.
    # It seems to come from kdump source, likely the C code.
    tail -n +2 etc/fstab > etc/fstab.new
    mv etc/fstab.new etc/fstab

    # kdump/boot points to mnt0 assuming it is the `/` partition, this corrects it to point
    # to the actual boot directory from the squash.
    # NOTE: The boot directory won't contain the kdump initrd until we run this script in the NCN pipeline.
    #       We assume that this directory is mounted to provide access
    #       to the kdump initrd (not that it needs to be accessed).
    rm -rf kdump/boot
    ln -snf rootfsbase/boot kdump/boot

    # /etc/sysconfig/kdump differs between the running system and in the kdump initrd.
    # in the initrd the value is this: KDUMP_SAVEDIR="file:///mnt0/var/crash"
    # in runtime it's KDUMP_SAVEDIR="file:////var/crash"
    # instead of modifying KDUMP_SAVEDIR since the values don't match between each context, this symlinks
    # where /var/crash exists in runtime to `/kdump/mnt0.
    sqfs_uuid=$(blkid -lt LABEL=$sqfs_label | tr ' ' '\n' | awk -F '"' ' /UUID/ {print $2}')
    rm -rf kdump/mnt0
    ln -snf overlay/${live_dir}/overlay-$sqfs_label-$sqfs_uuid/ kdump/mnt0

    echo "Regenerating modified kdump initrd ..."
    rm -f ${initrd}
    find . | cpio -oac | xz -C crc32 -z -c > ${initrd}
    popd
    rm -rf $temp
}


function build_initrd {

    local init_cmdline    
    local kdump_cmdline
    local kdump_add
    local kdump_omit
    local kdump_omit_drivers

    local live_dir=''
    local live_dir_arg=''
    local live_img=''
    local live_img_arg=''
    local overlay_label=''
    local overlay_label_arg=''
    local root=''
    local root_arg=''
    local sqfs_drive_url=''
    local sqfs_label=''
    local sqfs_label_arg=''
    local sqfs_label_arg=''

    # kdump-specific kernel parameters
    init_cmdline=$(cat /proc/cmdline)
    kdump_cmdline=()
    for cmd in $init_cmdline; do
        # cleans up first argument when running this script on a disk-booted system
        if [[ $cmd =~ kernel$ ]]; then
            cmd=$(basename "$(echo $cmd  | awk '{print $1}')")
        fi
        if [[ $cmd =~ ^rd\.live\.dir=.* ]]; then
            live_dir_arg="${cmd//;/\\;}"
        fi
        if [[ $cmd =~ ^rd\.live\.squashimg=.* ]]; then
            live_img_arg="${cmd//;/\\;}"
        fi
        if [[ $cmd =~ ^root=.* ]]; then
            root_arg="${cmd//;/\\;}"
            root=${root_arg#*=}
            case "$root" in
                live:*)
                    sqfs_drive_url=${root#live:}
                    sqfs_label_arg=${sqfs_drive_url#*:}
                    ;;
                *)
                    echo >&2 "This kdump script does not support a root type of $root"
                    ;;
            esac
        fi
        if [[ $cmd =~ ^rd.live.overlay=.* ]]; then
            overlay_label_arg="${cmd//;/\\;}"
        fi
        if [[ $cmd =~ ^rd.live.overlay.reset ]] ; then :
        elif [[ ! $cmd =~ ^metal. ]] && [[ ! $cmd =~ ^ip=.* ]] && [[ ! $cmd =~ ^bootdev=.* ]] ; then
            kdump_cmdline+=( "${cmd//;/\\;}" )
        fi
    done
    kdump_cmdline+=( "rd.info" )
    kdump_cmdline+=( "rd.debug=1" )
    
    # Resolve the filesystem and the live directory dynamically.
    [ -n "${sqfs_label_arg:-''}" ] && sqfs_label="${sqfs_label_arg#*=}"
    [ -z "$sqfs_label" ] && sqfs_label='SQFSRAID'
    [ -n "${overlay_label_arg:-''}" ] && overlay_label="${overlay_label_arg##*=}"
    [ -z "$overlay_label" ] && overlay_label='ROOTRAID'
    [ -n "${live_dir_arg:-''}" ] && live_dir="${live_dir_arg#*=}"
    [ -z "$live_dir" ] && live_dir='LiveOS'
    [ -n "${live_img_arg:-''}" ] && live_img="${live_img_arg#*=}"
    [ -z "$live_img" ] && live_img='filesystem.squashfs'
    
    initrd_name="/boot/initrd-${KVER}-kdump"

    # kdump-specific modules to add
    kdump_add=${ADD[*]}
    kdump_add+=( 'kdump' )

    # modules to remove
    kdump_omit=${OMIT[*]}
    kdump_omit+=( "plymouth" )
    kdump_omit+=( "resume" )
    kdump_omit+=( "metalmdsquash" )
    kdump_omit+=( "metaldmk8s" )
    kdump_omit+=( "metalluksetcd" )
    kdump_omit+=( "usrmount" )

    # Omit these drivers to make a smaller initrd.
    kdump_omit_drivers=$OMIT_DRIVERS
    kdump_omit_drivers+=( "mlx5_core" )
    kdump_omit_drivers+=( "mlx5_ib" )
    kdump_omit_drivers+=( "sunrpc" )
    kdump_omit_drivers+=( "xhci_hcd" )

    # move the 05-metal.conf file out of the way while the initrd is generated
    # it causes some conflicts if it's in place when 'dracut' is called.
    # This is restored by the cleanup function at the end.
    rm -f /etc/dracut.conf.d/05-metal.conf

    # generate the kdump initrd
    # Special notes for specific parameters:
    # - hostonly makes a smaller initrd for the system; if this script is ran in the pipeline this should be swapped for --no-hostonly.
    # - fstab is used to mitigate risk from reading /proc/mounts
    # - mount these are given to support mounting both /kdump/boot and /kdump/mnt0, /kdump/boot is meaningless so this is done as a formality
    # - filesystems only xfs is needed
    # - no-hostonly-default-device removes auto-resolution of root, this neatens the dracut output
    # - nohardlink is needed to provide init properly, hardlinking does not work since init exists on a different filesystem
    # - force-drivers raid1 is necessary to be able to view the raids we have
    echo "Creating initrd/kernel artifacts ..."
    dracut \
        -L 4 \
        --force \
        --hostonly \
        --omit "$(printf '%s' "${kdump_omit[*]}")" \
        --omit-drivers "$(printf '%s' "${kdump_omit_drivers[*]}")" \
        --add "$(printf '%s' "${kdump_add[*]}")" \
        --fstab \
        --nohardlink \
        --mount "LABEL=${sqfs_label} /kdump/live xfs ro" \
        --mount "/kdump/live/${live_dir}/${live_img} /kdump/rootfsbase squashfs ro" \
        --mount "LABEL=${overlay_label} /kdump/overlay xfs" \
        --filesystems 'xfs' \
        --compress 'xz -0 --check=crc32' \
        --no-hostonly-default-device \
        --kernel-cmdline "$(printf '%s' "${kdump_cmdline[*]}")" \
        --persistent-policy by-label \
        --mdadmconf \
        --printsize \
        --force-drivers 'raid1' \
        ${initrd_name}

    update_fstab ${initrd_name} ${sqfs_label} ${live_dir}
    check_size ${initrd_name}
    
    # restart kdump to apply the change
    echo "Restarting kdump ..."
    systemctl restart kdump
    echo "Done!"
}

build_initrd
