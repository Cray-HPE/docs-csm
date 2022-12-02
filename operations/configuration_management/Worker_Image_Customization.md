# Worker Image Customization

- [Background](#background)
- [Prerequisites](#prerequisites)
- [Procedure](#procedure)

## Background

NCN image customization refers to the process of CFS applying a configuration directly to an NCN image.
During CSM installs and upgrades[^1], NCN image customization must be performed on the NCN worker node image, and the worker NCNs must
then be configured to boot from the customized image. The purpose is to ensure that the appropriate CFS layers are applied
to the NCN worker image before the workers are booted.

[^1]: Except for CSM-only installs and upgrades, which are very rare in production environments. If CSM is the only product
on the system, then this procedure is not performed.

## Prerequisites

All of the following are prerequisites on the node where this procedure is being performed.

- SAT must be configured and authenticated.
  - See [SAT documentation](../sat/sat_in_csm.md#sat-documentation).
- The Cray CLI must be configured and authenticated.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation RPM must be installed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-m#`) Back up the current CFS state.

    For the CSM 1.3 release, the NCN image customization configuration is named `ncn-image-customization`.
    If a CFS configuration with this name already exists, the procedure on this page will overwrite it.

    Because this procedure will create/update a CFS configuration, take a snapshot of the current state of CFS.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/backup_cfs_config_comp.sh --cnfg-only
    ```

1. Gather a copy of the `sat bootprep` files.

    This procedure uses the default `sat bootprep` files from the `hpc-csm-software-recipe` repository in VCS.

    See [Accessing `sat bootprep` Files](Accessing_Sat_Bootprep_Files.md).

1. (`ncn-m#`) Create a local copy of the `management-bootprep.yaml` file.

    ```bash
    cp management-bootprep.yaml management-bootprep-image-customization.yaml
    ```

1. (`ncn-m#`) Delete the `ncn-personalization` configuration in the `management-bootprep-image-customization.yaml` file.

    After editing, the `ncn-image-customization` configuration should be the only entry remaining in the file, and
    the file should begin with the following lines:

    ```yaml
    # (C) Copyright 2022 Hewlett Packard Enterprise Development LP
    ---
    schema_version: 1.0.2
    configurations:
    - name: ncn-image-customization
    ```

1. (`ncn-m#`) Create the `ncn-image-customization` CFS configuration.

    Run `sat bootprep` against the `management-bootprep-image-customization.yaml` file to create the CFS configuration that will be used for image customization on the worker NCN image.

    ```bash
    sat bootprep run management-bootprep-image-customization.yaml
    ```

1. Customize the worker NCN image and update BSS to use the new image.

    Perform the steps in [Management Node Image Customization](Management_Node_Image_Customization.md), with the following notes:

    - The linked procedure gives examples of customizing a Kubernetes NCN image, which is what needs to be done in this case.
    - In the steps to identify the NCN image and obtain its artifacts, do the following based on the current scenario:
      - (`ncn-m001#`) If doing this as part of a CSM upgrade, then use the following command to set the `NCN_IMS_IMAGE_ID` variable.

          ```bash
          NCN_IMS_IMAGE_ID=$(grep "^export K8S_IMS_IMAGE_ID=" /etc/cray/upgrade/csm/myenv | tail -1 | cut -d= -f2)
          echo "${NCN_IMS_IMAGE_ID}"
          ```

      - Otherwise, follow the instructions in the linked procedure to identify the currently booted image for one of the worker NCNs.
    - Skip the steps in the linked procedure to create the CFS configuration, because the CFS configuration was already created in the previous step.
    - When creating the CFS session to customize the image, use the `ncn-image-customization` CFS configuration created earlier in this procedure.
    - When updating the boot parameters, update them for every NCN worker node in the system.

1. (`ncn-m#`) Optionally, delete `management-bootprep-image-customization.yaml`, which is no longer needed.

    ```bash
    rm management-bootprep-image-customization.yaml
    ```
