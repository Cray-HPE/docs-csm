# Upload Node Boot Information to Boot Script Service (BSS)

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
    1. [Set variables](#1-set-variables)
    1. [Update BSS](#2-update-bss)
        - [Update BSS by host name](#update-bss-by-host-name)
        - [Update BSS by NID](#update-bss-by-nid)
        - [Update BSS default boot setup](#update-bss-default-boot-setup)
    1. [Next step](#3-next-step)
- [Additional BSS queries](#additional-bss-queries)
    - [View a boot script in BSS](#view-a-boot-script-in-bss)
    - [View all BSS contents](#view-all-bss-contents)
    - [View HSM information in BSS](#view-hsm-information-in-bss)
    - [View all boot parameters in BSS](#view-all-boot-parameters-in-bss)
- [Additional resources](#additional-resources)

## Overview

The following information must be uploaded to the
[Boot Script Service (BSS)][bss]
as a prerequisite to booting a node using iPXE:

- The location of an `initrd` image in the artifact repository
- The location of a kernel image in the artifact repository
- Kernel boot parameters
- The nodes associated with that information, using either host name or [node ID (NID)][nid]

[BSS][bss] manages the iPXE boot scripts that coordinate the boot process for nodes, and it enables basic association of boot scripts with nodes.
The boot scripts supply a booting node with a pointer to the necessary images (kernel and `initrd`) and a set of boot-time parameters.

When using [BOS][bos] to boot nodes, this is done automatically. The information on this page describes how
an administrator can do this manually, if desired.

## Prerequisites

- The [Cray command line interface (CLI)][cli] tool is initialized and configured on the system.
    - See [Configure the Cray CLI][config-cli].
- The [Boot Script Service (BSS)][bss] is running.
- An `initrd` image and kernel image for one or more nodes have been uploaded to the artifact repository.
    - See [Manage Artifacts with the Cray CLI](../artifact_management/Manage_Artifacts_with_the_Cray_CLI.md).

## Procedure

> Throughout this procedure, be sure to replace the example values with the actual values for the hosts, boot artifacts,
> and parameters.

### 1. Set variables

Set variables identifying the boot artifacts and parameters.

1. (`ncn-mw#`) Set `KERNEL` to the [S3][s3] download URL of the kernel artifact.

    This should be in the `s3://s3_BUCKET/S3_OBJECT_KEY/kernel` format.

    ```bash
    KERNEL=s3://boot-images/97b548b9-2ea9-45c9-95ba-dfc77e5522eb/kernel
    ```

1. (`ncn-mw#`) Set `INITRD` to the [S3][s3] download URL of the `initrd` artifact.

    This should be in the `s3://s3_BUCKET/S3_OBJECT_KEY/initrd` format.

    ```bash
    INITRD=s3://boot-images/97b548b9-2ea9-45c9-95ba-dfc77e5522eb/initrd
    ```

1. (`ncn-mw#`) Set `ROOTFS` to the [S3][s3] download URL of the `rootfs` artifact.

    This should be in the `s3://s3_BUCKET/S3_OBJECT_KEY/rootfs` format.

    ```bash
    ROOTFS=s3://boot-images/97b548b9-2ea9-45c9-95ba-dfc77e5522eb/rootfs
    ```

1. (`ncn-mw#`) Set `ETAG` to the `etag` of the `rootfs` in [S3][s3].

    ```bash
    S3_BUCKET_KEY=$(echo "${ROOTFS}" | sed 's#^s3://([^/]\+)/(.*rootfs)$#\1 \2#')
    ETAG=$(cray artifacts describe ${S3_BUCKET_KEY} --format json | jq -r '.artifact.ETag' | tr -d '"')
    ```

1. (`ncn-mw#`) Set `PARAMS` to the boot kernel parameters.

    **IMPORTANT:** The `PARAMS` line must always include the substring `crashkernel=512M`.
    This enables node dumps, which are needed to troubleshoot node crashes.

    > For readability, this example shows the variable being set over multiple lines.

    ```bash
    PARAMS="console=ttyS0,115200 bad_page=panic crashkernel=512M,high "
    PARAMS+="crashkernel=256M,low intel_pstate=disable numa_balancing=disable oops=panic "
    PARAMS+="pcie_ports=native rd.retry=10 rd.shell split_lock_detect=off systemd.unified_cgroup_hierarchy=1 "
    PARAMS+="ip=dhcp quiet spire_join_token=\${SPIRE_JOIN_TOKEN} "
    PARAMS+="root=craycps-s3:${ROOTFS}:${ETAG}:dvs:api-gw-service-nmn.local:300:eth0 "
    PARAMS+="nmd_data=url=${ROOTFS},etag=${ETAG} bos_update_frequency=4h"
    ```

1. (`ncn-mw#`) Review the variables and verify that the values are correct.

    ```bash
    echo "KERNEL=${KERNEL}"
    echo "INITRD=${INITRD}"
    echo "ROOTFS=${ROOTFS}"
    echo "ETAG=${ETAG}"
    echo "PARAMS=${PARAMS}"
    ```

### 2. Update BSS

> This step requires the variables from [1. Set variables](#1-set-variables).

There are three options for updating [BSS][bss]:

- [Update BSS by host name](#update-bss-by-host-name)
- [Update BSS by NID](#update-bss-by-nid)
- [Update BSS default boot setup](#update-bss-default-boot-setup)

#### Update BSS by host name

1. (`ncn-mw#`) Set `HOSTS` to a comma-separated list of the node component names ([xnames][xname])
   whose [BSS][bss] entries should be updated.

    ```bash
    HOSTS=x3000c0s21b1n0,x3000c0s21b2n0
    ```

1. (`ncn-mw#`) Create the boot parameters in [BSS][bss] for the selected nodes.

    ```bash
    cray bss bootparameters create --hosts "${HOSTS}" --kernel "${KERNEL}" --initrd "${INITRD}" --params "${PARAMS}"
    ```

1. (`ncn-mw#`) Confirm that the information has been uploaded to [BSS][bss].

    ```bash
    cray bss bootparameters list --hosts "${HOSTS}"
    ```

#### Update BSS by NID

1. (`ncn-mw#`) Set `NIDS` to a comma-separated list of the [node IDs][nid] whose [BSS][bss] entries should be updated.

    ```bash
    NIDS=1001,1032
    ```

1. (`ncn-mw#`) Create the boot parameters in [BSS][bss] for the selected nodes.

    ```bash
    cray bss bootparameters create --nids "${NIDS}" --kernel "${KERNEL}" --initrd "${INITRD}" --params "${PARAMS}"
    ```

1. (`ncn-mw#`) Confirm that the information has been uploaded to [BSS][bss].

    ```bash
    cray bss bootparameters list --nids "${NIDS}"
    ```

#### Update BSS default boot setup

[BSS][bss] supports a mechanism that allows for a default boot setup, rather than needing to specify boot details for each specific node.
This feature is particularly useful with larger systems. To do this, follow the [Update BSS by host name](#update-bss-by-host-name)
procedure, setting the `HOSTS` variable to `Default`.

### 3. Next step

Boot information has been added to [BSS][bss] in preparation for iPXE booting all nodes in the list of host names or [NIDs][nid].

As part of power up the nodes in the host name or [NID][nid] list, the next step is to reboot the nodes.

See also:
[Troubleshoot Compute Node Boot Issues Related to the Boot Script Service (BSS)][troubleshoot-bss-node-boot]

## Additional BSS queries

This section lists other [BSS][bss] queries that may be useful when booting nodes or debugging boot issues.

- [View a boot script in BSS](#view-a-boot-script-in-bss)
- [View all BSS contents](#view-all-bss-contents)
- [View HSM information in BSS](#view-hsm-information-in-bss)
- [View all boot parameters in BSS](#view-all-boot-parameters-in-bss)

### View a boot script in BSS

This will show the specific boot script that will be passed to a given node when requesting a boot script.
This is useful for debugging boot problems and to verify that [BSS][bss] is configured correctly.

- (`ncn-mw#`) View the boot script in [BSS][bss] using a [NID][nid].

    ```bash
    cray bss bootscript list --nid NODE_ID
    ```

- (`ncn-mw#`) View the boot script in [BSS][bss] using a host name.

    ```bash
    cray bss bootscript list --name HOST_NAME
    ```

### View all BSS contents

(`ncn-mw#`) View the entire contents of [BSS][bss].

```bash
cray bss dumpstate list
```

### View HSM information in BSS

(`ncn-mw#`) View the information that [BSS][bss] retrieved from the
[Hardware State Manager (HSM)][hsm].

```bash
cray bss hosts list
```

### View all boot parameters in BSS

(`ncn-mw#`) View all boot parameter information in [BSS][bss].

```bash
cray bss bootparameters list
```

## Additional resources

- [BSS API specification](../../api/bss.md)
- [Troubleshoot Compute Node Boot Issues Related to the Boot Script Service (BSS)][troubleshoot-bss-node-boot]

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

[troubleshoot-bss-node-boot]: Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md

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
