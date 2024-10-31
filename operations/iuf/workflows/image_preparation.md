# Image preparation

This section creates CFS configurations and bootable images that will be used by later steps in the workflow.

Before proceeding, ensure any site customizations to product content stored in VCS have been made per [Perform manual product configuration operations](configuration.md#3-perform-manual-product-configuration-operations) to ensure CFS configurations
and images are created with the correct content and configuration values.

- [1. Execute the IUF `update-cfs-config` and `prepare-images` stages](#1-execute-the-iuf-update-cfs-config-and-prepare-images-stages)
- [2. Manually prepare additional images](#2-manually-prepare-additional-images)
    - [2.1 ARM images](#21-arm-images)
- [3. Next steps](#3-next-steps)

## 1. Execute the IUF `update-cfs-config` and `prepare-images` stages

**`NOTE`** Additional arguments are available to control the behavior of the `update-cfs-config` and `prepare-images` stages, for example `-bc`, `-bm`, and `-rv`. See the [`update-cfs-config` stage
documentation](../stages/update_cfs_config.md) and the [`prepare-images` stage documentation](../stages/prepare_images.md) for details and adjust the examples below if necessary.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `update-cfs-config` or `prepare-images` stages.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with `-r` to execute the [`update-cfs-config`](../stages/update_cfs_config.md) and [`prepare-images`](../stages/prepare_images.md) stages. Use site variables from the `site_vars.yaml` file found in
`${ADMIN_DIR}`, recipe variables from the `product_vars.yaml` file found in `${ADMIN_DIR}`, and `sat bootprep` input files found in `${ADMIN_DIR}/bootprep`.

    (`ncn-m001#`) Execute the `update-cfs-config` and `prepare-images` stages.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r update-cfs-config prepare-images
    ```

1. Inspect the newly-created management NCN and managed node images, CFS configurations, and BOS session templates to ensure they are correct before continuing with the next steps of the workflow. The artifacts can be identified
by examining the output from `iuf run` or by examining the Kubernetes ConfigMap associated with the activity. See the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for
instructions and examples.

Once this step has completed:

- New CFS configurations have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New images have been created for management NCNs and managed compute and application (UAN, etc.) nodes
- New BOS session templates have been created to boot managed compute and application (UAN, etc.) nodes with the new images and CFS configurations
- Per-stage product hooks have executed for the `update-cfs-config` and `prepare-images` stages

## 2. Manually prepare additional images

### 2.1 ARM images

If it is necessary to build `aarch64` images, then see [ARM images](../IUF.md#arm-images).

## 3. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.
