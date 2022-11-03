# Worker Image Customization

- [Background](#background)
- [Procedure](#procedure)

## Background

NCN image customization refers to the process of CFS applying a configuration directly to an unbooted NCN image.
During CSM upgrades, NCN image customization must be performed on the NCN worker node image, and the worker NCNs must
then be configured to boot from the customized image. The purpose is to ensure that the appropriate CFS layers are applied
to the NCN worker image before the workers are booted.

## Procedure

1. (`ncn-m#`) Back up the current CFS state.

    For the CSM 1.3 release, the NCN image customization configuration is named `ncn-image-customization`.
    If a CFS configuration with this name already exists, the procedure on this page will overwrite it.

    Because this procedure will create/update a CFS configuration, take a snapshot of the current state of CFS.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/backup_cfs_config_comp.sh
    ```

1. Gather a copy of the `sat bootprep` files.

    This procedure uses the default `sat bootprep` files from the `hpc-csm-software-recipe` repository in VCS.

    See [Accessing `sat bootprep` Files](Accessing_Sat_Bootprep_Files.md).

1. (`ncn-m#`) Create a local copy of the `management-bootprep.yaml` file.

    ```bash
    cp management-bootprep.yaml management-bootprep-image-customization.yaml
    ```

1. (`ncn-m#`) Delete the `ncn-personalization` configuration in the `management-bootprep-node-personalization.yaml` file.

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
    - (`ncn-m001#`) In the steps to identify the NCN image and obtain its artifacts, use the following command to set the `ARTIFACT_VERSION` variable.

        ```bash
        ARTIFACT_VERSION=$(grep "^export KUBERNETES_VERSION=" /etc/cray/upgrade/csm/myenv | tail -1 | cut -d= -f2)
        echo "${ARTIFACT_VERSION}"
        ```

    - Skip the steps in the linked procedure to create the CFS configuration, because the CFS configuration was already created in the previous step.
    - When creating the CFS session to customize the image, use the CFS configuration created in the previous step.
    - When updating the boot parameters, update them for every NCN worker node in the system.

1. (`ncn-m#`) Optionally, delete `management-bootprep-image-customization.yaml`, which is no longer needed.

    ```bash
    rm management-bootprep-image-customization.yaml
    ```
