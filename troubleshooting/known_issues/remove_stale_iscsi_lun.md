# Worker nodes may hang or unresponsive post `rootfs/PE` image deletion

## Symptom

On CSM 1.7 cluster, where compute/UAN nodes are booted with iSCSI SBPS,
if any `rootfs/PE` images are deleted say if some of these images are unused,
then worker nodes may hang or become unresponsive due to flood of following
messages in the worker nodes `dmesg`.

```text
[Fri Nov 7 15:06:12 2025] TARGET_CORE[iSCSI]: Detected NON_EXISTENT_LUN Access for 0x0000000a from iqn.2023-06.csm.iscsi:x1102c5s6b1n0
```

## Root cause

When the `rootfs/PE` images are deleted, the iSCSI SBPS marshal agent deletes corresponding
iSCSI `Luns` and `fileio` backing store while it scans `IMS/s3` every 180 secs. So once the iSCSI
`Luns` are deleted from the iSCSI target (worker node), the corresponding iSCSI `Luns` on the
iSCSI initiator (compute/UAN) node become stale and iSCSI initiator software looks for
corresponding `Luns` on the iSCSI target (worker) node repeatedly and above flood of messages
mentioned in the 'symptom' will be seen in the `dmesg` of worker nodes.

## Resolution

To fix this issue, we need to cleanup these stale iSCSI `Luns` on the iSCSI initiator. Run the
script [Remove stale iSCSI `Luns`](../../scripts/operations/iscsi_sbps/rm_stale_iscsi_lun.sh)
to delete stale iSCSI `Luns` from the iscsi initiator(s).
