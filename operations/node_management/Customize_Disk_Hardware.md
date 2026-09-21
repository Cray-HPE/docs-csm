# Customize PCIe Hardware

This page will assist an admin with changing the kernel parameters for [NCNs][ncn] that have extra disks.

> **NOTE:** If a system's hardware is Plan of Record (PoR), then this page is not needed.

For any procedure below, it is assumed that the extra disks are going to be utilized.
If they are undesired, then the only action item to do is to remove the disks from the NCN.

## Masters and workers

Add the kernel parameter `metal.disks=X` where `X` is the number of extra disks on the NCN.
This parameter may be added to the [PIT][pit] node's boot scripts or to the [Boot Script Service (BSS)][bss].

### PIT node

(`pit#`) For the PIT, edit the scripts for the masters and/or workers in `/var/www/ncn-*` with
this kernel parameter (the snippet below uses workers with 1 extra disk as an example):

```bash
for script in /var/www/ncn-w*/script.ipxe; do
sed -i 's/append/append metal.disks=3/' $script; done
```

### NCN (update BSS)

(`ncn#`) Update [BSS][bss] with the kernel parameter (the snippet below requires the [xname][xname]
of the [NCN][ncn] with the extra disks):

```bash
csi handoff bss-update-param --limit x3000c0s3b0n0 --kernel metal.disk=3
```

## Storage

There is nothing to do here. If there are extra disks they will be consumed by the Ceph installer.

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
