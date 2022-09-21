# Worker Upgrade Node Personalization

When performing an upgrade, NCN image customization must be performed with the NCN worker node image to ensure the appropriate CFS layers are applied.
 This step involves configuring CFS to use the default SAT `bootprep` files from the `hpc-csm-software-recipe` repository, and rebuilding the NCN worker nodes so they boot the newly customized image.

The definition of the CFS configuration used for NCN worker node personalization is provided in the `hpc-csm-software-recipe` repository in VCS.
 The following procedure describes how to correctly edit the SAT `bootprep` files to be able to use them to perform node personalization.

1. (`ncn-m#`) Perform the steps in the [Accessing SAT `Bootprep` Files](Accessing_Sat_Bootprep_Files.md) procedure to gather a copy of the SAT `Bootprep` files.

1. (`ncn-m#`) Create a local copy of the `management-bootprep-yaml` file and delete the `ncn-image-customization` configuration. The `ncn-personalization` configuration should  be the only entry remaining in the file if completed correctly.

    ```bash
    cp management-bootprep.yaml management-bootprep-node-personalization.yaml
    vi management-bootprep-node-personalization.yaml
    ```

    Edit the `management-bootprep-node-personalization.yaml` file to delete the `ncn-image-customization` configuration definition, leaving only the node personalization section.

    Verify the content now starts with just the `ncn-personalization` section.

    ```bash
    # (C) Copyright 2022 Hewlett Packard Enterprise Development LP
    ---
    schema_version: 1.0.2
    configurations:
    - name: ncn-personalization
    ```

1. (`ncn-m#`) Use the `management-bootprep-node-personalization.yaml` file as input when customizing the new NCN worker node image with CFS in the CSM documentation.

1. (`ncn-m#`) Acquire a copy of the current CPE and Analytics products CFS configuration values already in use.
 Obtain the values for the `cloneUrl`, `commit`, and `playbook` lines for each of those two layers in the next step to ensure that when the nodes boot later during upgrade, they come up with the desired configuration for CPE and Analytics.

    ```bash
    cray cfs components describe <ncn-xname> --format json
    ```

1. (`ncn-m#`) Edit the `management-bootprep-node-personalization.yaml` file to replace the CPE and Analytics layer with the playbook, commit hash, and product values already in use on the NCNs for CPE.
This must be done because the new version of CPE and Analytics has not yet been installed at this time in the upgrade procedure.

1. (`ncn-m#`) Run `sat bootprep` against the `management-bootprep-node-personalization.yaml` file to create the CFS configuration that will be used for node personalization on worker NCN.

    ```bash
    sat bootprep run `management-bootprep-node-personalization.yaml`
    ```
