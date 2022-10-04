# Worker Upgrade Image Customization

When performing an upgrade, NCN image customization must be performed with the NCN worker node image to ensure the appropriate CFS layers are applied.
This step involves configuring CFS to use the default `sat bootprep` files from the `hpc-csm-software-recipe` repository and rebuilding the NCN worker nodes so they boot the newly customized image.

The definition of the CFS configuration used for NCN worker node image customization is provided in the `hpc-csm-software-recipe` repository in VCS.
The following procedure describes how to correctly edit the `bootprep` files to be able to use them to perform image customization.

1. (`ncn-m#`) Perform the steps in the [Accessing `sat bootprep` Files](Accessing_Sat_Bootprep_Files.md) procedure to gather a copy of the `sat bootprep` files.

1. (`ncn-m#`) Create a local copy of the `management-bootprep.yaml` file and delete the `ncn-personalization` configuration. The `ncn-image-customization` configuration will be the only entry remaining in the file.

    ```bash
    cp management-bootprep.yaml management-bootprep-image-customization.yaml
    vi management-bootprep-image-customization.yaml
    ```

    Edit the `management-bootprep-image-customization.yaml` file to delete the ncn-personalization configuration definition.

    Verify the content now starts with just the image customization section.

    ```bash
    # (C) Copyright 2022 Hewlett Packard Enterprise Development LP
    ---
    schema_version: 1.0.2
    configurations:
    - name: ncn-image-customization
    ```

1. (`ncn-m#`) Run `sat bootprep` against the `management-bootprep-image-customization.yaml` file to create CFS configuration that will be used to customize the worker image.

    ```bash
    sat bootprep run management-bootprep-image-customization.yaml
    ```

1. (`ncn-m#`) Perform the steps in [Management Node Image Customization](Management_Node_Image_Customization.md). Use the CFS configuration created in the previous step when
    customizing the image.
