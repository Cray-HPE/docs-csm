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

# Script to remove iSCSI Luns on the iSCSI iniator (compute/UAN) for which
# corresponding rootfs/PE images are going to be deleted. This script
# expects a file named img_str.txt as an argument which has the list of
# rootfs/PE image identifiers which is generated as an output of
# get_img_str.sh script ran before this script on the iSCSI target.

set -euo pipefail

FILE="$1"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <filename>"
  echo "Error: No file argument provided."
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: File not found"
  exit 1
fi

while IFS= read -r line; do

  for dev in $(lsscsi | grep $line | awk '{print $NF}'); do
    blockdev --flushbufs $dev
  done

  for lun in $(lsscsi | grep $line | awk '{print $1}' | tr -d '[' | tr -d ']'); do
    echo "Device going to be deleted is $line"
    echo 1 > /sys/class/scsi_device/$lun/device/delete
  done

done < "$FILE"

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
  fi
done
