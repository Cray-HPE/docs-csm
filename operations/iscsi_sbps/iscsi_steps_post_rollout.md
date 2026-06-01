# Steps to follow after the worker node rollout during upgrade 

This document presents the steps to perform to avoid issues with iSCSI SBPS
during the CSM upgrade of worker nodes which are iSCSI target nodes.

## Symptom

After the worker node upgrade, I/O errors followed by flood of `squashfs` errors
are seen in the `dmesg` of iSCSI client nodes (Compute and UAN nodes) due to which
iSCSI client nodes became `un-responsive` where most of the commands failed with
`Bus error`.

Example command:

```bash
multipath -ll
```

Example command output reporting Bus error:

```text
3605377.034750 | /etc/multipath.conf line 10: ignoring deprecated option "disable_changed_wwids", using built-in value: "yes"
Bus error
```

`dmesg` output snippet of one of the compute node having I/O errors followed by `squashfs` errors:

```text
Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Unit Not Ready
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Sense Key : Illegal Request [current]
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Add. Sense: Logical unit not supported
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Read Capacity(16) failed: Result: hostbyte=DID_OK driverbyte=DRIVER_OK
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Sense Key : Illegal Request [current]
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: [sdbo] Add. Sense: Logical unit not supported
[Thu Apr  2 14:10:45 2026] sd 3:0:0:32: alua: rtpg failed
```

```text
nid001037:~ # dmesg -T | grep SQUASHFS
[Mon Apr  6 11:53:56 2026] SQUASHFS error: Failed to read block 0x4deef6e60: -5
[Mon Apr  6 11:53:56 2026] SQUASHFS error: Unable to read fragment cache entry [4deef6e60]
[Mon Apr  6 11:53:56 2026] SQUASHFS error: Unable to read fragment cache entry [4deef6e60]
[Mon Apr  6 11:53:56 2026] SQUASHFS error: Unable to read page, block 4deef6e60, size 837f
[Mon Apr  6 11:53:56 2026] SQUASHFS error: Failed to read block 0x4deeff1df: -5
```

## Root cause

The iSCSI `LUNs` mapping to `rootfs/PE` images before worker node rebuild as part of the upgrade, can
get mapped to different `rootfs/PE` images after rebuild and get different LUN numbers. The iSCSI
client nodes will send the I/O's to the iSCSI `LUNs` that were created before rebuild and I/O's fail
as those `LUNs` may not exist with the same LUN number or mapped to different images after rebuild.

## Resolution

The solution is, post worker node rebuild, logout the iSCSI session, discover the `LUNs` and login to
the iSCSI session using `iscsiadm` command. The steps are automated in the script
[`iscsi_post_rollout.sh`](../../scripts/operations/iscsi_sbps/iscsi_post_rollout.sh) and it is required
to copy the script onto iSCSI initiator (Compute/UAN) nodes and run using `pdsh` command from the master
node:

```text
sh iscsi_post_rollout.sh <NCN worker node>"
```

Example Command to be run if ncn-w002 was rolled out:

```bash
sh iscsi_post_rollout.sh ncn-w002
``` 

**Note:**

In certain state of the system(s), if the iSCSI session is not allowed to logout like if the device or resouce in
use, then it is required to turn of the `iscsid.safe_logout` attribute in `/etc/iscsi/iscsid.conf` file
and then restart the `iscsid` service and then logout the iSCSI session. By default `iscsid.safe_logout`
will be set to 'Yes', so this needs to be set to 'No'. After logging in to the iSCSI session, this needs
to be set back to 'Yes' and then restart the `iscsid` service.

Also, in some state of the system(s), iSCSI session will not be allowed to logout untill the worker node
to be rebuild is down. In such cases, iSCSI session needs to be logged out after the worker node is
down (cordon) during rebuild and may require to set the `iscsid.safe_logout` attribute in `/etc/iscsi/iscsid.conf`
to 'No' and restart `iscsid` service as mentioned above.
