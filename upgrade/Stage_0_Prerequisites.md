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
  - [Stage 0.3 - Customize the new NCN image and update NCN personalization configurations](#stage-03---customize-the-new-ncn-image-and-update-ncn-personalization-configurations)
    - [Standard upgrade](#standard-upgrade)
    - [CSM-only system upgrade](#csm-only-system-upgrade)
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
   CSM_RELEASE=1.4.0
   CSM_REL_NAME=csm-${CSM_RELEASE}
   ```

1. (`ncn-m001#`) Install the latest `docs-csm` RPM.

   - If `ncn-m001` has internet access, then use the following commands to download and install the latest documentation.

      > **Important:** The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why these commands copy it there.

      ```bash
      wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.4/noarch/docs-csm-latest.noarch.rpm \
          -O /root/docs-csm-latest.noarch.rpm &&
      rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
      ```

   - Otherwise, use the following procedure to download and install the latest documentation.

      1. Download the latest `docs-csm` RPM to an external system and copy it to `ncn-m001`.

         See [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation).

      1. (`ncn-m001#`) Copy the documentation RPM to `/root` and install it.

         > **Important:**
         >
         > - Replace the `PATH_TO_DOCS_RPM` below with the location of the RPM on `ncn-m001`.
         > - The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

         ```bash
         cp PATH_TO_DOCS_RPM /root/docs-csm-latest.noarch.rpm &&
         rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
         ```

1. (`ncn-m001#`) Create and mount an `rbd` device where the CSM release tarball can be stored.

   1. Initialize the Python virtual environment.

      ```bash
      tar xvf /usr/share/doc/csm/scripts/csm_rbd_tool.tar.gz -C /opt/cray/csm/scripts/
      ```

   1. Create and map the `rbd` device.

      **IMPORTANT:** This mounts the `rbd` device at `/etc/cray/upgrade/csm` on `ncn-m001`. This mount is available to stage content for the install/upgrade process. First, check if this device already exists.

      ```bash
      source /opt/cray/csm/scripts/csm_rbd_tool/bin/activate
      /usr/share/doc/csm/scripts/csm_rbd_tool.py --status
      ```

      >Expected output if `rbd` device does not exist:
      >
      >```text
      >Pool csm_admin_pool does not exist
      >Pool csm_admin_pool exists: False
      >RBD device exists None
      >```
      >
      >Example output if `rbd` device already exist:
      >
      >```text
      >[{"id":"0","pool":"csm_admin_pool","namespace":"","name":"csm_scratch_img","snap":"-","device":"/dev/rbd0"}]
      >Pool csm_admin_pool exists: True
      >RBD device exists True
      >RBD device mounted at - ncn-m002.nmn:/etc/cray/upgrade/csm
      >```

      If the `rbd` device already exists and is mounted, it can be moved to the desired node, if not already mounted there.
      **IMPORTANT:** *If upgrading from a CSM version that had previously mounted this rbd device, the `/etc/cray/upgrade/csm/myenv` file will need to be removed before proceeding with this upgrade as it will contain information from the previous install.*

      ```bash
      /usr/share/doc/csm/scripts/csm_rbd_tool.py --rbd_action move --target_host ncn-m001
      deactivate
      ```

      If the `rbd` device does not exist, create it.

      ```bash
      /usr/share/doc/csm/scripts/csm_rbd_tool.py --pool_action create --rbd_action create --target_host ncn-m001
      deactivate
      ```

      For more information or usage on the csm_rbd_tool utility please see [csm_rbd_tool Usage](../operations/utility_storage/CSM_rbd_tool_Usage.md)

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. (`ncn-m001#`) Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_REL_NAME}.tar.gz`

   **NOTE** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. (`ncn-m001#`) Run the script.

   **NOTE** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   > The `prepare-assets.sh` script will delete the CSM tarball (after expanding it) in order to free up space.
   > This behavior can be overridden by appending the `--no-delete-tarball-file` argument to the `prepare-assets.sh`
   > command below.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection and proceed to [Stage 0.2 - Prerequisites](#stage-02---prerequisites)

### Manual copy

1. Copy the CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../update_product_stream/README.md).

1. (`ncn-m001#`) Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   ```bash
   CSM_TAR_PATH=/path/to/${CSM_REL_NAME}.tar.gz
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

## Stage 0.3 - Customize the new NCN image and update NCN personalization configurations

There are two possible scenarios. Follow the procedure for the scenario that is applicable to the upgrade being performed.

- [Standard upgrade](#standard-upgrade) - Upgrading CSM on a system that has products installed other than CSM.
- [CSM-only system upgrade](#csm-only-system-upgrade) - Upgrading CSM only on a CSM-only system **no other products installed or being upgraded**.

While the names are similar, image customization is different than node personalization. Image customization is the
process of using Ansible stored in VCS in conjunction with the CFS and IMS microservices to customize an image before
it is booted. Node personalization is the process of using Ansible stored in VCS in conjunction with the CFS and IMS
microservices to personalize a node after it has booted.

**NOTE:** For the standard upgrade, it will not be possible to rebuild NCNs on the current, pre-upgraded CSM version after performing these steps. Rebuilding NCNs will become the same thing as upgrading them.

### Standard upgrade

In most cases, administrators will be performing a standard upgrade and not a CSM-only system upgrade. In the standard upgrade, worker NCN image customization and node personalization steps are required.

1. If not already done, consult the `HPE Cray EX System Software Getting Started Guide`.

    Read the `HPE Cray EX software upgrade workflow` section. Pay particular attention to the `HPC CSM Software Recipe` and `Cray System Management (CSM)` subsections,
    as well as any `NCN Personalization` subsections.

1. Prepare the pre-boot worker NCN image customizations.

    This will ensure that the CFS configuration layers are applied to perform image customization for the worker NCNs.
    See [Worker Image Customization](../operations/configuration_management/Worker_Image_Customization.md).

1. Prepare the post-boot worker NCN personalizations.

    This will ensure that the appropriate CFS configuration layers are applied when performing post-boot node personalization of the worker NCNs.
    See [NCN Node Personalization](../operations/configuration_management/NCN_Node_Personalization.md).

Continue on to [Stage 0.4](#stage-04---backup-workload-manager-data), skipping the [CSM-only system upgrade](#csm-only-system-upgrade) subsection below.

### CSM-only system upgrade

This upgrade scenario is extremely uncommon in production environments.

1. (`ncn-m001#`) Generate new CFS configuration for the NCNs.

    This script will also leave CFS disabled for the NCNs. CFS will automatically be re-enabled on them as they are rebooted during the upgrade.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh --no-enable
    ```

    Successful output should end with the following line:

    ```text
    All components updated successfully.
    ```

## Stage 0.4 - Backup workload manager data

To prevent any possibility of losing workload manager configuration data or files, a backup is required. Execute all backup procedures (for the workload manager in use) located in
the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the
`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

This stage is completed. Continue to [Stage 1 - Ceph image upgrade](Stage_1.md).
