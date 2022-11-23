# NCN Node Personalization

- [Background](#background)
- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
  1. [Preparation](#1-preparation)
  1. [Remove layers for absent products](#2-remove-layers-for-absent-products)
  1. [Edit CPE and Analytics layers](#3-edit-cpe-and-analytics-layers)
  1. [Disable CFS on management NCNs](#4-disable-cfs-on-management-ncns)
  1. [Update CFS configuration and components](#5-update-cfs-configuration-and-components)
  1. [Cleanup](#6-cleanup)

## Background

NCN node personalization refers to the process of CFS applying a configuration to a management NCN after it is booted.
During CSM installs and upgrades[^1], this CFS configuration must be created and set as the desired configuration in CFS for all management NCNs.
The purpose is to ensure that the appropriate CFS layers are applied to the management NCNs after they boot.

[^1]: Except for CSM-only installs and upgrades, which are very rare in production environments. If CSM is the only product
on the system, then this procedure is not performed.

The same CFS configuration is used for post-boot personalization of master, storage, and worker NCNs. However, some individual parts of that
configuration will only be applied to appropriate node types.

## Prerequisites

All of the following are prerequisites on the node where this procedure is being performed.

- SAT must be configured and authenticated.
  - See [SAT documentation](../sat/sat_in_csm.md#sat-documentation).
- The Cray CLI must be configured and authenticated.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation RPM must be installed.
  - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

### 1. Preparation

1. (`ncn-m#`) Back up the current CFS state.

    For the CSM 1.3 release, the NCN personalization configuration is named `ncn-personalization`.
    If a CFS configuration with this name already exists, the procedure on this page will overwrite it.

    Because this procedure will create/update a CFS configuration and modify the CFS components of the management NCNs,
    take a snapshot of the current state of these CFS objects.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/backup_cfs_config_comp.sh
    ```

1. Gather a copy of the `sat bootprep` files.

    This procedure uses the default `sat bootprep` files from the `hpc-csm-software-recipe` repository in VCS.

    See [Accessing `sat bootprep` Files](Accessing_Sat_Bootprep_Files.md).

1. (`ncn-m#`) Create a local copy of the `management-bootprep.yaml` file.

    ```bash
    cp management-bootprep.yaml management-bootprep-node-personalization.yaml
    ```

1. (`ncn-m#`) Delete the `ncn-image-customization` configuration in the `management-bootprep-node-personalization.yaml` file.

    After editing, the `ncn-personalization` configuration should be the only entry remaining in the file, and
    the file should begin with the following lines:

    ```yaml
    # (C) Copyright 2022 Hewlett Packard Enterprise Development LP
    ---
    schema_version: 1.0.2
    configurations:
    - name: ncn-personalization
    ```

### 2. Remove layers for absent products

(`ncn-m#`) Review the layers in `management-bootprep-node-personalization.yaml`. If there are any
layers for products that are not installed on the system, edit the file to remove those layers.
In the case of CSM fresh installs, the `Getting Started Guide` section that linked to this procedure
should indicate which layers to remove and which to preserve.

### 3. Edit CPE and Analytics layers

This section is required if this procedure is being performed as part of a CSM upgrade.
If that is not the case (for example, during CSM fresh installs),
then skip ahead to [Update CFS configuration and components](#5-update-cfs-configuration-and-components).

In this section, the `management-bootprep-node-personalization.yaml` file is modified to specify the versions of CPE and Analytics that
are currently in use on the system. This is necessary because the new versions of CPE and Analytics have not yet been installed at this
time in the CSM upgrade procedure.

1. (`ncn-m#`) Acquire a copy of the current CPE and Analytics products CFS configuration values already in use.

    There are multiple ways to do this. The following is an example of finding these values by looking at the CFS configuration of the worker NCNs on the system.

    1. Find the name of the desired CFS configuration in use by the NCN worker nodes.

        > This code also makes sure that all NCN workers are using the same CFS configuration. If they are not, it will
        > prompt for the `WORKER_CONFIG` variable to be manually set after determining the proper configuration.

        ```bash
        WORKER_CONFIG=$(sat status --filter role=management --filter subrole=worker --fields desiredconfig --format json |
                            jq -r '.[]."Desired Config"' | sort -u)
        if [[ ${WORKER_CONFIG} == *" "* ]]; then
            echo "WARNING: Not all workers using the same CFS configuration. Multiple configurations in use: ${WORKER_CONFIG}"
            echo "Set the WORKER_CONFIG variable to the name of the configuration with the correct CPE and Analytics values."
            WORKER_CONFIG=""
        else
            echo "${WORKER_CONFIG}"
        fi
        ```

        Example output:

        ```text
        ncn-personalization
        ```

    1. Show the CPE and Analytics layers of that configuration.

        ```bash
        cray cfs configurations describe "${WORKER_CONFIG}" --format json | \
            jq -r '.layers[] | select(.cloneUrl | contains("/vcs/cray/cpe-config-management.git") or contains("/vcs/cray/analytics-config-management.git"))'
        ```

        Example output:

        ```json
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cpe-config-management.git",
          "commit": "c38c16bc9a645a9339a8303865e696b089b15e17",
          "name": "cpe-22.09-integration",
          "playbook": "pe_deploy.yml"
        }
        {
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git",
          "commit": "c9c0b2cc69998830a47d7c989b07f550814af095",
          "name": "analytics-integration-1.2.22",
          "playbook": "site.yml"
        }
        ```

1. (`ncn-m#`) Update the CPE and Analytics values in `management-bootprep-node-personalization.yaml`.

    These values will be updated based on the values identified in the final command of the previous step.

    In order to accurately represent the exact configuration already in use for CPE and Analytics, use the `git` key in the `bootprep` layer definition.
    For each of these two layers:

    - Ensure that `commit`, `name`, and `playbook` match the corresponding field values identified in the previous step.
    - Ensure that `url` matches the `cloneUrl` value identified in the previous step.

    The example below shows what the CPE and Analytics layers should look like, based on the earlier example output.

    ```yaml
    - name: cpe-22.09-integration
      playbook: pe_deploy.yml
      git:
        url: https://api-gw-service-nmn.local/vcs/cray/cpe-config-management.git
        commit: c38c16bc9a645a9339a8303865e696b089b15e17
    - name: analytics-integration-1.2.22
      playbook: site.yml
      git:
        url: https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git
        commit: c9c0b2cc69998830a47d7c989b07f550814af095
    ```

### 4. Disable CFS on management NCNs

This section is required if this procedure is being performed as part of a CSM upgrade.
If that is not the case (for example, during CSM fresh installs),
then skip ahead to [Update CFS configuration and components](#5-update-cfs-configuration-and-components).

(`ncn-m#`) Disable CFS on the management NCNs.

```bash
cray hsm state components list --role Management --type Node --format json | jq -r '.Components[] | .ID' | 
    xargs -rI {} cray cfs components update {} --enabled false || echo ERROR
```

If there is no output, or if the output ends with `ERROR`, then there is a problem. In that case, stop and troubleshoot.

### 5. Update CFS configuration and components

1. (`ncn-m#`) Create the `ncn-personalization` CFS configuration.

    Run `sat bootprep` against the `management-bootprep-node-personalization.yaml` file to create the CFS configuration that will be used for node personalization on management NCNs.

    ```bash
    sat bootprep run management-bootprep-node-personalization.yaml
    ```

1. (`ncn-m#`) Set the management NCNs to use the `ncn-personalization` configuration.

    The command to use varies based on whether or not this is being done as part of a CSM upgrade.

    - If this is being done as part of a CSM upgrade, then run the following command:

        > This command deliberately only updates the desired configuration in CFS. It does not
        > enable the NCNs in CFS nor does it clear their CFS states or error counts. All of those
        > things will happen automatically when the NCNs are rebuilt during the CSM upgrade.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
            --no-config-change --config-name ncn-personalization --no-enable --no-clear-err
        ```

        Successful output will end with the following:

        ```text
        All components updated successfully.
        ```

    - If this is NOT being done as part of a CSM upgrade (for example, if being done during a CSM fresh install), then run the following command:

        > In addition to updating the desired configuration for the NCNs in CFS, this also enables them in CFS, clears their CFS
        > state, and clears their CFS error count. After doing this, it waits for all of the management NCNs to complete configuration.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
            --no-config-change --config-name ncn-personalization --clear-state
        ```

        Successful output will end with a message similar to the following:

        ```text
        Configuration complete. 9 component(s) completed successfully.  0 component(s) failed.
        ```

        The number reported should match the number of management NCNs in the system.

### 6. Cleanup

(`ncn-m#`) Optionally, delete `management-bootprep-node-personalization.yaml`, which is no longer needed.

```bash
rm management-bootprep-node-personalization.yaml
```
