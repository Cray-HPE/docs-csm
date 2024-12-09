# Repopulate Data in etcd Clusters When Rebuilding Them

When an etcd cluster is not healthy, it needs to be rebuilt. During that process, the pods that rely on etcd clusters lose data.
That data needs to be repopulated in order for the cluster to go back to a healthy state.

- [Repopulate Data in etcd Clusters When Rebuilding Them](#repopulate-data-in-etcd-clusters-when-rebuilding-them)
    - [Applicable services](#applicable-services)
    - [Prerequisites](#prerequisites)
    - [Procedures](#procedures)
        - [BOS](#bos)
        - [BSS](#bss)
        - [FAS](#fas)
        - [HMNFD](#hmnfd)

## Applicable services

The following services need their data repopulated in the etcd cluster:

- Boot Orchestration Service \(BOS\)
- Boot Script Service \(BSS\)
- Firmware Action Service \(FAS\)
- HMS Notification Fanout Daemon \(HMNFD\)
- Mountain Endpoint Discovery Service \(MEDS\)

## Prerequisites

An etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

## Procedures

- [BOS](#bos)
- [BSS](#bss)
- [FAS](#fas)
- [HMNFD](#hmnfd)

### BOS

Reconstruct boot session templates for impacted product streams to repopulate data.

Boot preparation information for other product streams can be found in the following locations:

- UANs: Refer to the UAN product stream repository and search for the "PREPARE UAN BOOT SESSION TEMPLATES" header in the "Install and Configure UANs" procedure.
- Cray Operating System \(COS\): Refer to the "Create a Boot Session Template" header in the "Boot COS" procedure in the COS product stream documentation.

### BSS

Restore BSS from the ETCD backup see [Restore an ETCD Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md)

### FAS

Reload the firmware images from Nexus.

Refer to the `Load Firmware from Nexus` section in [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-nexus) for more information.

When the etcd cluster is rebuilt, all historic data for firmware actions and all recorded snapshots will be lost.
Image data will be reloaded from Nexus.
Any images that were loaded into FAS outside of Nexus will need to be reloaded using the `Load Firmware from RPM or ZIP file` section in
[FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file).
After images are reloaded, any running actions at time of failure will need to be recreated.

### HMNFD

Resubscribe the compute nodes and any NCNs that use the ORCA daemon for their State Change Notifications \(SCN\).

1. (`ncn-m#`) Resubscribe all compute nodes.

    ```bash
    TMPFILE=$(mktemp)
    sat status --no-borders --no-headings | grep Ready | grep Compute | awk '{printf("nid%06d-nmn\n",$4);}' > "${TMPFILE}"
    pdsh -w ^"${TMPFILE}" "systemctl restart cray-orca"
    rm -rf "${TMPFILE}"
    ```

1. (`ncn-m#`) Resubscribe all worker nodes.

    **NOTE:** Modify the `-w` arguments in the following commands to reflect the number of worker nodes in the system.

    ```bash
    pdsh -w ncn-w00[1-4]-can.local "systemctl restart cray-orca"
    ```
