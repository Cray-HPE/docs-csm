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

1. (`ncn-m001#`) Install the latest `docs-csm` and `libcsm` RPMs, see the short procedure in
   [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation).

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

1. This step should ONLY be performed if an http proxy is required to access a public endpoint on the internet for the purpose of downloading artifacts.
CSM does NOT support the use of proxy servers for anything other than downloading artifacts from external endpoints.
The http proxy variables must be `unset` after the desired artifacts are downloaded. Failure to unset the http proxy variables after downloading artifacts will cause many failures in subsequent steps.

   ```bash
   export https_proxy=https://example.proxy.net:443
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
   unset http_proxy
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

While the names are similar, image customization is different than node personalization. Image customization is the
process of using Ansible stored in VCS in conjunction with the CFS and IMS microservices to customize an image before
it is booted. Node personalization is the process of using Ansible stored in VCS in conjunction with the CFS and IMS
microservices to personalize a node after it has booted.

- [Standard upgrade](#standard-upgrade) - Upgrading CSM on a system that has products installed other than CSM.
- [CSM-only system upgrade](#csm-only-system-upgrade) - Upgrading CSM only on a CSM-only system **no other products installed or being upgraded**.

### Standard upgrade

In most cases, administrators will be performing a standard upgrade and not a CSM-only system upgrade.
In the standard upgrade, the new worker NCN images must be customized, and all NCNs must have their personalization configurations updated in CFS.

**NOTE:** For the standard upgrade, it will not be possible to rebuild NCNs on the current, pre-upgraded CSM version after performing these steps. Rebuilding NCNs will become the same thing as upgrading them.

1. Prepare the pre-boot worker NCN image customizations.

    This will ensure that the CFS configuration layers are applied to perform image customization for the worker NCNs.
    See [Worker Image Customization](../operations/configuration_management/Worker_Image_Customization.md).

1. Prepare the post-boot NCN personalizations.

    This will ensure that the appropriate CFS configuration layers are applied when performing post-boot node personalization of the master, storage, and worker NCNs.
    See [NCN Node Personalization](../operations/configuration_management/NCN_Node_Personalization.md).

Continue on to [Stage 0.4](#stage-04---backup-workload-manager-data), skipping the [CSM-only system upgrade](#csm-only-system-upgrade) subsection below.

### CSM-only system upgrade

This upgrade scenario is extremely uncommon in production environments.

1. (`ncn-m001#`) Generate a new CFS configuration for the NCNs.

    This script will also leave CFS disabled for the NCNs. CFS will automatically be re-enabled on them as they are rebooted during the upgrade.

    > The configuration name in the following command (`management-0.0`) is deliberately used to distinguish this from the CFS configurations created during
    > standard upgrade, where the `0.0` would instead be the CSM recipe version.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh --no-enable --config-name management-0.0
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
