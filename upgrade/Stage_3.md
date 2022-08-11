# Stage 3 - CSM Service Upgrades

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Move assets to `ncn-m002`

1. Set the `CSM_RELEASE` variable to the **target** CSM version of this upgrade.

   ```bash
   CSM_RELEASE=1.3.0
   CSM_REL_NAME=csm-${CSM_RELEASE}
   ```

1. Move the RBD device containing the csm tarball.

    ```bash
   /usr/share/doc/csm/scripts/csm_rbd_tool/csm_rbd_tool.py --rbd_action move --target_host ncn-m002
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
   /usr/share/doc/csm/upgrade/scripts/upgrade/csm-upgrade.sh
   ```

## Verify Keycloak users

Verify that the Keycloak users localize job has completed as expected.

> This section can be skipped if user localization is not required.

After an upgrade, it is possible that all expected Keycloak users were not localized.
See [Verification procedure](../operations/security_and_authentication/Keycloak_User_Localization.md#Verification-procedure) to confirm that Keycloak localization has completed as expected.

## Stage completed

This stage is completed. Continue to [Stage 4](Stage_4.md).
