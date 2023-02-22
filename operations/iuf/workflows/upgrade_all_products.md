# Install or Upgrade All Products Provided in a HPC CSM Software Recipe

The following workflow describes an install or upgrade procedure of all **non-CSM product content** provided with a HPC CSM Software Recipe release. This is to be followed after an initial install of CSM or whenever new non-CSM
product content is made available for upgrade and there is no need to upgrade CSM itself. **CSM is not installed or upgraded in this workflow.** Instructions for performing an initial install of CSM are provided in
[Cray System Management Install](../../../install/README.md). Instructions for performing an upgrade install of CSM and non-CSM product content at the same time are provided in [Upgrade CSM](../../../upgrade/README.md). Follow those
instructions for either of those scenarios instead of this workflow.

All stages of `iuf` are executed in this workflow: all of the new product software provided in the recipe release is deployed and all management NCNs and managed compute and application (UAN, etc.) nodes are rebooted to new images
and CFS configurations. Manual operations are documented for procedures that are not currently managed by IUF.

The install/upgrade workflow comprises the following procedures:

- [Prepare for the install or upgrade](#prepare-for-the-install-or-upgrade)
- [Product delivery](#product-delivery)
  - [Execute the IUF `process-media`, `pre-install-check`, and `deliver-product` stages](#execute-the-iuf-process-media-pre-install-check-and-deliver-product-stages)
  - [Perform manual product delivery operations](#perform-manual-product-delivery-operations)
- [Configuration](#configuration)
  - [Execute the IUF `update-vcs-config` stage](#execute-the-iuf-update-vcs-config-stage)
  - [Perform manual product configuration operations](#perform-manual-product-configuration-operations)
- [Image preparation](#image-preparation)
  - [Execute the IUF `update-cfs-config` and `prepare-images` stages](#execute-the-iuf-update-cfs-config-and-prepare-images-stages)
  - [Manually prepare additional images](#manually-prepare-additional-images)
    - [UAI images](#uai-images)
- [Backup](#backup)
  - [Slingshot Fabric Manager](#slingshot-fabric-manager)
- [Management rollout](#management-rollout)
  - [Execute the IUF `deploy-product` and `post-install-service-check` stages](#execute-the-iuf-deploy-product-and-post-install-service-check-stages)
  - [Manual configuration of the Slingshot Fabric Manager](#manual-configuration-of-the-slingshot-fabric-manager)
  - [Perform Slingshot switch firmware updates](#perform-slingshot-switch-firmware-updates)
  - [Update management host firmware (FAS)](#update-management-host-firmware-fas)
  - [Execute the IUF `management-nodes-rollout` stage](#execute-the-iuf-management-nodes-rollout-stage)
    - [NCN worker nodes](#ncn-worker-nodes)
    - [NCN master nodes](#ncn-master-nodes)
    - [NCN storage nodes](#ncn-storage-nodes)
  - [Update management host Slingshot NIC firmware](#update-management-host-slingshot-nic-firmware)
- [Managed rollout](#managed-rollout)
  - [Update managed host firmware (FAS)](#update-managed-host-firmware-fas)
  - [Execute the IUF `managed-nodes-rollout` stage](#execute-the-iuf-managed-nodes-rollout-stage)
    - [Compute nodes](#compute-nodes)
    - [Application nodes](#application-nodes)
  - [Update managed host Slingshot NIC firmware](#update-managed-host-slingshot-nic-firmware)
  - [Execute the IUF `post-install-check` stage](#execute-the-iuf-post-install-check-stage)
- [Conclusion](#conclusion)

## Prepare for the install or upgrade

This section defines environment variables and directory content that is used throughout the workflow.

**`NOTE`** The following step uses the `iuf activity` command to demonstrate how to record operations within an IUF activity. While `iuf` automatically records all `iuf run` operations within an IUF activity, any other
administrative operation can also be recorded within an IUF activity by using `iuf activity` in this manner. The remainder of the workflow will not use `iuf activity`, deferring to the administrator to use it as they desire.

1. Create timestamped media, activity, and administrator directories on `ncn-m001`. Copy all distribution files from the HPC CSM Software Recipe to the media directory, utilizing `iuf activity` to record the time spent downloading
media and associate it with activity `${ACTIVITY_NAME}`.

    The following environment variables are used throughout the workflow:

    | Name               | Path                                           | Description                                                                               |
    | ------------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------------- |
    | `${ACTIVITY_NAME}` | n/a                                            | String identifier for the IUF activity and the `iuf -a` argument for all `iuf` commands   |
    | `${MEDIA_DIR}`     | `/etc/cray/upgrade/csm/"${ACTIVITY_NAME}"`     | Directory containing product distribution files                                           |
    | `${ACTIVITY_DIR}`  | `/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"` | Directory containing IUF activity logs and state                                          |
    | `${ADMIN_DIR}`     | `/etc/cray/upgrade/csm/admin`                  | Directory containing files that define site preferences for IUF, e.g. `product_vars.yaml` |

    (`ncn-m001#`) Create a typescript, set environment variables for the workflow, and populate the media directory with product content.

    ```bash
    script -af iuf.$(date +%Y%m%d_%H%M%S).txt
    DATE=`date +%Y%m%d%H%M%S`
    ACTIVITY_NAME=update-products-"${DATE}"
    MEDIA_DIR=/etc/cray/upgrade/csm/"${ACTIVITY_NAME}"
    ACTIVITY_DIR=/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"
    ADMIN_DIR=/etc/cray/upgrade/csm/admin
    mkdir -p "${ACTIVITY_DIR}" "${MEDIA_DIR}" "${ADMIN_DIR}"
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "downloading product media" in_progress
    < copy HPC CSM Software Recipe content to "${MEDIA_DIR}" >
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "download complete" waiting_admin
    ```

Once this step has completed:

- Product content has been uploaded to `${MEDIA_DIR}`

## Product delivery

This section ensures the product content is loaded onto the system and available for later steps in the workflow.

### Execute the IUF `process-media`, `pre-install-check`, and `deliver-product` stages

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `process-media`, `pre-install-check`,
or `deliver-product` stages.

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-e` to execute the [`process-media`](../stages/process_media.md), [`pre-install-check`](../stages/pre_install_check.md), and
   [`deliver-product`](../stages/deliver_product.md) stages. Perform the upgrade using product content found in `${MEDIA_DIR}`.

    (`ncn-m001#`) Execute the `process-media`, `pre-install-check`, and `deliver-product` stages.

    ```bash
    iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run -e deliver-product
    ```

Once this step has completed:

- Product content has been extracted from the product distribution files in `${MEDIA_DIR}`
- Pre-install checks have been performed for CSM and all products found in `${MEDIA_DIR}`
- Product content for all products found in `${MEDIA_DIR}` has been uploaded to the system
- Product content uploaded to the system has been recorded in the product catalog
- Per-stage product hooks have executed for the `process-media`, `pre-install-check`, and `deliver-product` stages

### Perform manual product delivery operations

**`NOTE`** This subsection is optional and can be skipped if third-party GPU and/or programming environment software is not needed.

Some products provide instructions for delivering third-party content to the system outside of IUF. If this content is desired, refer to the following documentation for instructions and execute the procedures before continuing
with the workflow.

- **Content:** Third-party GPU software
  - **Description:** The Cray Operating System (COS) provides the `gpu-nexus-tool` script to upload third-party GPU software to Nexus. The GPU software is used later in the workflow when creating CFS configurations and building
    compute and application node images.
  - **Instructions:** See the "IUF Stage Details for COS" section of _HPE Cray Operating System Installation Guide CSM on HPE Cray EX Systems (S-8025)_ for references to the installation procedures.
- **Content:** Third-party programming environment software
  - **Description:** The Cray Programming Environment (CPE) provides the `install-3p.sh` script to upload third-party programming environment software to Nexus. The programming environment software is used later in the workflow when
    creating CPE configurations and building CPE images.
  - **Instructions:** See the "CPE Install and Upgrade Framework usage" section of _HPE CPE Installation Guide CSM on HPE Cray EX Systems (S-8003)_ for references to the installation procedures.

Once this step has completed:

- Third-party software has been uploaded to Nexus

## Configuration

This section ensures product configuration have been defined, customized, and is available for later steps in the workflow.

This workflow uses `${ADMIN_DIR}` to retain files that define site preferences for IUF. `${ADMIN_DIR}` is defined separately from `${ACTIVITY_DIR}` and `${MEDIA_DIR}` based on the assumption that the files in `${ADMIN_DIR}` will be
used when performing future IUF operations unrelated to this workflow.

**`NOTE`** The following steps assume `${ADMIN_DIR}` is empty. If this is not the case, i.e. `${ADMIN_DIR}` has been populated by previous IUF workflows, ensure the content in `${ADMIN_DIR}` is up to date with the latest content
provided by the HPC CSM Software Recipe release content being installed. This may involve merging new content provided in the latest branch of the `hpc-csm-software-recipe` repository in VCS with the existing content in `${ADMIN_DIR}`.

### Populate `${ADMIN_DIR}` with files defining site preferences

1. Change directory to `${ADMIN_DIR}`

    ```bash
    cd ${ADMIN_DIR}
    ```

1. Follow the instructions in [Accessing `sat bootprep` Files](../../configuration_management/Accessing_Sat_Bootprep_Files.md) to check out content from the `hpc-csm-software-recipe` repository and switch to the branch named for the
HPC CSM Software Recipe release being installed/upgraded. When complete, the contents of `${ADMIN_DIR}` should look similar to this:

    (`ncn-m001#`) List contents of `${ADMIN_DIR}`

    ```bash
    ls *
    product_vars.yaml

    bootprep:
    compute-and-uan-bootprep.yaml  management-bootprep.yaml
    ```

1. Edit the `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files to account for any site deviations from the default values. For example:
    - Comment out the `shs-mellanox_install-integration-{{shs.version}}` CFS configuration layers and uncomment the `shs-cassini_install-integration-{{shs.version}}` CFS configuration layers
    - Uncomment the `gpu-{{recipe.version}}` CFS configuration layer and `gpu-image` image definition
    - Etc.

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override the HPE-provided `product_vars.yaml` content. For example:
    - Add a `default` section containing a `network_type: "cassini"` entry to define the desired Slingshot network type used when executing CFS configurations later in the workflow
    - Add a `suffix` entry to the `default` section to append a string to the names of CFS configuration, image, and BOS session template artifacts created during the workflow for easy identification from other artifacts
    - Etc.

    (`ncn-m001#`) Display the contents of an example `site_vars.yaml` file

    ```bash
    cat site_vars.yaml
    default:
      network_type: "cassini"
      suffix: "test01"
    ```

    When complete, the contents of `${ADMIN_DIR}` should look similar to this:

    (`ncn-m001#`) List contents of `${ADMIN_DIR}`

    ```bash
    ls *
    product_vars.yaml  site_vars.yaml

    bootprep:
    compute-and-uan-bootprep.yaml  management-bootprep.yaml
    ```

Once this step has completed:

- `${ADMIN_DIR}` is populated with `product_vars.yaml`, `site_vars.yaml`, and `sat bootprep` input files
- The aforementioned configuration files have been updated to reflect site preferences

### Execute the IUF `update-vcs-config` stage

**`NOTE`** Additional arguments are available to control the behavior of the `update-vcs-config` stage, for example `-rv`. See the [`update-vcs-config` stage
documentation](../stages/update_vcs_config.md) for details and adjust the examples below if necessary.

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `update-vcs-config` stage.

1. Invoke `iuf run` with `-r` to execute the [`update-vcs-config`](../stages/update_vcs_config.md) stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml`
file found in `${ADMIN_DIR}`.

    (`ncn-m001#`) Execute the `update-vcs-config` stage.

    ```bash
    iuf -a ${ACTIVITY_NAME} run --site-vars "${ADMIN_DIR}/site_vars.yaml" --bpcd "${ADMIN_DIR}" -r update-vcs-config
    ```

Once this step has completed:

- Product configuration content has been merged to VCS branches as described in the [update-vcs-config stage documentation](../stages/update_vcs_config.md)
- Per-stage product hooks have executed for the `update-vcs-config` stage

### Perform manual product configuration operations

Some products must be manually configured prior to the creation of CFS configurations and images. The "Install and Upgrade Framework" section of each individual product's installation documentation will refer to instructions for product-specific
configuration, if any. The following highlights some of the areas that most often require manual configuration changes **but is not intended to be a comprehensive list.** Note that many of the configuration changes are only
required for initial installation scenarios.

- Products that most often require site customizations to Ansible content in VCS
  - COS
  - CPE
  - Slingshot Host Software
  - UAN
- Workload Managers
  - Update settings for Slurm or PBS installation via `update-customizations.sh`
- Initial install configuration changes (not required for upgrade scenarios)
  - SAT
    - Configure SAT authentication via `sat auth`
    - Generate SAT S3 credentials
    - Configure system revision information via `sat setrev`
  - SDU
    - Configure SDU via `sdu setup`
  - COS
    - Set the COS root password in HashiCorp Vault
  - UAN
    - Set the UAN root password in HashiCorp Vault

Once this step has completed:

- Product configuration has been completed

## Image preparation

This section creates CFS configurations and bootable images that will be used by later steps in the workflow.

Before proceeding, ensure any site customizations to product content stored in VCS have been made per [Perform manual product configuration operations](#perform-manual-product-configuration-operations) to ensure CFS configurations
and images are created with the correct content and configuration values.

### Execute the IUF `update-cfs-config` and `prepare-images` stages

**`NOTE`** Additional arguments are available to control the behavior of the `update-cfs-config` and `prepare-images` stages, for example `-bc`, `-bm`, and `-rv`. See the [`update-cfs-config` stage
documentation](../stages/update_cfs_config.md) and the [`prepare-images` stage documentation](../stages/prepare_images.md) for details and adjust the examples below if necessary.

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `update-cfs-config` or
`prepare-images` stages.

1. Invoke `iuf run` with `-r` to execute the [`update-cfs-config`](../stages/update_cfs_config.md) and [`prepare-images`](../stages/prepare_images.md) stages. Use site variables from the `site_vars.yaml` file found in
`${ADMIN_DIR}`, recipe variables from the `product_vars.yaml` file found in `${ADMIN_DIR}`, and `sat bootprep` input files found in `${ADMIN_DIR}`.

    (`ncn-m001#`) Execute the `update-cfs-config` and `prepare-images` stages.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" --bpcd "${ADMIN_DIR}" -r update-cfs-config prepare-images
    ```

1. Inspect the newly-created management NCN and managed node images, CFS configurations, and BOS session templates to ensure they are correct before continuing with the next steps of the workflow. The artifacts can be identified
by examining the Kubernetes ConfigMap associated with the activity. See the `prepare-images` [Artifacts created](../stages/prepare_images.md#artifacts-created) section for instructions and examples.

Once this step has completed:

- New CFS configurations have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New images have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New BOS session templates have been created to boot managed compute and application (UAN, etc.) nodes with the new images and CFS configurations
- Per-stage product hooks have executed for the `update-cfs-config` and `prepare-images` stages

### Manually prepare additional images

#### UAI images

If User Access Instances are utilized on the system, refer to one of the following documents for details on how to build updated UAI images with new product content.

- If CPE is installed on the system, refer to the "Enable CPE in UAIs" section of _HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems_. This procedure will create new UAI images based on the new product
  content installed, including CPE.
- If CPE is not installed on the system, refer to [Custom End-User UAI Images](../../UAS_user_and_admin_topics/Customize_End-User_UAI_Images.md). This procedure will create new UAI images based on the new product content
  installed, but will not include CPE content.

Once this step has completed:

- New UAI images have been created

## Backup

**`NOTE`** This section is only relevant for upgrade workflows. Skip to the [next section](#management-rollout) if performing an initial install.

This section describes procedures that backup critical state in case it becomes necessary to fall back to previous configurations and software.

### Slingshot Fabric Manager

It is recommended to create a backup of the Slingshot Fabric Manager prior to proceeding with the workflow. Refer to the "Backup and Restore Operation of Fabric Configuration" section in the _Slingshot Operations Guide for Customers_
for details on how to perform this operation.

Once this step has completed:

- Slingshot Fabric Manager content has been backed up

## Management rollout

This section updates the software running on management NCNs.

### Execute the IUF `deploy-product` and `post-install-service-check` stages

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `deploy-product` or
`post-install-service-check` stages.

1. Invoke `iuf run` with `-r` to execute the [`deploy-product`](../stages/deploy_product.md) and [`post-install-service-check`](../stages/post_install_service_check.md) stages.

    (`ncn-m001#`) Execute the `deploy-product` and `post-install-service-check` stages.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r deploy-product post-install-service-check
    ```

Once this step has completed:

- New versions of product microservices have been deployed
- Validation scripts have executed to verify the health of the product microservices
- Per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

### Manual configuration of the Slingshot Fabric Manager

**`NOTE`** This section is only relevant for initial install workflows. Skip to the [next section](#perform-slingshot-switch-firmware-updates) if performing an upgrade.

Instructions to configure the Slingshot Fabric Manager are provided in the "Slingshot Installation in a Kubernetes Orchestrated Container Environment" section of the _Slingshot Operations Guide for Customers_. Follow all
subsections beginning with "Configure Fabric Manager" and ending with "Verify Fabric Manager version".

For systems with Slingshot NICs, also follow the instructions in the "Fabric Configuration for Slingshot NICs" section.

Once this step has completed:

- The Slingshot Fabric Manager is configured

### Perform Slingshot switch firmware updates

Instructions to perform Slingshot switch firmware updates are provided in the "Upgrade Slingshot Switch Firmware on HPE Cray EX" section of the  _Slingshot Operations Guide for Customers_.

Once this step has completed:

- Slingshot switch firmware has been updated

### Update management host firmware (FAS)

Refer to [Update Firmware with FAS](../../firmware/Update_Firmware_with_FAS.md) for details on how to upgrade the firmware on management nodes.

Once this step has completed:

- Host firmware has been updated on management nodes

### Execute the IUF `management-nodes-rollout` stage

This section describes how to update software on management nodes. It describes how to test a new image and CFS configuration on a single "canary node" first before rolling it out to the other management nodes. Modify the procedure
as necessary to accommodate site preferences for rebuilding management nodes. The images and CFS configurations used are created by the `prepare-images` and `update-cfs-config` stages respectively; see the `prepare-images`
[Artifacts created](../stages/prepare_images.md#artifacts-created) section for details on how to query the images and CFS configurations and [update-cfs-config](../stages/update_cfs_config.md) section for details about how the CFS configuration is updated.

**`NOTE`** Additional arguments are available to control the behavior of the `management-nodes-rollout` stage, for example `--limit-management-rollout` and `-cmrp`. See the
[`management-nodes-rollout` stage documentation](../stages/management_nodes_rollout.md) for details and adjust the examples below if necessary.

**`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN worker nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI,
remember to include these workflows.

#### NCN worker nodes

NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow. This section describes how to test a new image and CFS configuration on a single "canary node" first before
rolling it out to the other NCN worker nodes. Modify the procedure as necessary to accommodate site preferences for rebuilding NCN worker nodes. Since the default node target for the `management-nodes-rollout` is `Management_Worker`
nodes, the `--limit-management-rollout` argument is not used in the instructions below.

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `management-nodes-rollout` stage.

1. Use `kubectl` to label all NCN worker nodes but one with `iuf-prevent-rollout=true` to ensure `management-nodes-rollout` only rebuilds a single NCN worker node. This node is referred to as the "canary node" in the remainder of
this section.

    (`ncn-m001#`) Label a NCN to prevent it from rebuilding. Replace the example value of `${XNAME}` with the appropriate value. **Repeat this step for all but one NCN worker node (the canary node).**

    ```bash
    XNAME=x3000c0s29b1n0
    kubectl label node "${XNAME}" --overwrite iuf-prevent-rollout=true
    ```

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on the unlabeled canary node. This will rebuild the canary node with the new CFS configuration and image built in
previous steps of the workflow.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from all NCN worker nodes and apply it to the canary node to prevent it from unnecessarily rebuilding again.

    (`ncn-m001#`) Remove a label from a NCN to allow it to rebuild. Replace the example value of `${XNAME}` with the appropriate value. **Repeat this step for all NCN worker nodes except for the canary node.**

    ```bash
    XNAME=x3000c0s29b1n0
    kubectl label node "${XNAME}" --overwrite iuf-prevent-rollout-
    ```

    (`ncn-m001#`) Label the canary node to prevent it from rebuilding. Replace the example value of `${XNAME}` with the xname of the canary node.

    ```bash
    XNAME=x3000c0s29b1n0
    kubectl label node "${XNAME}" --overwrite iuf-prevent-rollout=true
    ```

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on all remaining NCN worker nodes. This will rebuild the nodes with the new CFS configuration and
image built in previous steps of the workflow.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker and master nodes.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node. Replace the example value of `${XNAME}` with the xname of the canary node.

    ```bash
    XNAME=x3000c0s29b1n0
    kubectl label node "${XNAME}" --overwrite iuf-prevent-rollout-
    ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

#### NCN master nodes

Unlike NCN worker nodes, NCN master nodes do not contain kernel module content from non-CSM products. However, userspace non-CSM product content is still provided on NCN master nodes and thus the `prepare-images` and `update-cfs-config` stages create a
new image and CFS configuration for NCN master nodes. The CFS configuration layers ensure the non-CSM product content is applied correctly for both image customization and node personalization scenarios. As a result, the administrator
can decide how to apply the new content to the NCN master nodes by following **one** of the following procedures:

1. Rebuild the NCN master nodes (rebooting to the new image and CFS configuration)

   If this procedure is used, follow the procedure documented in [NCN worker nodes](#ncn-worker-nodes) to rebuild the master nodes. For all invocations of `iuf run -r management-nodes-rollout`, also specify
   `--limit-management-rollout Management_Master` to limit the rebuild operations to the NCN master nodes.

   **`NOTE`** the `management-nodes-rollout` stage currently does not rebuild `ncn-m001`. Follow the instructions in [Stage 2.3 - `ncn-m001` upgrade](../../../upgrade/Stage_2.md#stage-23---ncn-m001-upgrade) to rebuild `ncn-m001` outside of IUF.

1. Update the CFS configuration (applying the new CFS configuration to the existing node without rebuilding)

   If this procedure is used, update the CFS configuration for all of the NCN master nodes by following the instructions documented in
   [Update a CFS Configuration](../../configuration_management/Update_a_CFS_Configuration.md#update-a-cfs-configuration).

Once this step has completed:

- Management NCN master nodes have either been rebuilt with the image and CFS configuration created in previous steps of this workflow or have had their CFS configuration updated to the CFS configuration created in previous steps
  of this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage if the master nodes were rebuilt

#### NCN storage nodes

Unlike NCN worker nodes, NCN storage nodes do not contain kernel module content from non-CSM products. However, userspace non-CSM product content is still provided on NCN storage nodes and thus the `prepare-images` and `update-cfs-config` stages create a
new image and CFS configuration for NCN storage nodes. The CFS configuration layers ensure the non-CSM product content is applied correctly for both image customization and node personalization scenarios. As a result, the administrator
can decide how to apply the new content to the NCN storage nodes by following **one** of the following procedures:

  1. APPLY CFS CONFIGURATION --- TODO

  1. IUF currently does not manage the rebuild or NCN storage nodes. NCN storage nodes can be rebuilt manually into the new image by setting the CFS configuration and rebuilding the NCN storage nodes.
      1. TODO set CFS CONFIG and IMAGE
      1. Follow the instructions for manually rebuilding NCN storage nodes starting at [Prepare Storage Nodes](../../node_management/Rebuild_NCNs/Prepare_Storage_Nodes.md).

Once this step has completed:

- All management NCN storage nodes have either been rebuilt with the image and CFS configuration created in previous steps of this workflow or have had their CFS configuration updated to the CFS configuration created in previous steps
  of this workflow

### Update management host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the  _Slingshot Operations Guide for Customers_ for details on how to update NIC firmware on management nodes.

Once this step has completed:

- New versions of product microservices have been deployed
- Service checks have been run to verify product microservices are executing as expected
- Per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

## Managed rollout

This section updates the software running on managed compute and application (UAN, etc.) nodes.

### Update managed host firmware (FAS)

Refer to [Update Firmware with FAS](../../firmware/Update_Firmware_with_FAS.md) for details on how to upgrade the firmware on managed nodes.

Once this step has completed:

- Host firmware has been updated on managed nodes

### Execute the IUF `managed-nodes-rollout` stage

This section describes how to update software on managed nodes. It describes how to test a new image and CFS configuration on a single "canary node" first before rolling it out to the other managed nodes. Modify the procedure
as necessary to accommodate site preferences for rebooting managed nodes. If the system has heterogeneous nodes, it may be desirable to repeat this process with multiple canary nodes, one for each distinct node configuration.
The images, CFS configurations, and BOS session templates used are created by the `prepare-images` stage; see the `prepare-images` [Artifacts created](../stages/prepare_images.md#artifacts-created) section for details on how to query the
images and CFS configurations.

**`NOTE`** Additional arguments are available to control the behavior of the `managed-nodes-rollout` stage. See the [`managed-nodes-rollout` stage documentation](../stages/managed_nodes_rollout.md) for details and adjust the
examples below if necessary.

#### Compute nodes

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `managed-nodes-rollout` stage.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage on a single node to ensure the node reboots successfully with the desired image and CFS configuration. This node is
referred to as the "canary node" in the remainder of this section. Use `--limit-managed-rollout` to target the canary node only and use `-mrs reboot` to reboot the canary node immediately.

    (`ncn-m001#`) Execute the `managed-nodes-rollout` stage with a single xname, rebooting the canary node immediately. Replace the example value of `${XNAME}` with the xname of the canary node.

    ```bash
    XNAME=x3000c0s29b1n0
    iuf -a "${ACTIVITY_NAME}" -r managed-nodes-rollout --limit-managed-rollout "${XNAME}" -mrs reboot
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage on all nodes, rebooting the nodes in the default staged manner in conjunction with the workload manager.

    (`ncn-m001#`) Execute the `managed-nodes-rollout` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -r managed-nodes-rollout
    ```

Once this step has completed:

- Managed compute nodes have been rebooted to the images and CFS configurations created in previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage

#### Application nodes

Since applications nodes are not managed by workload managers, the IUF `managed-nodes-rollout` stage cannot reboot them in a controlled manner via the `-mrs stage` argument. The IUF `managed-nodes-rollout` stage can reboot application
nodes using the `-mrs reboot` argument, but an immediate reboot of application nodes is likely to be disruptive to users and overall system health and is not recommended. Administrators should determine the best approach for rebooting
application nodes outside of IUF that aligns with site preferences.

Once this step has completed:

- Managed application (UAN, etc.) nodes have been rebooted to the images and CFS configurations created in previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if IUF `managed-nodes-rollout` procedures were used to perform the reboots

### Update managed host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the  _Slingshot Operations Guide for Customers_ for details on how to update NIC firmware on managed nodes.

Once this step has completed:

- Slingshot NIC firmware has been updated on managed nodes

### Execute the IUF `post-install-check` stage

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `post-install-check` stage.

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage.

    (`ncn-m001#`) Execute the `post-install-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r post-install-check
    ```

Once this step has completed:

- Per-stage product hooks have executed for the `post-install-check` stage to verify product software is executing as expected

## Conclusion

The install/upgrade workflow is now complete. Exit the typescript session started at the beginning of the procedure.

(`ncn-m001#`) Exit the typescript session.

```bash
exit
```
