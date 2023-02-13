# Install or Upgrade All Products Provided in a HPC CSM Software Recipe

The following workflow describes an install or upgrade procedure of all **non-CSM product content** provided with a HPC CSM Software Recipe release. **CSM itself is not installed or upgraded.** All stages of `iuf` are executed:
all of the new product software provided in the recipe release is deployed and all management NCNs and managed compute and application (UAN, etc.) nodes are rebooted to new images and CFS configurations. Manual operations are
documented for procedures that are not currently managed by IUF.

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
- [Backup](#backup)
- [Management nodes rollout](#management-nodes-rollout)
  - [Update management host firmware (FAS)](#update-management-host-firmware-fas)
  - [Execute the IUF `management-nodes-rollout` stage](#execute-the-iuf-management-nodes-rollout-stage)
  - [Execute the IUF `deploy-product` and `post-install-service-check` stages](#execute-the-iuf-deploy-product-and-post-install-service-check-stages)
  - [Manual configuration of the Slingshot fabric manager](#manual-configuration-of-the-slingshot-fabric-manager)
- [Managed nodes rollout](#managed-nodes-rollout)
  - [Perform Slingshot switch firmware updates](#perform-slingshot-switch-firmware-updates)
  - [Execute the IUF `managed-nodes-rollout` stage](#execute-the-iuf-managed-nodes-rollout-stage)
  - [Execute the IUF `post-install-check` stage](#execute-the-iuf-post-install-check-stage)
- [Conclusion](#conclusion)

## Prepare for the install or upgrade

This section defines environment variables and directory content that is used throughout the workflow.

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
    iuf -a "${ACTIVITY_NAME}" activity --create waiting_admin
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
  - **Description:** COS provides the `gpu-nexus-tool` script to upload third-party GPU software to Nexus. The GPU software is used later in the workflow when creating CFS configurations and building compute and application
    node images.
  - **Instructions:** See the "IUF Stage Details for COS" section of the [HPE Cray Operating System Installation Guide CSM on HPE Cray EX Systems (S-8025)](https://www.hpe.com/support/ex-S-8025) for references to the installation
    procedures.
- **Content:** Third-party programming environment software
  - **Description:** CPE provides the `install-3p.sh` script to upload third-party programming environment software to Nexus. The programming environment software is used later in the workflow when creating CPE configurations
    and building CPE images.
  - **Instructions:** See the "CPE Install and Upgrade Framework usage" section of the [HPE CPE Installation Guide CSM on HPE Cray EX Systems (S-8003)](https://www.hpe.com/support/ex-S-8003) for references to the installation
    procedures.

1. Follow instructions to install third-party GPU software.

    ```bash
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "installing third-party GPU content" in_progress
    < perform necessary operations per COS documentation >
    iuf -a "${ACTIVITY_NAME}" activity --create waiting_admin
    ```

1. Follow instructions to install third-party programming environment software.

    ```bash
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "installing third-party programming environment content" in_progress
    < perform necessary operations per CPE documentation >
    iuf -a "${ACTIVITY_NAME}" activity --create waiting_admin
    ```

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

1. Follow the instructions in [Accessing `sat bootprep` Files](#../../configuration_management/Accessing_Sat_Bootprep_Files.md) to check out content from the `hpc-csm-software-recipe` repository and switch to the branch named for the
HPC CSM Software Recipe release being installed/upgraded. When complete, the contents of `${ADMIN_DIR}` should look similar to this:

    (`ncn-m001#`) List contents of `${ADMIN_DIR}`

    ```bash
    ls *
    product_vars.yaml

    bootprep:
    compute-and-uan-bootprep.yaml  management-bootprep.yaml
    ```

1. Edit the `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files to account for any site deviations from the default values. For example:
    - comment out the `shs-mellanox_install-integration-{{shs.version}}` CFS configuration layers and uncomment the `shs-cassini_install-integration-{{shs.version}}` CFS configuration layers
    - uncomment the `gpu-{{recipe.version}}` CFS configuration layer and `gpu-image` image definition
    - etc.

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override the HPE-provided `product_vars.yaml` content. For example:
    - adding a `default` section containing a `network_type: "cassini"` entry to define the desired Slingshot network type used when executing CFS configurations later in the workflow:

        ```bash
        cat site_vars.yaml
        default:
          network_type: "cassini"
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

TBD

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

1. Inspect the newly-created management NCN and managed node images and CFS configurations to ensure they are correct before continuing with the next steps of the workflow.

Once this step has completed:

- New CFS configurations have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New images have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New BOS session templates have been created to boot managed compute and application (UAN, etc.) nodes with the new images and CFS configurations
- Per-stage product hooks have executed for the `update-cfs-config` and `prepare-images` stages

## Backup

This section describes procedures that backup critical state in case it becomes necessary to fall back to previous configurations and software.

TBD

## Management nodes rollout

This section updates the software running on management NCNs.

### Update management host firmware (FAS)

TBD

### Execute the IUF `management-nodes-rollout` stage

**`NOTE`** Additional arguments are available to control the behavior of the `management-nodes-rollout` stage, for example `--limit-management-rollout` and `-cmrp`. See the
[`management-nodes-rollout` stage documentation](../stages/management_nodes_rollout.md) for details and adjust the examples below if necessary.

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `management-nodes-rollout` stage.

1. Use `kubectl` to label all NCN worker nodes but one with `iuf-prevent-rollout=true` to ensure `management-nodes-rollout` only rebuilds a single NCN worker node. This node is referred to as the "canary node" in the remainder of
this section.

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on the canary node. This will rebuild the canary node with the new CFS configurations and images built in
previous steps of the workflow.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from all NCN worker nodes and apply it to the canary node to prevent it from unnecessarily rebuilding again.

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on all remaining NCN worker and master nodes. This will rebuild the nodes with the new CFS configurations and
images built in previous steps of the workflow. All NCN master nodes **except** for `ncn-m001` will be rebuilt. `ncn-m001` and all NCN storage nodes must be rebuilt outside of IUF as documented in a later step.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker and master nodes.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node.

1. Follow the instructions in [Stage 1 - Ceph image upgrade](#../../upgrade/Stage_1.md) to rebuild the NCN storage nodes.

1. Follow the instructions in [Stage 2.3 - `ncn-m001` upgrade](#../../upgrade/Stage_2.md#stage-23---ncn-m001-upgrade) to rebuild `ncn-m001`.

Once this step has completed:

- All management NCN nodes have been rebooted to the images and CFS configurations created in previous steps in this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

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
- Service checks have been run to verify product microservices are executing as expected
- Per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

### Manual configuration of the Slingshot fabric manager

TBD

## Managed nodes rollout

This section updates the software running on managed compute and application (UAN, etc.) nodes.

### Perform Slingshot switch firmware updates

TBD

### Execute the IUF `managed-nodes-rollout` stage

**`NOTE`** Additional arguments are available to control the behavior of the `managed-nodes-rollout` stage. See the [`managed-nodes-rollout` stage documentation](../stages/managed_nodes_rollout.md) for details and adjust the
examples below if necessary.

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

- All managed compute and application (UAN, etc.) nodes have been rebooted to the images and CFS configurations created in previous steps in this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage

### Execute the IUF `post-install-check` stage

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `post-install-check` stage.

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage.

    (`ncn-m001#`) Execute the `post-install-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r post-install-check
    ```

Once this step has completed:

- Per-stage product hooks have executed to verify product software is executing as expected

## Conclusion

The install/upgrade workflow is now complete. Exit the typescript session started at the beginning of the procedure.

(`ncn-m001#`) Exit the typescript session.

```bash
exit
```
