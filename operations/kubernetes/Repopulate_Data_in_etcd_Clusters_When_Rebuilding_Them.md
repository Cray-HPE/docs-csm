# Repopulate Data in etcd Clusters When Rebuilding Them

When an etcd cluster is not healthy, it needs to be rebuilt. During that process, the pods that rely on etcd clusters lose data.
That data needs to be repopulated in order for the cluster to go back to a healthy state.

- [Applicable services](#applicable-services)
- [Prerequisites](#prerequisites)
- [Procedures](#procedures)
    - [BSS](#bss)
    - [FAS](#fas)
    - [HMNFD](#hmnfd)

## Applicable services

The following services need their data repopulated in the etcd cluster:

- [Boot Script Service (BSS)][bss]
- [Firmware Action Service (FAS)][fas]
- [HMS Notification Fanout Daemon (HMNFD)][hmnfd]

## Prerequisites

An etcd cluster was rebuilt. See [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

## Procedures

- [BSS](#bss)
- [FAS](#fas)
- [HMNFD](#hmnfd)

### BSS

To restore [BSS][bss] from the etcd backup, see [Restore an ETCD Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md).

### FAS

Reload the firmware images from Nexus.

Refer to the `Load Firmware from Nexus` section in [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-nexus) for more information.

When the etcd cluster is rebuilt, all historic data for firmware actions and all recorded snapshots will be lost.
Image data will be reloaded from Nexus.
Any images that were loaded into [FAS][fas] outside of Nexus will need to be reloaded using the `Load Firmware from RPM or ZIP file` section in
[FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file).
After images are reloaded, any running actions at time of failure will need to be recreated.

### HMNFD

Resubscribe the [compute nodes][cn] and any [NCNs][ncn] that use the ORCA daemon for their State Change Notifications (SCN).

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

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../configure_cray_cli.md
[check-latest-docs]: ../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../glossary.md#ansible-execution-environment-aee
[an]: ../../glossary.md#application-node-an
[ara]: ../../glossary.md#ara-records-ansible-ara
[bmc]: ../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../glossary.md#boot-orchestration-service-bos
[bss]: ../../glossary.md#boot-script-service-bss
[can]: ../../glossary.md#customer-access-network-can
[canu]: ../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../glossary.md#configuration-framework-service-cfs
[chn]: ../../glossary.md#customer-high-speed-network-chn
[cli]: ../../glossary.md#cray-cli-cray
[cmn]: ../../glossary.md#customer-management-network-cmn
[cn]: ../../glossary.md#compute-node-cn
[csi]: ../../glossary.md#cray-site-init-csi
[fas]: ../../glossary.md#firmware-action-service-fas
[hbtd]: ../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../glossary.md#high-speed-network-hsn
[ims]: ../../glossary.md#image-management-service-ims
[iuf]: ../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../glossary.md#management-nodes
[mountain]: ../../glossary.md#mountain-cabinet
[nc]: ../../glossary.md#node-controller-nc
[ncn]: ../../glossary.md#non-compute-node-ncn
[nid]: ../../glossary.md#node-id-nid
[nmd]: ../../glossary.md#node-memory-dump-nmd
[nmn]: ../../glossary.md#node-management-network-nmn
[pcs]: ../../glossary.md#power-control-service-pcs
[pdu]: ../../glossary.md#power-distribution-unit-pdu
[pit]: ../../glossary.md#pre-install-toolkit-pit
[river]: ../../glossary.md#river-cabinet
[rts]: ../../glossary.md#redfish-translation-service-rts
[s3]: ../../glossary.md#simple-storage-service-s3
[sat]: ../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../glossary.md#system-configuration-service-scsd
[sdu]: ../../glossary.md#system-diagnostic-utility-sdu
[shcd]: ../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../glossary.md#slingshot
[sls]: ../../glossary.md#system-layout-service-sls
[sma]: ../../glossary.md#system-monitoring-application-sma
[smd]: ../../glossary.md#hardware-state-manager-smd
[sops]: ../../glossary.md#secrets-operations-sops
[tapms]: ../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../glossary.md#user-access-node-uan
[uss]: ../../glossary.md#user-services-software-uss
[vcs]: ../../glossary.md#version-control-service-vcs
[vnid]: ../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../glossary.md#xname

<!-- markdownlint-restore -->
