# Product delivery

This section ensures the product content is loaded onto the system and available for later steps in the workflow.

1. [Execute the IUF `process-media` and `pre-install-check` stages](#1-execute-the-iuf-process-media-and-pre-install-check-stages)
1. [Update `customizations.yaml`](#2-update-customizationsyaml)
1. [Execute the IUF `deliver-product` stage](#3-execute-the-iuf-deliver-product-stage)
1. [Perform manual product delivery operations](#4-perform-manual-product-delivery-operations)
1. [Next steps](#5-next-steps)

## 1. Execute the IUF `process-media` and `pre-install-check` stages

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `process-media` or `pre-install-check` stages.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Run `upload-rebuild-templates.sh` to update all the workflows that will be used by IUF and to ensure the correct CSM product versions will be used by IUF.

    (`ncn-m001#`) Execute the `upload-rebuild-templates.sh` script.

    ```bash
    /usr/share/doc/csm/workflows/scripts/upload-rebuild-templates.sh
    ```

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-e` to execute the [`process-media`](../stages/process_media.md) and [`pre-install-check`](../stages/pre_install_check.md) stages. Perform the upgrade
   using product content found in `${MEDIA_DIR}`.

    (`ncn-m001#`) Execute the `process-media` and `pre-install-check` stages.

    ```bash
    iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run -e pre-install-check
    ```

Once this step has completed:

- Product content has been extracted from the product distribution files in `${MEDIA_DIR}`
- Pre-install checks have been performed for CSM and all products found in `${MEDIA_DIR}`
- Per-stage product hooks have executed for the `process-media` and `pre-install-check` stages

## 2. Update `customizations.yaml`

Some products require modifications to the `customizations.yaml` file before executing the `deliver-product` stage. Currently, this is limited to the Slurm and PBS Workload Manager (WLM) products and the UAN product. Refer to the
"Install and Upgrade Framework" section of the Slurm, PBS, and UAN product documents to determine the actions that need to be performed to update `customizations.yaml`.

Once this step has completed:

- The `customizations.yaml` file has been updated per product documentation.

## 3. Execute the IUF `deliver-product` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `deliver-product` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-r` to execute the [`deliver-product`](../stages/deliver_product.md) stage. Perform the upgrade using product content found in `${MEDIA_DIR}`.

    (`ncn-m001#`) Execute the `deliver-product` stage.

    ```bash
    iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run -r deliver-product
    ```

> **WARNING:** If you are using CSM 1.5.0 (and not CSM 1.5.1+), there is a bug that prevents the `deliver-product` stage from completing on large number of products being delivered. This bug is addressed in the 1.5.0 hotfix titled `CASMINST-6799`.
> You are encouraged to apply that hotfix for 1.5.0 (see [Check for field notices about hotfixes](../../../update_product_stream/index.md#check-for-field-notices-about-hotfixes)).
> If you have not applied the hotfix and you run across this issue, you can abort IUF-CLI and try running the stage again, but this doesn't guarantee that the issue will not happen again as it is a race condition.
> Note again that this does not affect CSM 1.5.1+.  

Once this step has completed:

- Product content for all products found in `${MEDIA_DIR}` has been uploaded to the system
- Product content uploaded to the system has been recorded in the product catalog
- Per-stage product hooks have executed for the `deliver-product` stage

## 4. Perform manual product delivery operations

**`NOTE`** This subsection is optional and can be skipped if third-party GPU and/or programming environment software is not needed.

Some products provide instructions for delivering third-party content to the system outside of IUF. If this content is desired, refer to the following documentation for instructions and execute the procedures before continuing
with the workflow.

- **Content:** Third-party GPU software
    - **Description:** [User Services Software (USS)](../../../glossary.md#user-services-software-uss) provides the `gpu-nexus-tool` script to upload third-party GPU software to Nexus.
    The GPU software is used later in the workflow when creating CFS configurations and building compute and application node images.
    - **Instructions:** See the "IUF Stage Details for USS" section of _HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray EX Systems_ for references to the installation procedures.
- **Content:** Third-party programming environment software
    - **Description:** The Cray Programming Environment (CPE) provides the `install-3p.sh` and `cpe-custom-img.sh` scripts to upload third-party programming environment software to Nexus and build images. The programming environment
    software is used later in the workflow when creating CPE configurations.
    - **Instructions:** See the "CPE Install and Upgrade Framework usage" section of _HPE CPE Installation Guide CSM on HPE Cray EX Systems (S-8003)_ for references to the installation procedures.

Once this step has completed:

- Third-party software has been uploaded to Nexus

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM, return to the
  [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.
