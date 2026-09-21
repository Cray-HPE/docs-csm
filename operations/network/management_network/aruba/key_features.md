# Key Features Used in the Management Network Configuration

The following is a list of key features used in the management network configuration.

| Feature         | Notes | Description                                                                                                |
|:----------------|:-----:|:-----------------------------------------------------------------------------------------------------------|
| MLAG            |       | Layer 2 Redundancy, Allows the [NCNs][ncn] to be bonded so if one link fails they can continue to operate. |
| MLAG            |       | Layer 3 Redundancy, Allows one Spine switch/default gateway to fail and continue to work                   |
| VLAN            |       | Segregates layer 2 broadcast domains, need to separate [NMN][nmn]/[HMN][hmn]/[compute][cn] traffic.        |
| MSTP            |       | Layer 2 loop prevention mechanism at edge                                                                  |
| IP routing      |       | IP routing / static routes                                                                                 |
| OSPF            |       | Routing protocol used to peer from Leaf switches to Spines                                                 |
| BGP             |       | Routing protocol used to peer with MetalLB                                                                 |
| Prefix lists    |       | Lists to match components of an IP route                                                                   |
| Route maps      |       | Defines which route are redistributed                                                                      |
| NTP             |       | Network Time Protocol                                                                                      |
| ACLs            |       | Access Control Lists                                                                                       |
| Max MTU (9198)  |       | Max Transmission Unit/Maximum Frame size                                                                   |
| SNMP            |       | Allows for device polling from the [NCNs][ncn] to map out interfaces                                       |
| VRF             |       | Virtual routing and forwarding, used to segregate traffic between networks                                 |

[Back to Index](../README.md)

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cmn]: ../../../glossary.md#customer-management-network-cmn
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
