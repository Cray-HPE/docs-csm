# Stage 0 - Prerequisites and Preflight Checks

> **Reminders:**
>
> - CSM 1.3.0 or higher is required in order to upgrade to CSM 1.4.0.
> - If any problems are encountered and the procedure or command output does not provide relevant guidance, see
>   [Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

Stage 0 has several critical procedures which prepare the environment and verify if the environment is ready for the upgrade.

- [Stage 0 - Prerequisites and Preflight Checks](#stage-0---prerequisites-and-preflight-checks)
  - [Start typescript](#start-typescript)
  - [Stage 0.1 - Prepare assets](#stage-01---prepare-assets)
    - [Direct download](#direct-download)
    - [Manual copy](#manual-copy)
  - [Stage 0.2 - Prerequisites](#stage-02---prerequisites)
  - [Stage 0.3 - Update management node CFS configuration and customize worker node image](#stage-03---update-management-node-cfs-configuration-and-customize-worker-node-image)
    - [Option 1: Upgrade of CSM and additional products](#option-1-upgrade-of-csm-and-additional-products)
    - [Option 2: Upgrade of CSM on system with additional products](#option-2-upgrade-of-csm-on-system-with-additional-products)
    - [Option 3: Upgrade of CSM on CSM-only system](#option-3-upgrade-of-csm-on-csm-only-system)
  - [Stage 0.4 - Backup workload manager data](#stage-04---backup-workload-manager-data)
  - [Stop typescript](#stop-typescript)
  - [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_0.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Stage 0.1 - Prepare assets

1. (`ncn-m001#`) Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   export CSM_RELEASE=1.4.0
   ```

1. (`ncn-m001#`) Install the latest `docs-csm` and `libcsm` RPMs. See the short procedure in
   [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation).

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. (`ncn-m001#`) Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}/csm-${CSM_RELEASE}.tar.gz`

   > ***NOTE*** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. This step should ONLY be performed if an http proxy is required to access a public endpoint on the internet for the purpose of downloading artifacts.
CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
The http proxy variables must be `unset` after the desired artifacts are downloaded. Failure to unset the http proxy variables after downloading artifacts will cause many failures in subsequent steps.

    - Secured:

       ```bash
       export https_proxy=https://example.proxy.net:443
       ```

    - Unsecured:

       ```bash
       export http_proxy=http://example.proxy.net:80
       ```

1. (`ncn-m001#`) Run the script.
   **NOTE** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   > The `prepare-assets.sh` script will delete the CSM tarball (after expanding it) in order to free up space.
   > This behavior can be overridden by appending the `--no-delete-tarball-file` argument to the `prepare-assets.sh`
   > command below.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. This step must be performed if an http proxy was set previously.

   ```bash
   unset https_proxy
   ```

   ```bash
   unset http_proxy
   ```

1. Skip the `Manual copy` subsection and proceed to [Stage 0.2 - Prerequisites](#stage-02---prerequisites)

### Manual copy

1. Copy the CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../update_product_stream/README.md).

1. (`ncn-m001#`) Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   ```bash
   CSM_TAR_PATH=/path/to/csm-${CSM_RELEASE}.tar.gz
   ```

1. (`ncn-m001#`) Run the script.

   > The `prepare-assets.sh` script will delete the CSM tarball (after expanding it) in order to free up space.
   > This behavior can be overridden by appending the `--no-delete-tarball-file` argument to the `prepare-assets.sh`
   > command below.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Stage 0.2 - Prerequisites

1. (`ncn-m001#`) Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the password for `admin` user on the switches. This is needed for preflight tests within the check script.

   > **NOTE:** `read -s` is used to prevent the password from being written to the screen or the shell history.

   ```bash
   read -s SW_ADMIN_PASSWORD
   ```

   ```bash
   export SW_ADMIN_PASSWORD
   ```

1. (`ncn-m001#`) Set the `NEXUS_PASSWORD` variable **only if needed**.

   > **IMPORTANT:** If the password for the local Nexus `admin` account has been
   > changed from the password set in the `nexus-admin-credential` secret (not typical),
   > then set the `NEXUS_PASSWORD` environment variable to the correct `admin` password
   > and export it, before running `prerequisites.sh`.
   >
   > For example:
   >
   > > `read -s` is used to prevent the password from being written to the screen or the shell history.
   >
   > ```bash
   > read -s NEXUS_PASSWORD
   > ```
   >
   > ```bash
   > export NEXUS_PASSWORD
   > ```
   >
   > Otherwise, the upgrade will try to use the password in the `nexus-admin-credential`
   > secret and fail to upgrade Nexus.

1. (`ncn-m001#`) Run the script.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prerequisites.sh --csm-version ${CSM_RELEASE}
   ```

   If the script ran correctly, it should end with the following output:

   ```text
   [OK] - Successfully completed
   ```

   If the script does not end with this output, then try rerunning it. If it still fails, see
   [Upgrade Troubleshooting](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).
   If the failure persists, then open a support ticket for guidance before proceeding.

1. (`ncn-m001#`) Unset the `NEXUS_PASSWORD` variable, if it was set in the earlier step.

   ```bash
   unset NEXUS_PASSWORD
   ```

1. (Optional) (`ncn-m001#`) Commit changes to `customizations.yaml`.

   `customizations.yaml` has been updated in this procedure. If using an external Git repository
   for managing customizations as recommended, then clone a local working tree and commit
   appropriate changes to `customizations.yaml`.

   For example:

   ```bash
   git clone <URL> site-init
   cd site-init
   kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   git add customizations.yaml
   git commit -m 'CSM 1.3 upgrade - customizations.yaml'
   git push
   ```

1. If performing an upgrade of CSM and additional HPE Cray EX software products using the IUF,
   return to the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)
   procedure. Otherwise, if performing an upgrade of only CSM, proceed to Stage 0.3.

## Stage 0.3 - Update management node CFS configuration and customize worker node image

This stage updates a CFS configuration used to perform node personalization and image customization
of management nodes. It also applies that CFS configuration to the management nodes and customizes
the worker node image, if necessary.

Image customization is the process of using Ansible stored in VCS in conjunction with the CFS and
IMS microservices to customize an image before it is booted. Node personalization is the process of
using Ansible stored in VCS in conjunction with the CFS and IMS microservices to personalize a node
after it has booted.

There are several options for this stage. Use the option which applies to the current upgrade
scenario.

- [Option 1: Upgrade of CSM and additional products](#option-1-upgrade-of-csm-and-additional-products)
- [Option 2: Upgrade of CSM on system with additional products](#option-2-upgrade-of-csm-on-system-with-additional-products)
- [Option 3: Upgrade of CSM on CSM-only system](#option-3-upgrade-of-csm-on-csm-only-system)

### Option 1: Upgrade of CSM and additional products

If performing an upgrade of CSM and additional HPE Cray EX software products, this stage
should not be performed. Instead, the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)
procedure should be followed as described in the first option of the [Upgrade CSM](../upgrade/README.md) procedure,
[Option 1: Upgrade CSM with additional HPE Cray EX software products](../upgrade/README.md#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)

That procedure will perform the appropriate steps to create a CFS configuration for management nodes
and perform management node image customization during the
[Image Preparation](../operations/iuf/workflows/image_preparation.md) step.

### Option 2: Upgrade of CSM on system with additional products

Use this alternative if performing an upgrade of only CSM on a system which has additional HPE Cray
EX software products installed. This upgrade scenario is uncommon in production environments.
Generally, if performing an upgrade of CSM, you will also be performing an upgrade of additional HPE
Cray EX software products as part of an HPC CSM software recipe upgrade. In that case, follow the
scenario described above for [Upgrade of CSM and additional products](#option-1-upgrade-of-csm-and-additional-products).

The following subsection shows how to use IUF input files to perform `sat bootprep` operations, in this
case to assign images and configurations to management nodes.

#### Using `sat bootprep` with IUF generated input files

In order to follow this procedure, you will need to know the name of the IUF activity used to
perform the initial installation of the HPE Cray EX software products. See the
[Activities](../operations/iuf/IUF.md#activities) section of the IUF documentation for more
information on IUF activities. See [`list-activities`](../operations/iuf/IUF.md#list-activities)
for information about listing the IUF activities on the system. The first step provides an
example showing how to find the IUF activity.

1. (`ncn-m001#`) Find the IUF activity used for the most recent install of the system.

   ```bash
   iuf list-activities
   ```

   This will output a list of IUF activity names. For example, if only a single install has been
   performed on this system of the 22.04 recipe, the output may show a single line like this:

   ```text
   22.04-recipe-install
   ```

1. (`ncn-m001#`) Record the most recent IUF activity name and directory in environment variables.

   ```bash
   export ACTIVITY_NAME="22.04-recipe-install"
   export ACTIVITY_DIR="/etc/cray/upgrade/csm/iuf/${ACTIVITY_NAME}"
   ```

1. (`ncn-m001#`) Record the media directory used for this activity in an environment variable.

   ```bash
   export MEDIA_DIR="$(yq r "${ACTIVITY_DIR}/state/stage_hist.yaml" 'summary.media_dir')"
   echo "${MEDIA_DIR}"
   ```

   This should display a path to a media directory. For example:

   ```text
   /etc/cray/upgrade/csm/media/22.04-recipe-install
   ```

1. (`ncn-m001#`) Create a directory for the `sat bootprep` input files and the `session_vars.yaml` file.

   This example uses a directory under the RBD mount used by the IUF:

   ```bash
   export BOOTPREP_DIR="/etc/cray/upgrade/csm/admin/bootprep-csm-${CSM_RELEASE}"
   mkdir -pv "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the `sat bootprep` input file for management nodes into the directory.

   It is possible that the file name will differ from `management-bootprep.yaml` if a different
   file was used during the IUF activity.

   ```bash
   cp -v "${MEDIA_DIR}/.bootprep-${ACTIVITY_NAME}/management-bootprep.yaml" "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the `session_vars.yaml` file into the directory.

   ```bash
   cp -v "${ACTIVITY_DIR}/state/session_vars.yaml" "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Modify the CSM version in the copied `session_vars.yaml`:

   ```bash
   yq w -i "${BOOTPREP_DIR}/session_vars.yaml" 'csm.version' "${CSM_RELEASE}"
   ```

1. (`ncn-m001#`) Update the `working_branch` if one is used for the CSM product.

   By default, a `working_branch` is not used for the CSM product. Check if there is a
   `working_branch` specified for CSM:

   ```bash
   yq r "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch'
   ```

   If this produces no output, a `working_branch` is not in use for the CSM product, and this step
   can be skipped. Otherwise, it shows the name of the working branch. For example:

   ```text
   integration-1.4.0
   ```

   In this case, be sure to manually update the version string in the working branch to match the
   new working branch. Then check it again. For example:

   ```bash
   yq w -i "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch' "integration-${CSM_RELEASE}"
   yq r "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch'
   ```

   This should output the name of the new CSM working branch.

1. (`ncn-m001#`) Modify the `default.suffix` value in the copied `session_vars.yaml`:

   As long as the `sat bootprep` input file uses `{{default.suffix}}` in the names of the CFS
   configurations and IMS images, this will ensure new CFS configurations and IMS images are created
   with different names from the ones created in the IUF activity.

   ```bash
   yq w -i -- "${BOOTPREP_DIR}/session_vars.yaml" 'default.suffix' "-csm-${CSM_RELEASE}"
   ```

1. (`ncn-m001#`) Change directory to the `BOOTPREP_DIR` and run `sat bootprep`.

   This will create a CFS configuration for management nodes, and it will use that CFS configuration
   to customize the images for the master, worker, and storage management nodes.

   ```bash
   cd "${BOOTPREP_DIR}"
   sat bootprep run --vars-file session_vars.yaml management-bootprep.yaml
   ```

1. Gather the CFS configuration name, and the IMS image names from the output of `sat bootprep`.

   `sat bootprep` will print a report summarizing the CFS configuration and IMS images it created.
   For example:

   ```text
   ################################################################################
   CFS configurations
   ################################################################################
   +-----------------------------+
   | name                        |
   +-----------------------------+
   | management-22.4.0-csm-x.y.z |
   +-----------------------------+
   ################################################################################
   IMS images
   ################################################################################
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | name                        | preconfigured_image_id               | final_image_id                       | configuration               | configuration_group_names  |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | master-secure-kubernetes    | c1bcaf00-109d-470f-b665-e7b37dedb62f | a22fb912-22be-449b-a51b-081af2d7aff6 | management-22.4.0-csm-x.y.z | Management_Master          |
   | worker-secure-kubernetes    | 8b1343c4-1c39-4389-96cb-ccb2b7fb4305 | 241822c3-c7dd-44f8-98ca-0e7c7c6426d5 | management-22.4.0-csm-x.y.z | Management_Worker          |
   | storage-secure-storage-ceph | f3dd7492-c4e5-4bb2-9f6f-8cfc9f60526c | 79ab3d85-274d-4d01-9e2b-7c25f7e108ca | management-22.4.0-csm-x.y.z | Management_Storage         |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   ```

   Save the name of the CFS configuration:

   ```bash
   export CFS_CONFIG_NAME="management-22.4.0-csm-x.y.z"
   ```

   Save the name of the IMS images from the `final_image_id` column:

   ```bash
   export MASTER_IMAGE_ID="a22fb912-22be-449b-a51b-081af2d7aff6"
   export WORKER_IMAGE_ID="241822c3-c7dd-44f8-98ca-0e7c7c6426d5"
   export STORAGE_IMAGE_ID="79ab3d85-274d-4d01-9e2b-7c25f7e108ca"
   ```

1. Assign the images to the management nodes in BSS.

   Perform the procedure in [4. Update management node boot parameters](../operations/configuration_management/Management_Node_Image_Customization.md#4-update-management-node-boot-parameters)
   for master, worker, and storage nodes.

   Note that the procedure must be followed three times: once for master nodes with
   `MASTER_IMAGE_ID`, once for worker nodes with `WORKER_IMAGE_ID`, and once for storage nodes with
   `STORAGE_IMAGE_ID`.

   Do not proceed to the next steps in the linked procedure. Return here when finished with the
   single step that updates the management node boot parameters.

1. Assign the CFS configuration to the management nodes.

   This command deliberately only sets the desired configuration of the components in CFS. It
   disables the components and does not clear their configuration states or error counts. When the
   nodes are rebooted to their new images later in the CSM upgrade, they will automatically be
   enabled in CFS, and node personalization will occur.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
       --no-config-change --config-name "${CFS_CONFIG_NAME}" --no-enable --no-clear-err
   ```

   Successful output will end with the following:

   ```text
   All components updated successfully.
   ```

Continue on to [Stage 0.4](#stage-04---backup-workload-manager-data).

### Option 3: Upgrade of CSM on CSM-only system

Use this alternative if performing an upgrade of CSM on a CSM-only system with no other HPE Cray EX
software products installed. This upgrade scenario is extremely uncommon in production environments.

1. (`ncn-m001#`) Generate a new CFS configuration for the management nodes.

   This script creates a new CFS configuration that includes the CSM version in its name and
   applies it to the management nodes. This leaves the management node components in CFS disabled.
   They will be automatically enabled when they are rebooted at a later stage in the upgrade.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
       --no-enable --config-name management-${CSM_RELEASE}
   ```

   Successful output should end with the following line:

   ```text
   All components updated successfully.
   ```

Continue on to [Stage 0.4](#stage-04---backup-workload-manager-data).

## Stage 0.4 - Backup workload manager data

To prevent any possibility of losing workload manager configuration data or files, a backup is required. Execute all backup procedures (for the workload manager in use) located in
the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the
`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

If performing an upgrade of CSM and additional HPE Cray EX software products using the IUF,
return to the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)
procedure. Otherwise, if performing an upgrade of only CSM, proceed to the next step.

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

This stage is completed. Continue to [Stage 1 - CSM Service Upgrades](Stage_1.md).
