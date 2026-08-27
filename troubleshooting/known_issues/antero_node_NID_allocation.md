# Antero node NID allocation

- [Overview](#overview)
- [Workaround](#workaround)
    - [List Antero blade NIDs](#list-antero-blade-nids)
    - [List Antero nodes](#list-antero-nodes)
    - [List all compute NIDs](#list-all-compute-nids)
- [Correct the NID numbering](#correct-the-nid-numbering)

## Overview

There is a known issue with Antero nodes where [NIDs][nid]
are not correctly allocated. When [Cray Site Init (CSI)][csi]
generates the [System Layout Service (SLS)][sls]
input file, it assumes that all blades in liquid-cooled cabinets are Windom [compute][cn] blades.
Even though both Antero and Windom blades have 4 nodes, they have different physical layouts.

- Windom blades have 2 node [BMCs][bmc], 2 nodes per node [BMC][bmc], resulting in the following nodes: `b0n0`, `b0n1`, `b1n0`, `b1n1`
- Antero blades have 1 node [BMC][bmc], 4 nodes per node [BMC][bmc], resulting in the following nodes: `b0n0`, `b0n1`, `b0n2`, `b0n3`

[SLS][sls] has [NIDs][nid] only allocated for nodes `b0n0`, `b0n1`, `b1n0`, and `b1n1` on a [compute][cn] node blade.
On an Antero blade, the nodes `b0n2` and `b0n3` will have automatically assigned [NIDs][nid] that are not contiguous
with the [NIDs][nid] on nodes `b0n0` and `b0n1`.

It is important to note that the nodes `b0n2` and `b0n3` on an Antero blade are functional,
but do not have [NIDs][nid] in contiguous range with their peers.

## Workaround

This section gives information on how to work around this issue until there is a system
maintenance window in which to [Correct the NID numbering](#correct-the-nid-numbering).
To work around this issue, the appropriate [NID][nid] values for nodes `b0n2` and `n0n3` on Antero blades
must be supplied to the Work Load Manager (WLM) when it launches jobs.

The following sections provide examples of [SAT][sat] commands that can help determine the
[NIDs][nid] that are in use for Antero blades.

- [List Antero blade NIDs](#list-antero-blade-nids)
- [List Antero nodes](#list-antero-nodes)
- [List all compute NIDs](#list-all-compute-nids)

### List Antero blade NIDs

(`ncn-mw#`) View the [NIDs][nid] for Antero blades in the system:

```bash
ANTERO=$(sat hwinv --list-node-enclosures --fields=xname \
             --filter='Model=ANTERO' --format json  | \
         jq '.node_enclosure_list[] | "xname=(.xname)*"' -r | sed 's/e0//' | \
         paste -sd " " | sed 's/ / or /g')
sat status --type Node --fields 'xname,role,nid' --filter "${ANTERO}"
```

Example output:

```text
+---------------+---------+-----------+
| xname         | Role    | NID       |
+---------------+---------+-----------+
| x9000c1s4b0n0 | Compute | 1016      |
| x9000c1s4b0n1 | Compute | 1017      |
| x9000c1s4b0n2 | Compute | 147474562 |
| x9000c1s4b0n3 | Compute | 147474563 |
| x9000c1s5b0n0 | Compute | 1020      |
| x9000c1s5b0n1 | Compute | 1021      |
| x9000c1s5b0n2 | Compute | 147474594 |
| x9000c1s5b0n3 | Compute | 147474595 |
+---------------+---------+-----------+
```

### List Antero nodes

(`ncn-mw#`) Identify the Antero nodes present in the system:

```bash
sat hwinv --list-nodes --fields 'xname,"Model"' --filter='Model="HPE EX4252"'
```

Example output:

```text
################################################################################
Listing of all nodes
################################################################################
+---------------+------------+
| xname         | Model      |
+---------------+------------+
| x9000c1s7b0n0 | HPE EX4252 |
| x9000c1s7b0n1 | HPE EX4252 |
| x9000c1s7b0n2 | HPE EX4252 |
| x9000c1s7b0n3 | HPE EX4252 |
| x9000c3s0b0n0 | HPE EX4252 |
| x9000c3s0b0n1 | HPE EX4252 |
| x9000c3s0b0n2 | HPE EX4252 |
| x9000c3s0b0n3 | HPE EX4252 |
+---------------+------------+
```

### List all compute NIDs

(`ncn-mw#`) View [NIDs][nid] for all [compute nodes][cn] in the system:

```bash
sat status --type Node --fields 'xname,role,nid' --filter 'role=compute'
```

Example output:

```text
+---------------+---------+-----------+
| xname         | Role    | NID       |
+---------------+---------+-----------+
| x9000c1s0b0n0 | Compute | 1000      |
| x9000c1s0b0n1 | Compute | 1001      |
| x9000c1s1b0n0 | Compute | 1004      |
| x9000c1s1b0n1 | Compute | 1005      |
| x9000c1s7b0n0 | Compute | 1028      |
| x9000c1s7b0n1 | Compute | 1029      |
| x9000c1s7b0n2 | Compute | 147474562 |
| x9000c1s7b0n3 | Compute | 147474563 |
| x9000c3s0b0n0 | Compute | 1032      |
| x9000c3s0b0n1 | Compute | 1033      |
| x9000c3s0b0n2 | Compute | 147474594 |
| x9000c3s0b0n3 | Compute | 147474595 |
+---------------+---------+-----------+
```

## Correct the NID numbering

Optionally, during a system maintenance window, the Antero [NID][nid] numbering can be corrected by following the
[Defragment NID Numbering][defrag-nids] procedure.

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

[defrag-nids]: ../../operations/node_management/Defragment_NID_Numbering.md

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../operations/configure_cray_cli.md
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
[scsd]: ../../glossary.md#system-configuration-service-scsd
[shcd]: ../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../glossary.md#slingshot
[sls]: ../../glossary.md#system-layout-service-sls
[sma]: ../../glossary.md#system-monitoring-application-sma
[smd]: ../../glossary.md#hardware-state-manager-smd
[tapms]: ../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../glossary.md#user-access-node-uan
[vcs]: ../../glossary.md#version-control-service-vcs
[vnid]: ../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../glossary.md#xname

<!-- markdownlint-restore -->
