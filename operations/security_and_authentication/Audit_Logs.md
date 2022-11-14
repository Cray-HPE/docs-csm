# Audit Logs

## Overview

Audit logs are used to monitor the system and search for suspicious behavior.
Host and Kubernetes API audit logging can be enabled to produce extra audit logs for analysis.
Enabling audit logging is optional. If enabled it generates some load and data on the non-compute nodes \(NCNs\).

By default, host and Kubernetes API audit logging are not enabled.
It is not required for both to be enabled or disabled at the same time.

Host audit logs are stored in the `/var/log/audit/HostOS` directory on each NCN.
Host audit logging uses a maximum of 60GB on each NCN when using log rotation settings.
The log rotation settings are enabled after editing the CSI settings and rebooting the NCNs.

The Kubernetes API audit logs are stored in the `/var/log/audit/kl8s/apiserver` directory on each master NCN.
Kubernetes API audit logging uses a maximum of 1GB on each master NCN when using log rotation settings.

* [Enable or disable audit logging for host and Kubernetes APIs](#enable-or-disable-audit-logging-for-host-and-kubernetes-apis)
  * [During CSM install, from the PIT node](#enable-audit-logging-during-csm-install-from-the-pit-node)
    * [Use `csi` tool](#use-csi-tool)
    * [Edit `system_config.yaml`](#edit-system_configyaml)
  * [After CSM install](#enable-audit-logging-after-csm-install)
    * [Use `csi` tool from `ncn-m001`](#use-csi-tool-from-ncn-m001)
    * [Modify BSS from a Kubernetes NCN](#modify-bss-from-a-kubernetes-ncn)
* [Verify that audit logging is enabled](#verify-that-audit-logging-is-enabled)
* [Restart NCNs to make settings take effect](#restart-ncns-in-order-to-make-settings-take-effect)

## Enable or disable audit logging for host and Kubernetes APIs

The method for updating the audit log settings varies depending on the state of the system.

Select one of the following options to enable audit logging based on the installation status of the system.
For each of the following options, only enable the desired level of audit logging. It is not required to enable both.

* [During CSM install, from the PIT node](#enable-audit-logging-during-csm-install-from-the-pit-node)
* [After CSM install](#enable-audit-logging-after-csm-install)

### Enable audit logging during CSM install, from the PIT node

**NOTE:** This step needs to happen at the same time that `csi config init` is normally run during the install.

(`pit#`) To update the audit log settings during the installation, use one of the following options:

* [Use `csi` tool](#use-csi-tool)
* [Edit `system_config.yaml`](#edit-systemconfigyaml)

#### Use `csi` tool

During the installation, audit logging is enabled or disabled by modifying the CSI settings.
To enable or disable audit logging, use the following flags with the `csi config init` command.
For more information on using flags, see `csi config init -h`.

* Host audit logging

   Set to `true` to enable host logging or to `false` to disable host logging.

   ```console
   csi config init --ncn-mgmt-node-auditing-enabled=true [other config init options]
   ```

* Kubernetes API audit logging

   Set to `true` to enable Kubernetes API logging or to `false` to disable Kubernetes API logging.

   ```console
   csi config init --k8s-api-auditing-enabled=true [other config init options]
   ```

#### Edit `system_config.yaml`

Adjust the audit log settings by editing the `system_config.yaml` file.

View the current settings with the following command:

```console
cd /var/www/ephemeral/prep
grep audit system_config.yaml
```

Example output:

```text
k8s-api-auditing-enabled: false
ncn-mgmt-node-auditing-enabled: false
```

### Enable audit logging after CSM install

Choose either of the following options:

* [Use `csi` tool from `ncn-m001`](#use-csi-tool-from-ncn-m001)
* [Modify BSS from a Kubernetes NCN](#modify-bss-from-a-kubernetes-ncn)

#### Use `csi` tool from `ncn-m001`

(`ncn-m001#`) Enable audit logging using the `csi` tool on `ncn-m001`.

1. Install the `csi` tool on `ncn-m001`, if it is not already installed.

   If the `csi` command is not installed on `ncn-m001`, then locate the `cray-site-init` RPM on `ncn-m001` and install it.

   ```console
   find /mnt/pitdata -name cray-site-init*
   rpm -Uvh --force <rpm file path>
   ```

   It is also possible to enable audit logging without `csi`. See [Modify BSS from a Kubernetes NCN](#modify-bss-from-a-kubernetes-ncn).

1. Enable audit logging.

   * Host audit logging

      ```console
      TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token') \
                csi handoff bss-update-param --limit <mgmt-node-xname> --set ncn-mgmt-node-auditing-enabled=true
      ```

   * Kubernetes API audit logging

      ```console
      TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token') \
                csi handoff bss-update-param --limit <mgmt-node-xname> --set k8s-api-auditing-enabled=true
      ```

#### Modify BSS from a Kubernetes NCN

(`ncn-mw#`) Enable audit logging with Boot Script Service (BSS) parameters.

1. Configure the Cray CLI, if it is not already.

   See [Configure the Cray CLI](../configure_cray_cli.md).

1. Enable audit logging.

   * Host audit logging

      ```console
      XNAME=<node_xname>
      PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | tr -d \")
      PARAMS="$PARAMS ncn-mgmt-node-auditing-enabled=true"
      cray bss bootparameters update --hosts "${XNAME}" --params "${PARAMS}"
      ```

   * Kubernetes API audit logging

      ```console
      XNAME=<node_xname>
      PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | tr -d \")
      PARAMS="$PARAMS k8s-api-auditing-enabled=true"
      cray bss bootparameters update --hosts "${XNAME}" --params "${PARAMS}"
      ```

## Verify that audit logging is enabled

> Changes made post-install will not be reflected until after the NCN is rebooted.

* (`ncn#`) Host audit logging

   ```console
   craysys metadata get ncn-mgmt-node-auditing-enabled
   ```

* (`ncn#`) Kubernetes API audit logging

   ```console
   craysys metadata get k8s-api-auditing-enabled
   ```

## Restart NCNs in order to make settings take effect

This section is only necessary if the audit logging settings were changed after the CSM install.
If the desired audit logging settings were made as part of the CSM install, then skip this section.

Restart each NCN to apply the new settings after the CSI setting is changed.

Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure.
