# NCN Node Personalization

When performing an upgrade or fresh install, NCN node personalization must be performed on the NCN management nodes to ensure the appropriate CFS layers are applied post-boot.
This step involves configuring CFS to use the default `sat bootprep` files from the `hpc-csm-software-recipe` repository and applying the resulting configuration to the NCN management nodes.

The definition of the CFS configuration used for node personalization is provided in the `hpc-csm-software-recipe` repository in VCS.
The following procedure describes how to correctly edit the `sat bootprep` files to be able to use them to perform node personalization.

1. (`ncn-m#`) Perform the steps in the [Accessing `sat bootprep` Files](Accessing_Sat_Bootprep_Files.md) procedure to gather a copy of the `sat bootprep` files.

1. (`ncn-m#`) Create a local copy of the `management-bootprep.yaml` file and delete the `ncn-image-customization` configuration. The `ncn-personalization` configuration should be the only entry remaining in the file if completed correctly.

    ```bash
    cp management-bootprep.yaml management-bootprep-node-personalization.yaml
    vi management-bootprep-node-personalization.yaml
    ```

    Edit the `management-bootprep-node-personalization.yaml` file to delete the `ncn-image-customization` configuration definition, leaving only the node personalization section.

    Verify the content now starts with just the `ncn-personalization` section.

    ```yaml
    # (C) Copyright 2022 Hewlett Packard Enterprise Development LP
    ---
    schema_version: 1.0.2
    configurations:
    - name: ncn-personalization
    ```

1. In the case of an upgrade, execute the following two substeps:

    1. (`ncn-m#`) Acquire a copy of the current CPE and Analytics products CFS configuration values already in use.
     Obtain the values for the `cloneUrl`, `commit`, and `playbook` lines for each of those two layers in the next step to ensure that they are personalized with the desired configuration for CPE and Analytics.

        ```bash
        cray cfs components describe <ncn-xname> --format json
        ```

    1. (`ncn-m#`) Edit the `management-bootprep-node-personalization.yaml` file to replace the CPE and Analytics layers with the playbook, commit hash, and product values already in use on the NCNs for CPE and Analytics.
    This must be done because the new versions of CPE and Analytics have not yet been installed at this time in the upgrade procedure.

1. (`ncn-m#`) Run `sat bootprep` against the `management-bootprep-node-personalization.yaml` file to create the CFS configuration that will be used for node personalization on management NCNs.

    ```bash
    sat bootprep run management-bootprep-node-personalization.yaml
    ```
