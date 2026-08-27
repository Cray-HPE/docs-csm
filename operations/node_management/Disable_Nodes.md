# Disable Nodes

Use the [Hardware State Manager (HSM)][hsm] [Cray CLI][cli] commands to disable nodes on the system.

Disabling nodes that are not configured correctly allows the system to successfully boot.

## Prerequisites

- The [Cray command line interface (CLI)][cli] tool is initialized and configured on the system.

## Procedure

1. (`ncn-mw#`) Disable one or more nodes with [HSM][hsm].

    ```bash
    cray hsm state components bulkEnabled update --enabled false --component-ids XNAME_LIST --format toml
    ```

1. (`ncn-mw#`) Verify that the desired nodes are disabled.

    ```bash
    cray hsm state components query create --component-ids XNAME_LIST --format toml
    ```

    Example output:

    ```toml
    [[Components]]
    Type = "Node"
    Enabled = false
    State = "On"
    NID = 1003
    Flag = "OK"
    Role = "Compute"
    NetType = "Sling"
    Arch = "X86"
    ID = "x5000c1s0b1n1"

    [[Components]]
    Type = "Node"
    Enabled = false
    State = "On"
    NID = 1004
    Flag = "OK"
    Role = "Compute"
    NetType = "Sling"
    Arch = "X86"
    ID = "x5000c1s0b1n2"
    ```

After changing the state of nodes, be cautious when powering them on/off. The
preferred method for safely powering them on/off is to use the
[Boot Orchestration Service (BOS)][bos].
The [Cray Advanced Platform Monitoring and Control (CAPMC)][capmc] or
the [Power Control Service (PCS)][pcs] are used to directly control the power for nodes,
regardless of the state in [HSM][hsm]; CAPMC and PCS do not check if a node is disabled
in HSM.

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
