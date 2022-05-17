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

## Enable or disable audit logging for host and Kubernetes APIs

The method for updating the audit log settings varies depending on the state of the system.

1. Enable audit logging.

   1. (Optional) If the `csi` command is not installed, locate the `cray-site-init-*` RPM on `ncn-m001` and install it:

      ```console
      find /mnt/pitdata -name cray-site-init*
      rpm -Uvh --force <rpm file path>
      ```

   1. Select one of the following options to enable audit logging based on the installation status of the system:

      For each of the following options, only enable the desired level of audit logging.
      It is not required to enable both.

      * During CSM install, from the PIT node (`pit#`)

        To update the audit log settings during the installation, use one of the following options:

        * **Option 1**

          During the installation, audit logging is enabled or disabled by modifying the CSI settings.
          To enable or disable audit logging, use the following flags with the `csi config init` command. For more information on using flags, see `csi config init -h`.

          * `ncn-mgmt-node-auditing-enabled`

            Set to `true` to enable host logging or to `false` to disable host logging.

            ```console
            csi config init --ncn-mgmt-node-auditing-enabled=true [other config init options]
            ```

          * `k8s-api-auditing-enabled`

            Set to `true` to enable Kubernetes API logging or to `false` to disable Kubernetes API logging.

            ```console
            csi config init --k8s-api-auditing-enabled=true [other config init options]
            ```

        * **Option 2**

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

      * After CSM install (`ncn-m001#`)

        * **Option 1**

          Enable audit logging through the following `csi` command.

          * `ncn-mgmt-node-auditing-enabled`

            ```console
            TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
               -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
               https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token') \
               csi handoff bss-update-param --limit <mgmt-node-xname> --set ncn-mgmt-node-auditing-enabled=true
            ```

          * `k8s-api-auditing-enabled`

            ```console
            TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
               -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
               https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token') \
               csi handoff bss-update-param --limit <mgmt-node-xname> --set k8s-api-auditing-enabled=true
            ```

        * **Option 2**

          Enable audit logging with Boot Script Service (BSS) parameters.

          * `ncn-mgmt-node-auditing-enabled`

            ```console
            XNAME=<node_xname>
            PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | tr -d \")
            PARAMS="$PARAMS ncn-mgmt-node-auditing-enabled=true"
            cray bss bootparameters update --hosts "${XNAME}" --params "${PARAMS}"
            ```

          * `k8s-api-auditing-enabled`

            ```console
            XNAME=<node_xname>
            PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | tr -d \")
            PARAMS="$PARAMS k8s-api-auditing-enabled=true"
            cray bss bootparameters update --hosts "${XNAME}" --params "${PARAMS}"
            ```

2. (`ncn#`) Verify that audit logging is enabled (changes made post-install will not be reflected until after the NCN is rebooted).

   `ncn-mgmt-node-auditing-enabled`:

   ```console
   craysys metadata get ncn-mgmt-node-auditing-enabled
   ```

   `k8s-api-auditing-enabled`:

   ```console
   craysys metadata get k8s-api-auditing-enabled
   ```

3. Restart each NCN to apply the new settings after the CSI setting is changed.

   Skip this step if the system was fresh installed with audit logging enabled.

   Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure.
