# Steps to follow after the worker node rollout during CSM upgrade

This document presents the steps to perform to avoid issues with iSCSI SBPS
during the CSM upgrade of worker nodes which are iSCSI target nodes.

## Symptom

After the worker node upgrade, I/O errors followed by flood of `squashfs` errors
are seen in the `dmesg` of iSCSI client nodes (Compute and UAN nodes) due to which
iSCSI client nodes became `un-responsive` where most of the commands failed with
`Bus error`.

Example command:

```bash
nid000001:~ # multipath -ll
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

The solution is to logout the iSCSI session with rebuilt worker node which is stale and re-establish
the iSCSI session with rebuilt worker node, rediscover the `LUNs` and login to iSCSI session using `iscsiadm`
command. The steps are automated in the script [`iscsi_post_rollout.sh`](../../scripts/operations/iscsi_sbps/iscsi_post_rollout.sh) and need to copy this script onto the iSCSI initiator nodes (Compute/UAN) and run it.

1. (`ncn-m#`) Run the script [`scp_iscsi_scr.sh`](../../scripts/operations/iscsi_sbps/scp_iscsi_scr.sh)
   to copy `iscsi_post_rollout.sh` onto compute nodes.

   ```bash
   sh scp_iscsi_scr.sh
   ```

   Copy `iscsi_post_rollout.sh` manually to UAN nodes onto /tmp directory.

1. (`ncn-m#`) Example command to run `iscsi_post_rollout.sh` on compute node:
   
   For example if `ncn-w002` was rebuilt and to run on compute node `x3000c0s19b3n0`:

   ```bash
   pdsh -w x3000c0s19b3n0 "sh /tmp/iscsi_post_rollout.sh ncn-w002"
   ```

**Note:**

In certain state of the system(s), the iSCSI session may not be allowed to logout, for example when a device or resource
in use, then it is required to disable the `iscsid.safe_logout` parameter in `/etc/iscsi/iscsid.conf` temporarily by
setting it to 'No', followed by restart of the `iscsid` service. Once this change has been made, run the `iscsi_post_rollout.sh` script.

By default, `iscsid.safe_logout` is set to 'Yes', so it must be changed to 'No' before executing the script.
After `iscsi_post_rollout.sh` completes successfully, restore `iscsid.safe_logout` to 'Yes' and restart the
`iscsid` service again to re-enable safe logout behavior.
