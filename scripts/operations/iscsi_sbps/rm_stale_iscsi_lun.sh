#!/bin/bash

# Script to delete stale iSCSI Lun's which can be seen 
# in scenario's like after unused image deletion. 

# Get the list of iSCSI Luns
lsscsi -t | grep iscsi | awk '{print $4}' > iscsi_devs
	
input="iscsi_devs"

# For each iSCSI Lun, issue Report Luns command to determine
# whether it is stale or active lun. Report Luns command fails
# with Illegal request if it's a stale lun.

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

MULTIPATH_DEVICES=$(multipath -l | grep dm-* | awk '{print $1}')

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
