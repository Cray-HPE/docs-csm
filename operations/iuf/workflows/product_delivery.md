# Product Delivery

This section ensures the product content is loaded onto the system and available for later steps in the workflow.

1. [Configure optional CSM features](#1-configure-optional-csm-features)
1. [Execute the IUF `process-media` and `pre-install-check` stages](#2-execute-the-iuf-process-media-and-pre-install-check-stages)
1. [Update `customizations.yaml`](#3-update-customizationsyaml)
1. [Populate admin directory with files defining site preference](#4-populate-admin-directory-with-files-defining-site-preferences)
1. [Execute the IUF `deliver-product` stage](#5-execute-the-iuf-deliver-product-stage)
1. [Perform manual product delivery operations](#6-perform-manual-product-delivery-operations)
1. [Next steps](#7-next-steps)

## 1. Configure optional CSM features

> If this IUF procedure is not part of an upgrade from CSM 1.6 to CSM 1.7, then this section should be skipped.

### Rack Resiliency

> If this IUF procedure is not part of an upgrade from CSM 1.6 to CSM 1.7, then this section should be skipped.

Rack Resiliency is new in CSM 1.7. It is disabled by default and it
**cannot change between enabled and disabled later**. Administrators are advised to
take time to determine whether or not they wish to use this feature. See
[Rack Resiliency](../../rack_resiliency/README.md) for details.

If an administrator does not wish to enable the Rack Resiliency feature, then the
rest of this section can be skipped. Otherwise, follow these steps to enable
(and optionally customize) Rack Resiliency.

1. (`ncn-mw#`) Retrieve the `customizations.yaml` file.

    ```bash
    TMPDIR=$(mktemp -d -p ~) &&
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' \
        | base64 -d > "${TMPDIR}/customizations.yaml" \
        && echo "${TMPDIR}/customizations.yaml"
    ```

    Example output:

    ```text
    /root/tmp.iM4FrDrJEJ/customizations.yaml
    ```

1. (`ncn-mw#`) Enable the feature in `customizations.yaml`.

    ```bash
    yq write -i "${TMPDIR}/customizations.yaml" \
        'spec.kubernetes.services.rack-resiliency.enabled' "true"
    ```

1. (`ncn-mw#`) Optionally, set custom zone name prefixes.

    See [Zone names](../../rack_resiliency/Zones.md#zone-names) for details
    on reasons for doing this and restrictions on names. This is optional; prefixes are not
    required. However, **prefixes cannot be changed, set, or removed later**.

    1. Optionally, set a site-specific [Kubernetes zone](../../rack_resiliency/Zones.md#kubernetes-zones) prefix.

        > In the following command, replace `k8s-prefix-string` with the desired Kubernetes zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.k8s_zone_prefix' "k8s-prefix-string"
        ```

    1. Optionally, set a site-specific [Ceph zone](../../rack_resiliency/Zones.md#ceph-zones) prefix.

        > In the following command, replace `ceph-prefix-string` with the desired Ceph zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.ceph_zone_prefix' "ceph-prefix-string"
        ```

1. (`ncn-mw#`) Update the `site-init` secret in the Kubernetes cluster.

    ```bash
    kubectl delete secret -n loftsman site-init \
        && kubectl create secret -n loftsman generic site-init \
            --from-file="${TMPDIR}/customizations.yaml"
    ```

    Expected output:

    ```text
    secret/site-init created
    ```

1. (`ncn-mw#`) Confirm that the fields are set to the desired values.

    ```bash
    kubectl get secrets -n loftsman site-init \
        -o jsonpath='{.data.customizations\.yaml}' \
        | base64 -d | yq r - 'spec.kubernetes.services.rack-resiliency'
    ```

    Example output (in a case where only the Ceph zone prefix was set):

    ```yaml
    enabled: true
    ceph_zone_prefix: my-ceph-prefix
    ```

## 2. Execute the IUF `process-media` and `pre-install-check` stages

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `process-media` or `pre-install-check` stages.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Run `upload-rebuild-templates.sh` to update all the workflows that will be used by IUF and to make sure the workflow templates are the latest versions.

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

> **`IMPORTANT`*** If upgrading CSM manually, ensure that the `docs-csm-latest.noarch.rpm` and `libcsm-latest.noarch.rpm` RPMs are available at path `/root/<rpm>` before executing the above command.

Once this step has completed:

- Product content has been extracted from the product distribution files in `${MEDIA_DIR}`
- Pre-install checks have been performed for CSM and all products found in `${MEDIA_DIR}`
- Per-stage product hooks have executed for the `process-media` and `pre-install-check` stages

## 3. Update `customizations.yaml`

**`NOTE`** This subsection is optional and can be skipped if upgrading only CSM through IUF.

Some products require modifications to the `customizations.yaml` file before executing the `deliver-product` stage. Currently, this is limited to the Slurm and PBS Workload Manager (WLM) products, CSM Diags, and the UAN product. Refer to the
"Install and Upgrade Framework" section of the Slurm, PBS, CSM Diags, and UAN product documents to determine the actions that need to be performed to update `customizations.yaml`.

Once this step has completed:

- The `customizations.yaml` file has been updated per product documentation.

## 4. Populate admin directory with files defining site preferences

For creating `site_vars.yaml` in admin directory, refer to [Populate admin directory with files defining site preferences](admin_directory.md).

## 5. Execute the IUF `deliver-product` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `deliver-product` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-r` to execute the [`deliver-product`](../stages/deliver_product.md) stage. Perform the upgrade using product content found in `${MEDIA_DIR}`.
   Additional arguments are available to control the behavior of the `deliver-product` stage (for example, `-rv`). See the [`deliver-product` stage documentation](../stages/deliver_product.md)
   for details and adjust the example below if necessary.

     **`NOTE`** When installing USS 1.1 or higher, select either Slurm or PBS Pro Products to use on the system before running this stage. This should be specified in `site_vars.yaml`.
     For more information, see the `deliver-product` stage details in the "Install and Upgrade Framework" section of the _HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray Supercomputing EX Systems (S-8063)_.

      (`ncn-m001#`) Execute the `deliver-product` stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml` file found in `${ADMIN_DIR}`.

      ```bash
      iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run --site-vars \
      "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r deliver-product
      ```

1. Run `upload-rebuild-templates.sh` to ensure the correct CSM product versions will be used by IUF now that all product artifacts have been uploaded.

    (`ncn-m001#`) Execute the `upload-rebuild-templates.sh` script.

    ```bash
    /usr/share/doc/csm/workflows/scripts/upload-rebuild-templates.sh
    ```

Once this step has completed:

- Product content for all products found in `${MEDIA_DIR}` has been uploaded to the system
- Product content uploaded to the system has been recorded in the product catalog
- Per-stage product hooks have executed for the `deliver-product` stage

## 6. Perform manual product delivery operations

**`NOTE`** This subsection is optional and can be skipped if upgrading only CSM through IUF.

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

## 7. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.
