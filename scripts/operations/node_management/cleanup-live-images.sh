#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

ALL=0
AUTO=0
INCLUDE_OVERLAYFS=0
SQUASHFS_DISK=$(grep -Po 'root=[\w=:]+' /proc/cmdline)
SQUASHFS_BASE="$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/${SQUASHFS_DISK##*=})"
OVERLAYFS_DISK=$(grep -Po 'rd.live.overlay=[\w=]+' /proc/cmdline)
OVERLAYFS_BASE="$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/${OVERLAYFS_DISK##*=})"

if [ ! -d ${SQUASHFS_BASE} ] || [ ! -d ${OVERLAYFS_BASE} ]; then
    echo >&2 "Could not find [$SQUASHFS_BASE] or [$OVERLAYFS_BASE]!"
    exit 1
fi

DISK="$(blkid -L SQFSRAID)"
LIVE_DIR=$(grep -oP 'rd.live.dir=[\w\d-_.]+' /proc/cmdline)
[ -z "$LIVE_DIR" ] && LIVE_DIR='rd.live.dir=LiveOS'
LIVE_DIR="${LIVE_DIR#*=}"

function usage {
    cat << EOF
$(basename 0) will cleanup squashFS and overlayFS that live in the [$SQUASHFS_BASE] and [$OVERLAYFS_BASE] directories.

Without any arguments this script will prompt the user for confirmation before performing any destructive actions.

By default this script will ignore the currently running squashFS.

- Passing any argument other than -y or -a will print this usage.
- Passing '-y' will automatically clean unused images, bypassing the prompt.
- Passing '-a' will include all images (unused and used), this will break disk booting unless the node is re-imaged on the next reboot.
- Passing '-o' will include overlayFS for each image, otherwise these are left alone. This never cleans up the active overlayFS (despite -a being given) because it will break the running operating system.
EOF
}

while getopts "aoy" opt; do
    case ${opt} in
        y)
            AUTO=1
            ;;
        a)
            ALL=1
            ;;
        o)
            INCLUDE_OVERLAYFS=1
            ;;
        *)
            usage
            ;;
    esac
done

if [ ${ALL} = 0 ]; then
    readarray -t LIVE_DIRS < <(find /run/initramfs/live/* -type d -exec basename {} \; 2>/dev/null| grep -v ${LIVE_DIR})
else
    readarray -t LIVE_DIRS < <(find /run/initramfs/live/* -type d -exec basename {} \; 2>/dev/null)
fi
function print_capacity {
    local capacity
    local used

    capacity="$(df -h /run/initramfs/live | awk '{print $2}' | sed -z 's/\n/: /g;s/: $/\n/')"
    used="$(df -h /run/initramfs/live | awk '{print $3}' | sed -z 's/\n/: /g;s/: $/\n/')"

    echo -e "Image storage status:\n\n\t$capacity\n\t$used\n" 
}
print_capacity
echo "Current used image directory is: [${SQUASHFS_BASE}/${LIVE_DIR}]"
if [ "${#LIVE_DIRS[@]}" = 0 ]; then
    echo 'Nothing to remove.'
    exit 1
fi
echo 'Found the following unused image directories: '
for live_dir in "${LIVE_DIRS[@]}"; do
    size=$(du -hs ${SQUASHFS_BASE}/$live_dir | awk '{print $1}')
    printf '\t%s\t%s\n' ${live_dir} ${size}
done
if [ ${AUTO} = 0 ]; then
    read -r -p "Proceed to cleanup listed image directories? [y/n]:" response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo 'Removing image directories ...'
            ;;
        *)
            echo 'Exiting without removing anything.'
            exit 0
            ;;
    esac
else
    echo '-y was present; automatically removing images ...'
fi

to_remove_squashfs="$(printf ${SQUASHFS_BASE}'/%s ' "${LIVE_DIRS[@]}")"
to_remove_overlayfs="$(printf ${OVERLAYFS_BASE}'/%s ' "${LIVE_DIRS[@]}")"
mount -o rw,remount ${DISK} ${BASE}
echo 'Removing squashFS directories ... '
if [ ${ALL} -eq 1 ]; then
    echo "-a was present; removing ALL images including the currently booted image [${BASE}/${LIVE_DIR}]"
    echo >&2 "This node will be unable to diskboot until it is reimaged with a netboot."
    rm -rf ${to_remove_squashfs} "${SQUASHFS_BASE:?}/${LIVE_DIR}"
else
    rm -rf ${to_remove_squashfs}
fi
if [ ${INCLUDE_OVERLAYFS} -eq 1 ]; then
    echo 'Removing overlayFS directories ... '
    rm -rf ${to_remove_overlayfs}
else
    echo "Overlays were left untouched since -o was not provided, these will be present in [$OVERLAYFS_BASE]."
fi
echo 'Done'

# Attempt to remount as ro, but don't fail
if ! mount -o ro,remount ${DISK} ${BASE} 2>/dev/null; then
    echo >&2 "Attempted to remount ${BASE} as read-only but the device was busy. This will correct itself on the next reboot."
fi 

# Do not reprint the size, for some reason it doesn't report properly for a given amount of time.
#print_capacity
