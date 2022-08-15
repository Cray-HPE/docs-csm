# Stage 0 - Prerequisites and Preflight Checks

> **Reminders:**
>
> - CSM 1.2.0 or higher is required in order to upgrade to CSM 1.3.0.
> - If any problems are encountered and the procedure or command output does not provide relevant guidance, see
>   [Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

Stage 0 has several critical procedures which prepare the environment and verify if the environment is ready for the upgrade.

- [Stage 0 - Prerequisites and Preflight Checks](#stage-0---prerequisites-and-preflight-checks)
  - [Stage 0.1 - Prepare assets](#stage-01---prepare-assets)
    - [Direct download](#direct-download)
    - [Manual copy](#manual-copy)
  - [Stage 0.2 - Upgrade management network](#stage-02---upgrade-management-network)
    - [Verify that switches have 1.2 configuration in place](#verify-that-switches-have-12-configuration-in-place)
  - [Stage 0.3 - Prerequisites check](#stage-03---prerequisites-check)
  - [Stage 0.4 - Backup workload manager data](#stage-04---backup-workload-manager-data)
  - [Stage completed](#stage-completed)

## Stage 0.1 - Prepare assets

1. (`ncn-m001#`) Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   CSM_RELEASE=1.3.0
   CSM_REL_NAME=csm-${CSM_RELEASE}
   ```

1. Use `csm_rbd_tool.py` to create the pool, device, and mount the device.

    ```bash
    source /opt/cray/csm/scripts/csm_rbd_tool/bin/activate
    /usr/share/doc/csm/scripts/csm_rbd_tool/csm_rbd_tool.py --pool_action create --rbd_action create --target_host ncn-m001
    deactivate
    ```

    **Note:** This same `rbd` device can be remapped to `ncn-m002` later in the upgrade procedure, when the CSM tarball is needed on that node.

    Example:

    ```bash
    /usr/share/doc/csm/scripts/csm_rbd_tool/csm_rbd_tool.py --rbd_action move --target_host ncn-m002
    ```

    **IMPORTANT:** This will mount the `rbd` device at `/etc/cray/upgrade/csm` on the desired node.

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m001`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m001`.

### Direct download

1. (`ncn-m001#`) Download and install the latest documentation RPM.

   > **Important:** The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   wget https://artifactory.algol60.net/artifactory/csm-rpms/hpe/stable/sle-15sp2/docs-csm/1.3/noarch/docs-csm-latest.noarch.rpm \
        -O /root/docs-csm-latest.noarch.rpm &&
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. (`ncn-m001#`) Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_REL_NAME}.tar.gz`

   **NOTE** This step is optional for Cray/HPE internal installs, if `ncn-m001` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. (`ncn-m001#`) Run the script.

   **NOTE** For Cray/HPE internal installs, if `ncn-m001` can reach the internet, then the `--endpoint` argument may be omitted.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection and proceed to [Stage 0.2 - Update SLS](#stage-02---update-sls)

### Manual copy

1. Copy the `docs-csm` RPM package and CSM release `tar` file to `ncn-m001`.

   See [Update Product Stream](../update_product_stream/README.md).

1. (`ncn-m001#`) Copy the documentation RPM to `/root` and install it.

   > **Important:**
   >
   > - Replace the `PATH_TO_DOCS_RPM` below with the location of the RPM on `ncn-m001`.
   > - The upgrade scripts expect the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm`; that is why this command copies it there.

   ```bash
   cp PATH_TO_DOCS_RPM /root/docs-csm-latest.noarch.rpm &&
   rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
   ```

1. (`ncn-m001#`) Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m001`.

   > The `prepare-assets.sh` script will delete the CSM tarball in order to free space on the node.
   > If using an `rbd` device to store the CSM tarball (or if not wanting the tarball file deleted for other reasons), then be sure to
   > copy the tarball file to a different location, and set the `CSM_TAR_PATH` to point to this new location.

   ```bash
   CSM_TAR_PATH=/path/to/${CSM_REL_NAME}.tar.gz
   ```

1. (`ncn-m001#`) Run the script.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/prepare-assets.sh --csm-version ${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Stage 0.2 - Upgrade management network

### Verify that switches have 1.2 configuration in place

1. Log in to each management switch.

1. Examine the text displayed when logging in to the switch.

   Specifically, look for output similar to the following:

   ```text
   ##################################################################################
   # CSM version:  1.2
   # CANU version: 1.6.5
   ##################################################################################
   ```

   - Output like the above text means that the switches have a CANU-generated configuration for CSM 1.2 in place. In this case, follow the steps in
     [Management Network 1.2 to 1.3](../operations/network/management_network/1.2_to_1.3_upgrade.md).
   - If the banner does NOT contain text like the above, then contact support in order to get `CSM 1.2 switch configuration` applied to the system.
   - See the [Management Network User Guide](../operations/network/management_network/README.md) for more information on the management network.
   - With CSM >= 1.2 switch configurations in place, users will only be able to SSH into the switches over the HMN and CMN.

## Stage 0.3 - Prerequisites check

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
   [Upgrade Troubleshooting](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).
   If the failure persists, then open a support ticket for guidance before proceeding.
   
1. (`ncn-m001#`) Assign a new CFS configuration to the worker nodes.

   The content of the new CFS configuration is described in HPE Cray EX System Software Getting Started Guide S-8000, section
   "HPE Cray EX Software Upgrade Workflow" subsection "Cray System Management (CSM)".

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

## Stage 0.4 - Backup workload manager data

To prevent any possibility of losing workload manager configuration data or files, a backup is required. Execute all backup procedures (for the workload manager in use) located in
the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the
`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting backup data should be stored in a safe location off of the system.

## Stage completed

This stage is completed. Continue to [Stage 1 - Ceph image upgrade](Stage_1.md).
