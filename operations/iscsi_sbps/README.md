# iSCSI SBPS (Scalable Boot Content Projection Service)

* [Introduction](#introduction)
* [iSCSI SBPS solution details](#iscsi-sbps-solution-details)
* [Steps to achieve SBPS](#steps-to-achieve-sbps)
* [Glossary](#glossary)

## Introduction

iSCSI based boot content projection solution named Scalable Boot Content Projection Service (SBPS)
is a boot content projection solution that replaces the Cray
[Content Projection Service (CPS)](../../glossary.md#content-projection-service-cps) and
[Data Virtualization Service (DVS)](../../glossary.md#data-virtualization-service-dvs).
SBPS projects boot content like `rootfs` and [Cray Programming Environment (CPE)](../../glossary.md#cray-programming-environment-cpe) images.
SBPS is aimed to offer better reliability, availability, security, ease and speed of deployment and ease of management than CPS/DVS.
SBPS was introduced in CSM 1.6. In CSM 1.7.0, support is removed for projecting root filesystems and PE images using
CPS and DVS. Also in CSM 1.7.0, the iSCSI SBPS [selective worker node personalization](#selective-worker-node-personalization)
feature is introduced.

The SBPS solution is spread across different components, including:

* [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos)
* [User Services Software (USS)](../../glossary.md#user-services-software-uss)
* The core service SBPS Marshal Agent is delivered as an RPM that gets deployed by the
  [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)

### Key features

* Provides open source friendly solution for read-only content projection (`rootfs` and `PE`) as it uses LIO (Linux IO) which is open source.
* Horizontally scalable content projection service (iSCSI target side)
* Delivers active/active IO operation from iSCSI initiator(s) to content projection service
* Delivers seamless failover and failback for iSCSI initiator(s) on iSCSI target(s) or partial network failure
* Supports projection over [High Speed Network (HSN)](../../glossary.md#high-speed-network-hsn) and
  [Node Management Network (NMN)](../../glossary.md#node-management-network-nmn) without significant reconfiguration
* Does not require additional hardware infrastructure (iSCSI target)
* Co-exists with DVS
* Enables future work related to image access control, [multi-tenancy](../multi-tenancy/Overview.md),
  and related zero trust principles
* Does not require duplication of images from [S3](../../glossary.md#simple-storage-service-s3)
* Supports monitoring for performance and reliability engineering
* Aligns with future plans for similar functionality in next generation systems management solutions
* Easy to deploy and manage

**Note:** Using HSN for boot content projection is recommended, and use NMN for any debugging purposes.
In the case that the HSN is not configured, use the NMN if it meets the bandwidth requirements.

## iSCSI SBPS solution details

![iSCSI SBPS Architecture](../../img/SBPS_Architecture_Diagram.jpg)

As shown in figure #1, the basic configuration involves two iSCSI target/server (worker node) nodes
and two iSCSI initiators/clients (compute nodes or UANs) connected via HSN and/or NMN where I/O multipath
is configured. The `rootfs` and `PE` images are hosted in the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
and S3 respectively and both of these images are mapped to `boot-images` bucket of S3. DNS records are created and used for target node
discovery from an initiator node during its boot.

**Note:** Atleast one iSCSI target/server (worker node) should be active for the image projection or for any I/O's from iSCSI initiators/clients.

### iSCSI target/server

* Standard Linux kernel
* `s3fs` to mount the `boot-images` bucket onto the worker node
* LIO (Linux IO) - an open-source implementation of SCSI target which supports `fileio` backing store
* `targetcli` - LIO command-line interface to manage iSCSI devices like creation of `LUNs`, listing of `LUNs`, creation of `fileio backstore`,
  saving/clearing the configuration, and so on
* The SBPS core service named SBPS Marshal Agent runs as a Linux `systemd` service
    * The agent scans IMS and S3 storage for `rootfs` and `PE` images
    * It creates `fileio backing store` for the images to be projected
    * The `rootfs` images to be projected are tagged by BOS when the boot of initiator nodes is triggered
    * Then the agent creates iSCSI `LUNs` for each of the `fileio` backing store where the images to be projected are mapped to these `LUNs`

### iSCSI initiator/client

* Standard Linux kernel
* User space iSCSI initiator services
* DM (Device Mapper) multipath software
* DNS SRV and A records are used to discover the target nodes during the boot and are part of BOS session template boot parameters
    * This BOS session template is used to trigger the boot of initiator nodes
    * The `LUNs` created on the target node which has the `rootfs`/ `PE` images mapped are thus projected to initiator nodes when the boot is triggered
    * Basically, the `rootfs` image projected is used as part of booting the initiator node and `PE` images projected are used post boot
    * These `LUNs` get mounted onto the initiator node as DM multipath `LUNs`
    * DM multipath software provides I/O multipath for high availability (failover and failback) and I/O load balancing

![iSCSI SBPS workflow](../../img/SBPS_workflow_latest.png)

## Steps to achieve SBPS

1. [Worker node personalization](#1-worker-node-personalization)
1. [Validate configuration](#2-validate-configuration)
1. [Create BOS session template](#3-create-bos-session-template)
1. [IMS image tagging](#4-ims-image-tagging)
1. [Boot compute nodes or UANs](#5-boot-compute-nodes-or-uans)
1. [Monitor iSCSI metrics](#6-monitor-iscsi-metrics)

### 1. Worker node personalization

Node personalization is the prerequisite step of SBPS solution where worker nodes are configured as iSCSI targets (servers)
with necessary provisioning. The required RPMs for the `targetcli` command and LIO are part of the NCN node image.
The SBPS Marshal Agent gets installed during node personalization using CFS.

#### Selective worker node personalization

In CSM 1.6, all worker nodes are configured and enabled as iSCSI SBPS targets using
[Management Node Personalization](../configuration_management/Management_Node_Personalization.md)

Starting in CSM 1.7.0, selective iSCSI worker node personalization is introduced.
All worker nodes are still **configured** for iSCSI, but selective node personalization gives
administrators control over which worker nodes are enabled as iSCSI SBPS targets.

The default behavior is still the same as in CSM 1.6, so if no action is taken to use this
feature, then all worker nodes will continue to be enabled as iSCSI targets.

For details on iSCSI selective worker node personalization,
see [Managing Selective Node Personalization](Managing_Selective_Node_Personalization.md).

#### Automatic setup with bootprep

By default worker node personalization of iSCSI SBPS is done during CSM install/upgrade
(using the [Install and Upgrade Framework (IUF)](../../glossary.md#install-and-upgrade-framework-iuf)).
It is initiated during bootprep (`management-nodes-rollout`) in order to do worker node personalization
automatically during boot time.

### 2. Validate configuration

In order to verify the readiness of the iSCSI targets before triggering the boot of compute nodes or
UANs, the iSCSI configuration should be validated. See [iSCSI SBPS Verification](iSCSI_SBPS_Verification.md).

### 3. Create BOS session template

Once the node personalization is done and the configuration has been validated, then create BOS Session Templates with SBPS boot parameters.

There are two ways to create BOS session template:

#### Using BOS directly

For details, refer to
[Create a Session Template to Boot Compute Nodes with SBPS](../boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md).

#### Using SAT

1. (`ncn-mw#`) Obtain system name and site domain.

    * System name

        ```bash
        craysys metadata get system-name
        ```

    * Site domain

        ```bash
        craysys metadata get site-domain
        ```

1. (`ncn-mw#`) Populate above values into `product_vars.yaml` and then create BOS session template using `sat` command.

    For example:

    ```bash
    sat bootprep run --vars-file "session_vars.yaml" --format json --bos-version v2 .bootprep-csm-1.6.0/compute-and-uan-bootprep.yaml
    ```

Refer to [SAT Bootprep](../system_admin_toolkit/usage/SAT_Bootprep.md) for further details.

**Note:** This way of creating BOS session template uses `vcs/bootprep/compute-and-uan-bootprep.yaml` where SBPS will be chosen by default.

### 4. IMS image tagging

To initiate the boot of compute nodes or UANs, the images (`rootfs`/ `PE` ) are tagged to determine which
`rootfs`/ `PE` image is to be projected.
The SBPS Marshal agent uses key/value pair of `sbps-project`/`true` to identify the images tagged.

#### `rootfs` image tagging

The `rootfs` images are tagged by BOS automatically when the boot of computes nodes or UANs is initiated.
Refer to
[BOS Workflows](../boot_orchestration/BOS_Workflows.md) for details.
It is also possible to tag the `rootfs` images in IMS manually using the Cray CLI.

#### PE image tagging

To tag the `PE` images, first import the `PE` image to IMS, and then use the Cray CLI to tag it in IMS.
Refer [Import External Image to IMS](../image_management/Import_External_Image_to_IMS.md) for the steps to import an image to IMS.

For details on how to add or remove an IMS image tag using the Cray CLI, refer to
[Manage image labels](../image_management/Image_Management_Workflows.md#manage-image-labels).

Below are few examples.

##### Add IMS image tag

(`ncn-mw#`) Tag IMS image with ID `bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb`.

```bash
cray ims images update bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb --metadata-operation set --metadata-key sbps-project --metadata-value true
```

##### Describe IMS image

(`ncn-mw#`) Describe IMS image with ID `bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb`.

```bash
cray ims images describe bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb --format json
```

Example output:

```format json
{
  "arch": "x86_64",
  "created": "2024-07-18T22:05:16.565885",
  "id": "bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb",
  "link": {
    "etag": "3325f830ba9ec291005a4087be4f666f",
    "path": "s3://boot-images/bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb/manifest.json",
    "type": "s3"
  },
  "metadata": {
    "sbps-project": "true"  <---------------- Tagged with key/value pair sbps-project/true
  },
  "name": "secure-storage-ceph-6.1.94-x86_64.squashfs"
}
```

##### Remove IMS image tag

(`ncn-mw#`) Remove tag from IMS image with ID `bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb`.

```bash
cray ims images update bbe0e9eb-fa8f-4896-9f54-95dbd26de9bb --metadata-operation remove --metadata-key sbps-project
```

**Note:**

> * Only remove tags from images that are not currently in use. Removing tags from images that are currently in use will
>   stop the content projection by SBPS Marshal agent, causing undesirable behavior on compute nodes or UANs using the content.
> * As mentioned in [`rootfs` image tagging](#rootfs-image-tagging), BOS automatically tags the `rootfs` image for projection.
>   BOS does not support automatically removing the tag, so it must be done manually.

### 5. Boot compute nodes or UANs

Follow the below steps in order to boot compute nodes or UANs.

#### Single node

(`ncn-mw#`) Use a command similar to the following to boot a single node.

```bash
cray bos sessions create --template-name <bos_session_template_name> --operation reboot --limit <xname_of_the_node>
```

For example, the following command creates a BOS session to boot the node with xname `x3000c0s19b2n0` using the BOS session template named `sbps-bos-template`.

```bash
cray bos sessions create --template-name sbps-bos-template --operation reboot --limit x3000c0s19b2n0
```

#### Multiple nodes

(`ncn-mw#`) Use a command similar to the following to boot every node targeted by a session template.

```bash
cray bos sessions create --template-name <bos_session_template_name> --operation reboot
```

#### Node console

For more information on accessing the consoles of the booting nodes, see:

* [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md)
* [Log in to a Node Using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md)

When booting compute nodes or UANs without the `--limit` option, the boot is triggered for all the nodes targeted by the session template.
It is necessary to open the console for each node separately.

### 6. Monitor iSCSI metrics

In order to monitor iSCSI SBPS target statistics, one may monitor metrics series like aggregate LUN read rate, read rate per LUN, throughput
statistics on LIO portal network endpoints, and so on.

Refer to [iSCSI Metrics](iSCSI_SBPS_Metrics.md) for details.

## Glossary

* iSCSI client: A client which initiates I/O requests and receives responses from iSCSI target
* iSCSI target: A server that responds to iSCSI commands and hosts storage resources
