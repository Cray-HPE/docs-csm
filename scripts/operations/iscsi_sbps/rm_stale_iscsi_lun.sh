#!/bin/bash

#  MIT License
#
#  (C) Copyright 2025 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

# Script to remove stale iSCSI LUNs

lsscsi -t | grep iscsi | awk '{print $4}' > iscsi_devs
	
input="iscsi_devs"

# Issue Report Luns command to each of the iSCSI Luns.
# Report Luns command fails if stale lun.

while IFS= read -r line
do
    sg_luns --readonly -q "$line" &> /dev/null

    if [ "$?" -ne 0 ]; then
	blockdev --flushbufs $line
        echo "report luns command failed for $line"
	lun=$(lsscsi | grep $line | awk '{print $1}' | tr -d '[' | tr -d ']')
	echo "lun = $lun"
        echo 1 > /sys/class/scsi_device/$lun/device/delete 
    fi
done < "$input"

rm iscsi_devs

# Cleanup Multipath devices if no active paths

echo "Check for multipath devices with no active paths..."

MULTIPATH_DEVICES=$(multipath -l | grep "dm-*" | awk '{print $1}')

for dev in $MULTIPATH_DEVICES; do

    ACTIVE_PATHS=$(multipath -l "$dev" | grep 'active' | grep 'running' | wc -l)

    if [ "$ACTIVE_PATHS" -eq 0 ]; then
        echo "Multipath device $dev has 0 active paths. Removing it..."
        # Flush the I/O and remove the multipath device
        multipath -f "$dev"
        if [ $? -eq 0 ]; then
            echo "Successfully removed $dev."
        else
            echo "Failed to remove $dev. It might be in use."
        fi
    else
        echo "Multipath device $dev has $ACTIVE_PATHS active paths. Keeping it."
    fi
done
