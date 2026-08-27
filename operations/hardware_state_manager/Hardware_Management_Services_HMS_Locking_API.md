# Hardware Management Services (HMS) Locking API

The locking feature is a part of the [Hardware State Manager (HSM)][hsm] API.
The locking API enables administrators to lock components on the system. Locking
components ensures other system actors, such as administrators or running services,
cannot perform a firmware update with the [Firmware Action Service (FAS)][fas] or a
power state change with the [Power Control Service (PCS)][pcs].

Locks only constrain FAS and PCS from each other, and help ensure that a firmware
update action will not be interfered with by a request to power off the device through
PCS. Locks only work with HMS services and will not impact other system services.
**Exception**: Starting in CSM 1.7, the [Boot Orchestration Service (BOS)][bos] is
aware of HSM locks. For more information, see
[BOS sessions and HSM locks](../boot_orchestration/Sessions.md#bos-sessions-and-hsm-locks).

Locks can only be used to prevent firmware updates with FAS, power state changes with PCS,
or inclusion in [BOS sessions](../boot_orchestration/Sessions.md).

Administrators can still use HMS APIs to view the state of various hardware components on
the system, even if a lock is in place. There is no automatic locking for hardware devices.
Locks need to be manually set or unset by an administrator. A scenario that might be
encountered is when a larger hardware state change job is run, and one of the components in
the job has a lock on it. If FAS is the service running the job, FAS will attempt to update
the firmware on each component, and will update all devices that do not have a lock on it.
The job will not complete until the node lock ends, or if a timeout is set for the job.

The locking API also includes actions to repair or disable a node's locking ability with
respect to HMS services. The disable function will make it so a device cannot be firmware
updated or power controlled (via an HMS service) until a repair is done. Future requests to
perform a firmware update via FAS or power state change via PCS cannot be made on that
component until the repair action is used.

**WARNING:** System administrators should **LOCK** [management NCNs][mgmt-ncns] after the
system has been brought up, in order to prevent an administrator from unintentionally
firmware updating or powering off an NCN. Without these locks, an authorized request to
FAS or PCS could power off the NCNs, which may negatively impact system stability and the
health of services running on those NCNs. See
[Lock and Unlock Management Nodes](Lock_and_Unlock_Management_Nodes.md).

For more information, see
[Manage HSM Locks](Manage_HMS_Locks.md).

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
[hsm]: ../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../glossary.md#high-speed-network-hsn
[ims]: ../../glossary.md#image-management-service-ims
[iuf]: ../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../glossary.md#management-nodes
[mountain]: ../../glossary.md#mountain-cabinet
[ncn]: ../../glossary.md#non-compute-node-ncn
[nid]: ../../glossary.md#node-id-nid
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
