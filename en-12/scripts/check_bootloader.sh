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

ERROR=0

if [ -f /etc/pit-release ]; then
    echo >&2 'This must run from an NCN and is not allowed to run from the PIT node'
    exit 1
fi

if ! mount -v -L BOOTRAID -T /etc/fstab.metal 2>/dev/null; then
    if ! grep -q BOOTRAID /etc/fstab.metal; then
        echo >&2 'BOOTRAID is missing from /etc/fstab.metal'
        exit 1
    fi
fi
BOOTRAID=$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/BOOTRAID)

# validate the kernel exists, use the one that matches the --no-hostonly initrd
function verify_kernel {
    if [ ! -f ${BOOTRAID}/boot/kernel ];then 
        echo >&2 "kernel missing at ${BOOTRAID}/boot"
        return 1
    else
        echo "The disk's kernel exists and is validated."
    fi
}

# verify initrd
function verify_initrd {
    
    local image_error=0
    local error=0
    local needed_initrd_name
    local needed_initrd
    
    needed_initrd_name="$(grep -oP '(?<=initrdefi \$prefix/\.\./)(initrd[a-zA-Z.\-_]*)' ${BOOTRAID}/boot/grub2/grub.cfg)"
    needed_initrd="${BOOTRAID}/boot/${needed_initrd_name}"
    if [ ! -f $needed_initrd ]; then

        echo >&2 "Grub expects ${needed_initrd} but it did not exist!"
        error=1

        if [ -f ${BOOTRAID}/boot/initrd ]; then
            
            echo >&2 "Found [${BOOTRAID}/boot/initrd] which differs from the expected [$needed_initrd]."

        elif [ -f ${BOOTRAID}/boot/initrd.img.xz ]; then

            echo >&2 "Found [${BOOTRAID}/boot/initrd.img.xz] which differs from the expected [$needed_initrd]."

        else

            echo >&2 "No initrd was found in the bootloader; [${BOOTRAID}] is missing an initrd!"

            if [ ! -f /squashfs/initrd.img.xz ]; then

                echo >&2 "The original initrd is also missing [/squashfs/initrd.img.xz]."
                image_error=1

            else

                echo "The original initrd exists [/squashfs/initrd.img.xz]."

            fi
        fi
    fi

    if [ ${error} -ne 0 ]; then
        echo >&2 "The errors that were found will prevent the disk bootloader from working."
        if [ ${image_error} -ne 0 ]; then

            echo >&2 "Cloud-init seems to have failed because the expected [/squashfs/initrd.img.xz] is missing."
            echo >&2 "The squashFS that is currently booted is missing a dependency for the bootloader to work."

        fi
        return 1
    fi
    
    # After finding the initrd we care about, verify it is a proper cpio archive.
    if [[ $(file $needed_initrd) != *cpio* ]]; then

        echo >&2 'initrd is corrupt! The initrd is not a CPIO archive.'
        return 1
    else

        echo "The disk's initrd was validated. The initrd name in GRUB's configuration exists on the filesystem and is a proper CPIO archive."
        return 0
    fi
}

if ! verify_kernel; then
    ERROR=1
fi 
if ! verify_initrd; then
    ERROR=1
fi
if [ ${ERROR} -ne 0 ]; then
    echo >&2 'The disk bootloader will not work and is broken.'
    echo >&2 'This means that either the used squashFS has a failed customization or that cloud-init failed to run the metal install.'
    echo >&2 'This could also mean that the cmdline has the wrong `initrd=` argument set, and cloud-init was unable to find the `initrd` in S3.'
    exit 1
else
    exit 0
fi
