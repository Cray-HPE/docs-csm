# Configuration

This section ensures product configuration has been defined, customized, and is available for later steps in the workflow.

This workflow uses `${ADMIN_DIR}` to retain files that define site preferences for IUF. `${ADMIN_DIR}` is defined separately from `${ACTIVITY_DIR}` and `${MEDIA_DIR}` based on the assumption that the files in `${ADMIN_DIR}` will be
used when performing future IUF operations unrelated to this workflow.

**`NOTE`** The following steps assume `${ADMIN_DIR}` is empty. If this is not the case, i.e. `${ADMIN_DIR}` has been populated by previous IUF workflows, ensure the content in `${ADMIN_DIR}` is up to date with the latest content
provided by the HPC CSM Software Recipe release content being installed. This may involve merging new content provided in the latest branch of the `hpc-csm-software-recipe` repository in VCS or provided in the files extracted from
the HPC CSM Software Recipe with the existing content in `${ADMIN_DIR}`.

- [1. Populate admin directory with files defining site preferences](#1-populate-admin-directory-with-files-defining-site-preferences)
- [2. Execute the IUF `update-vcs-config` stage](#2-execute-the-iuf-update-vcs-config-stage)
    - [2.1 Prerequisites](#21-prerequisites)
    - [2.2 Procedure](#22-procedure)
- [3. Perform manual product configuration operations](#3-perform-manual-product-configuration-operations)
- [4. Next steps](#4-next-steps)

## 1. Populate admin directory with files defining site preferences

1. Change directory to `${ADMIN_DIR}`

    (`ncn-m001#`) Change directory

    ```bash
    cd ${ADMIN_DIR}
    ```

1. Copy the `sat bootprep` and `product_vars.yaml` files from the uncompressed HPC CSM Software Recipe distribution file in the media directory to the current directory.

    (`ncn-m001#`) Copy `sat bootprep` and `product_vars.yaml` files

    ```bash
    cp "${MEDIA_DIR}"/hpc-csm-software-recipe-*/vcs/product_vars.yaml .
    cp -r "${MEDIA_DIR}"/hpc-csm-software-recipe-*/vcs/bootprep .
    ```

    (`ncn-m001#`) Examine the contents of `${ADMIN_DIR}` to verify the expected content is present

    ```bash
    find . -type f
    ```

    Example output:

    ```text
    ./bootprep/management-bootprep.yaml
    ./bootprep/compute-and-uan-bootprep.yaml
    ./product_vars.yaml
    ```

1. Edit the `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files to account for any site deviations from the default values. For example:
    - Comment out the `slurm-site` CFS configuration layer and uncomment the `pbs-site` CFS configuration layer in `compute-and-uan-bootprep.yaml` if PBS is the preferred workload manager
    - Comment out the SBPS `rootfs_provider` and `rootfs_provider_passthrough` parameters and uncomment the CPS `rootfs_provider` and `rootfs_provider_passthrough` parameters, if DVS with CPS is the preferred method to project content.
    - Comment the several sections with GPU_SUPPORT (between BEGIN_GPU_SUPPORT and END_GPU_SUPPORT) tags if the system has no GPU hardware.
        The sections are identified with BEGIN_GPU_SUPPORT and END_GPU_SUPPORT comments like this example.

        ```bash
        # The gpu_customize_driver_playbook.yml playbook will install GPU driver and
        # SDK/toolkit software into the compute boot image if GPU content is available
        # in the expected Nexus repo targets. If GPU content has not been uploaded to
        # Nexus this play will be skipped automatically. If GPU content is available in
        # Nexus but a non-gpu image is wanted this layer can be commented out.
        #BEGIN_GPU_SUPPORT
          - name: uss-gpu-customize-driver-playbook-{{uss.working_branch}}
            playbook: gpu_customize_driver_playbook.yml
            product:
              name: uss
              version: "{{uss.version}}"
              branch: "{{uss.working_branch}}"
            special_parameters:
              ims_require_dkms: true
        #END_GPU_SUPPORT
        ```

    - Comment out any CFS configuration layers in `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files for products that are not needed on the system
    - Any other changes needed to reflect site preferences

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override entries in the `default` section of the HPE-provided `product_vars.yaml` file.
   There are comments at the top of the `product_vars.yaml` file that describe the variables and related details. The following are a few examples of `site_vars.yaml` changes:
    - Add a `default` section containing a `network_type: "cassini"` entry to designate that Cassini is the desired Slingshot network type to be used when executing CFS configurations later in the workflow
    - Add a `suffix` entry to the `default` section to append a string to the names of CFS configuration, image, and BOS session template artifacts created during the workflow to make them easy to identify
    - Add a `system_name` entry to the `default` section. The Scalable Boot Projection Service (SBPS) uses this system name as the first part of the domain name. Do not add if not using SBPS.
      - See the procedure [Create a Session Template to Boot Compute Nodes with SBPS](../../../operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md#boot-set-rootfs_provider_passthrough-parameter)
        for more information.
        - If the `docs-csm` RPM is installed on a node, then this page can be found under `/usr/share/doc/csm/operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md`. See the
          "Boot set `rootfs_provider_passthrough` parameter" section for more details.
        - Otherwise, it can be found under the appropriate release branch in <https://github.com/Cray-HPE/docs-csm>.
      - This documentation indicates how to find the `system_name`.
    - Add a `site_domain` entry to the `default` section. The Scalable Boot Projection Service (SBPS) uses this domain name as the second part of the domain name. Do not add if not using SBPS.
      - See the procedure [Create a Session Template to Boot Compute Nodes with SBPS](../../../operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md#boot-set-rootfs_provider_passthrough-parameter)
        for more information.
        - If the `docs-csm` RPM is installed on a node, then this page can be found under `/usr/share/doc/csm/operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md`.
          See the "Boot set `rootfs_provider_passthrough` parameter"section for more details.
        - Otherwise, it can be found under the appropriate release branch in <https://github.com/Cray-HPE/docs-csm>.
      - This documentation indicates how to find the `site_domain`.

   Additional information on `site_vars.yaml` files can be found in the [Site and recipe variables](../IUF.md#site-and-recipe-variables) and [`update-vcs-config`](../stages/update_vcs_config.md) sections.

    1. <create a `site_vars.yaml` file with desired key/value pairs >

    2. Ensure the `site_vars.yaml` file contents are formatted correctly. The following text is an example for verification purposes only.

       (`ncn-m001#`) Display the contents of an **example** `site_vars.yaml` file

       ```bash
       cat site_vars.yaml
       ```

       Example output:

       ```text
       default:
         network_type: "cassini"
         suffix: "-test01"
         system_name: "my-system"
         site_domain: "my-site-domain.net"
       uss:
         deploy_slurm: true
         deploy_pbs: true
       ```

    3. Ensure the expected files are present in the admin directory after performing the steps in this section.

       (`ncn-m001#`) Examine the contents of `${ADMIN_DIR}` to verify the expected content is present

       ```bash
       find . -type f
       ```

       Example output:

       ```text
       ./bootprep/management-bootprep.yaml
       ./bootprep/compute-and-uan-bootprep.yaml
       ./product_vars.yaml
       ./site_vars.yaml
       ```

Once this step has completed:

- `${ADMIN_DIR}` is populated with `product_vars.yaml`, `site_vars.yaml`, and `sat bootprep` input files
- The aforementioned configuration files have been updated to reflect site preferences

**`NOTE`** If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.

## 2. Execute the IUF `update-vcs-config` stage

For each product that uploaded Ansible configuration content to a configuration management VCS repository, the `update-vcs-config` stage attempts to merge the pristine branch of the configuration management repository into a
corresponding customer working branch.

### 2.1 Prerequisites

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

### 2.2 Procedure

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

## 3. Perform manual product configuration operations

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

## 4. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM manually and additional products with IUF,
  return to the [Upgrade CSM manually and additional products with IUF](upgrade_csm_manual_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_iuf_additional_products_with_iuf.md)
  workflow to continue the upgrade.
