# Stage 1 - CSM Service Upgrades

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Start typescript](#start-typescript)
- [Perform upgrade](#perform-upgrade)
- [Verify Keycloak users](#verify-keycloak-users)
- [Take Etcd Manual Backup](#take-etcd-manual-backup)
- [Stop typescript](#stop-typescript)
- [Stage completed](#stage-completed)

## Start typescript

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_1.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Perform upgrade

During this stage there will be a brief (approximately five minutes) window where pods with Persistent Volumes (`PV`s) will not be able to migrate between nodes.
This is due to a redeployment of the Ceph `csi` provisioners into namespaces, in order to accommodate the newer charts and a better upgrade strategy.

1. If it has not been done previously, record in Vault the `admin` user password for the management switches in the system.

   See [Adding switch admin password to Vault](../operations/network/management_network/README.md#adding-switch-admin-password-to-vault).

1. (`ncn-m001#`) Ensure that the `CSM_RELEASE` variable is set to the **target** CSM version of this upgrade.

   ```bash
   export CSM_RELEASE=1.6.0
   ```

1. (`ncn-m001#`) Perform the upgrade.

   Run `csm-upgrade.sh` to deploy upgraded CSM applications and services.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/csm-upgrade.sh
   ```

## Verify Keycloak users

1. (`ncn-m001#`) Verify that the Keycloak users localize job has completed as expected.

    > This step can be skipped if user localization is not required.

    After an upgrade, it is possible that all expected Keycloak users were not localized.
    See [Verification procedure](../operations/security_and_authentication/Keycloak_User_Localization.md#verification-procedure)
    to confirm that Keycloak localization has completed as expected.

## Take Etcd Manual Backup

1. (`ncn-m001#`) Execute the following script to take a manual backup of the Etcd clusters.
   These clusters are automatically backed up every 24 hours, but taking a manual backup
   at this stage in the upgrade enables restoring from backup later in this process if needed.

   ```bash
   /usr/share/doc/csm/scripts/operations/etcd/take-etcd-manual-backups.sh post_upgrade
   ```

## Stop typescript

For any typescripts that were started during this stage, stop them with the `exit` command.

## Stage completed

This stage is completed. There are two different upgrade paths moving forward:

- Path 1: If performing a CSM only upgrade without IUF, continue to [Stage 2](Stage_2.md).
- Path 2: If performing an upgrade with IUF that includes upgrading CSM manually and additional products with IUF,
 return to [Upgrade CSM manually and additional products with IUF](../operations/iuf/workflows/upgrade_csm_manual_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.
- Path 3: If performing an upgrade with IUF that includes upgrading CSM and additional products with IUF, return to
[Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_iuf_additional_products_with_iuf.md) workflow to continue the upgrade.
