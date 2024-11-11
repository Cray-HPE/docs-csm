# Configuration

This section ensures product configuration has been defined, customized, and is available for later steps in the workflow.

- [1. Execute the IUF `update-vcs-config` stage](#1-execute-the-iuf-update-vcs-config-stage)
    - [1.1 Prerequisites](#11-prerequisites)
    - [1.2 Procedure](#12-procedure)
- [2. Perform manual product configuration operations](#2-perform-manual-product-configuration-operations)
- [3. Next steps](#3-next-steps)

## 1. Execute the IUF `update-vcs-config` stage

For each product that uploaded Ansible configuration content to a configuration management VCS repository, the `update-vcs-config` stage attempts to merge the pristine branch of the configuration management repository into a
corresponding customer working branch.

### 1.1 Prerequisites

- Understand the default branching scheme defined in `product_vars.yaml`, which is typically `integration-<x.y.z>`. Details are provided in the [update-vcs-config stage documentation](../stages/update_vcs_config.md).
- Create and configure `site_vars.yaml` to properly define the **customer** branching strategy as well as any needed product-specific overrides and provide it as an argument when invoking `iuf run`.
- If the default branching scheme described above does not match the customer branching scheme used, use `git` to perform a manual migration of VCS content to the default branching scheme before running the `update-vcs-config` stage.

    For example, if the customer branch `integration` was previously used with the `slingshot-host-software-2.0.0` release and `slingshot-host-software-2.0.2` is now being installed with the default `integration-<x.y.z>` branching
    scheme, create the branch that IUF expects from the current `integration` branch in the `slingshot-host-software-config-management` repository:

    (`ncn-m001#`) Create an `integration-2.0.0` branch from `integration` to align with IUF expectations

    ```bash
    ncn-m001:/mnt/admin/cfg/slingshot-host-software-config-management# git checkout integration
    ncn-m001:/mnt/admin/cfg/slingshot-host-software-config-management# git pull
    ncn-m001:/mnt/admin/cfg/slingshot-host-software-config-management# git branch integration-2.0.0
    ncn-m001:/mnt/admin/cfg/slingshot-host-software-config-management# git checkout integration-2.0.0
    ncn-m001:/mnt/admin/cfg/slingshot-host-software-config-management# git push
    ```

    When the `update-vcs-config` stage is run, IUF will now use the `integration-2.0.0` branch as the starting point for merging because it adheres to the expected branching scheme.

- If there are workarounds checked into VCS that modify the HPE-provided Ansible plays or roles and the workarounds are no longer needed in the new version of software being upgraded to, it is beneficial to revert the workarounds
  prior to running the `update-vcs-config` stage to avoid merge conflicts.

    For example, if the following workaround was present in the Slurm `integration-1.2.9` branch:

    ```bash
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git checkout integration-1.2.9
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git log
    commit 133d5fc815aafd502d3aca07961524e4f9eab445 (origin/integration-1.2.9, integration-1.2.9)
    Author: Joe Smith <joe.smith@example.com>
    Date:   Fri Mar 3 19:26:53 2023 +0000

    Workaround for bug #234232
    ```

    ... and an upgrade to Slurm `integration-1.2.10` is being performed, then a new working branch should be created and the workaround should be reverted from the new branch:

    ```bash
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git branch integration-1.2.10
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git checkout integration-1.2.10
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git revert 133d5fc815aafd502d3aca07961524e4f9eab445
    ncn-m001:/mnt/admin/cfg/slurm-config-management# git push
    ```

    When the `update-vcs-config` stage is run, IUF will now use the `integration-1.2.10` branch, and the merge conflict that would have occurred will be avoided as the workaround was reverted.

### 1.2 Procedure

**`NOTE`** Additional arguments are available to control the behavior of the `update-vcs-config` stage, for example `-rv`. See the [`update-vcs-config` stage
documentation](../stages/update_vcs_config.md) for details and adjust the examples below if necessary.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `update-vcs-config` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with `-r` to execute the [`update-vcs-config`](../stages/update_vcs_config.md) stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml`
file found in `${ADMIN_DIR}`.

    (`ncn-m001#`) Execute the `update-vcs-config` stage.

    ```bash
    iuf -a ${ACTIVITY_NAME} run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r update-vcs-config
    ```

Once this step has completed:

- Product configuration content has been merged to VCS branches as described in the [update-vcs-config stage documentation](../stages/update_vcs_config.md)
- Per-stage product hooks have executed for the `update-vcs-config` stage

## 2. Perform manual product configuration operations

Some products must be manually configured prior to the creation of CFS configurations and images. The "Install and Upgrade Framework" section of each individual product's installation documentation contains instructions for product-specific
configuration, if any. Major changes may also be documented in the _HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray EX Systems_.
The following highlights some of the areas that require manual configuration changes **but is not intended to be a comprehensive list.** Note that many of the configuration changes are only
required for initial installation scenarios.

- USS
    - Configure DVS and LNet with appropriate Slingshot settings
    - Configure DVS and LNet for use on application nodes
    - Enable site-specific file system mounts
    - Set the USS root password in HashiCorp Vault
- UAN
    - Enable CAN, LDAP, and set MOTD
    - Move DVS and LNet settings to USS branch
    - Set the UAN root password in HashiCorp Vault
- SHS
    - Update release information in `group_vars` (done for each product release)
- CPE
    - Enable previous CPE versions or alternate 3rd party products (optional, done for each product release)
- SDU
    - Configure SDU via `sdu setup`
- SAT
    - Configure SAT authentication via `sat auth`
    - Generate SAT S3 credentials
    - Configure system revision information via `sat setrev`
- SLURM
    - UAS
        - Configure UAS network settings
            - The network settings for UAS must match the SLURM WLM to allow job submission from UAIs
    - CSM Diags
        - Update CSM Diags network attachment definition
- PBS Pro
    - UAS
        - Configure UAS network settings
            - The network settings for UAS must match the PBS Pro WLM to allow job submission from UAIs
    - CSM Diags
        - Update CSM Diags network attachment definition

Once this step has completed:

- Product configuration has been completed

## 3. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.
