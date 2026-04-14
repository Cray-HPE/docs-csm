# Steps to follow after the worker node is down during Rebuild

This document presents the pre-requisite steps to avoid issues with iSCSI SBPS
during the CSM upgrade of worker nodes which are iSCSI target nodes.

## Symptom

After the worker node upgrade, I/O errors followed by flood of squashfs errors
are seen in the dmesg of iSCSI client nodes (Compute and UAN nodes) due to which
iSCSI client nodes became un-responsive where most of the commands failed with
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

dmesg output snippet of one of the compute node having I/O errors followed by squashfs errors:

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

The iSCSI LUNs mapping to rootfs/PE images before worker node rebuild as part of the upgrade, can
get mapped to different rootfs/PE images after rebuild and get different LUN numbers. The iSCSI
client nodes will send the I/O's to the iSCSI LUNs that were created before rebuild and I/O's fail
as those LUNs may not exist with the same LUN number or mapped to different images after rebuild.

## Resolution

Below steps need to be followed in order to avoid the issue:

1. ssh to iSCSI client (Compute/UAN) node

   Example command:

   ```bash
   (`ncn-m#`) ssh x3000c0s15b1n0
   ```

1. Edit /etc/iscsi/iscsid.conf, set the following parameter from 'Yes' to 'No', and then save it.

   iscsid.safe_logout = No

1. Restart iscsid service

   Example command:

   ```bash
   systemctl restart iscsid.service
   ```
 
1. List the iscsi sessions

   Example command:

   ```bash
   iscsiadm -m session
   ```

   Example command output:
 
   ```text
   tcp: [1] 10.153.0.2:3260,1 iqn.2023-06.csm.iscsi:ncn-w001 (non-flash)
   tcp: [3] 10.153.0.14:3260,1 iqn.2023-06.csm.iscsi:ncn-w003 (non-flash)
   tcp: [4] 10.153.0.10:3260,1 iqn.2023-06.csm.iscsi:ncn-w002 (non-flash)
   tcp: [5] 10.153.0.16:3260,1 iqn.2023-06.csm.iscsi:ncn-w004 (non-flash)
   ```

1. Logout the iSCSI session associated with the node (say ncn-w001) that is in progress with rebuild:

   command:

   ```bash
   iscsiadm -m node -T <iqn> -p <ip_address>:<port> -u
   ```

   Example command:

   ```bash
   iscsiadm -m node -T iqn.2023-06.csm.iscsi:ncn-w001 -p 10.153.0.2:3260 -u
   ```

1. Perform iscsiadm discovery of above worker node

   command:

   ```bash
   iscsiadm -m discovery -t sendtargets -p <ip_address>:<port>
   ```

   Example command:

   ```bash
   iscsiadm -m discovery -t sendtargets -p 10.153.0.2:3260
   ```

1. Login to the iSCSI session of the worker node

   command:

   ```bash
   iscsiadm -m node -T < iqn > -p <ip_address>:<port> -l
   ```

   Example command:

   ```bash
   iscsiadm -m node -T iqn.2023-06.csm.iscsi:ncn-w001  -p 10.153.0.2:3260 -l
   ```

1. Edit /etc/iscsi/iscsid.conf set 'iscsid.safe_logout' back to 'yes'

   iscsid.safe_logout = Yes

1. Restart iscsid service

   ```bash
   systemctl restart iscsid.service
   ```
