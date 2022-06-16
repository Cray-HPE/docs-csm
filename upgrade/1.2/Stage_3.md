# Stage 3 - CSM Service Upgrades

## Prepare assets on `ncn-m002`

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   CSM_RELEASE=1.2.0
   ```

1. Follow either the [Direct download](#direct-download) or [Manual copy](#manual-copy) procedure.

   - If there is a URL for the CSM `tar` file that is accessible from `ncn-m002`, then the [Direct download](#direct-download) procedure may be used.
   - Alternatively, the [Manual copy](#manual-copy) procedure may be used, which includes manually copying the CSM `tar` file to `ncn-m002`.

### Direct download

1. Set the `ENDPOINT` variable to the URL of the directory containing the CSM release `tar` file.

   In other words, the full URL to the CSM release `tar` file must be `${ENDPOINT}${CSM_RELEASE}.tar.gz`

   > **`NOTE`** This step is optional for Cray/HPE internal installs, if `ncn-m002` can reach the internet.

   ```bash
   ENDPOINT=https://put.the/url/here/
   ```

1. Run the script.

   > **`NOTE`** For Cray/HPE internal installs, if `ncn-m002` can reach the internet, then the `--endpoint` argument may be omitted.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version csm-${CSM_RELEASE} --endpoint "${ENDPOINT}"
   ```

1. Skip the `Manual copy` subsection and proceed to [Perform upgrade](#perform-upgrade).

### Manual copy

1. Copy the CSM release `tar` file to `ncn-m002`.

   See [Update Product Stream](../../update_product_stream/README.md).

1. Set the `CSM_TAR_PATH` variable to the full path to the CSM `tar` file on `ncn-m002`.

   ```bash
   CSM_TAR_PATH=/path/to/csm-${CSM_RELEASE}.tar.gz
   ```

1. Run the script.

   > By default, the script will delete the CSM tarball file. If not wanting the tarball file to be deleted, then
   > append the `--no-delete-tarball-file` argument when running the script.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prepare-assets.sh --csm-version csm-${CSM_RELEASE} --tarball-file "${CSM_TAR_PATH}"
   ```

## Perform upgrade

During this stage there will be a brief (approximately five minutes) window where pods with Persistent Volumes (`PV`s) will not be able to migrate between nodes.
This is due to a redeployment of the Ceph `csi` provisioners into namespaces, in order to accommodate the newer charts and a better upgrade strategy.

1. Set the `SW_ADMIN_PASSWORD` environment variable.

   Set it to the `admin` user password for the switches. This is required for post-upgrade tests.

   > `read -s` is used to prevent the password from being written to the screen or the shell history.

   ```bash
   read -s SW_ADMIN_PASSWORD
   export SW_ADMIN_PASSWORD
   ```

1. Perform the upgrade.

   Run `csm-upgrade.sh` to deploy upgraded CSM applications and services.

   ```bash
   /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/csm-upgrade.sh
   ```

## Verify Keycloak users

Verify that the Keycloak users localize job has completed as expected.

> This section can be skipped if user localization is not required.

After an upgrade, it is possible that all expected Keycloak users were not localized.
See [Verification procedure](../../operations/security_and_authentication/Keycloak_User_Localization.md#Verification-procedure) to confirm that Keycloak localization has completed as expected.

## Stage completed

This stage is completed. Continue to [Stage 4](Stage_4.md).
