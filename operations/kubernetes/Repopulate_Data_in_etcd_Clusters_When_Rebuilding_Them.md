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

## Applicable services

The following services need their data repopulated in the etcd cluster:

- Boot Orchestration Service (BOS)
- Boot Script Service (BSS)
- Firmware Action Service (FAS)
- Mountain Endpoint Discovery Service (MEDS)

## Prerequisites

An etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

## Procedures

- [BOS](#bos)
- [BSS](#bss)
- [FAS](#fas)

### BOS

BOS Session Templates

Boot preparation information can be found in the following locations:

- [BOS Session Templates](../../operations/boot_orchestration/Manage_a_Session_Template.md)
- [Boot UANs](../../operations/boot_orchestration/Boot_UANs.md)

Always consult the latest USS Administration Guide and CSM documentation for authoritative steps and best practices.

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
