# Change SNMP Credentials on Leaf-BMC Switches

This procedure changes the SNMP credentials on management leaf-BMC switches in the system. All SNMP credentials need to be the same as those found in the `customizations.yaml` sealed secret `cray_reds_credentials`.

**`NOTE`** This procedure will not update the default SNMP credentials used when new leaf BMC switches are added to the system. To update the default SNMP credentials for new hardware, follow
the [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md) procedure.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

There are three steps involved. The first two steps involve running the `leaf_switch_snmp_creds.sh` script. This script can be used to check for undesirable SNMP user IDs and credentials, and also to set new ones. The default behavior is to check first
and then set new credentials. The script can be run either interactively (no environment variables or command line options) or non-interactively (using environment variables on the command line). The following examples use the environment variable method.

1. (`ncn-mw#`) Set environment variables containing the new SNMP credentials.
    > `read -s` is used to prevent the password from appearing in the command history.

    1. Set the SNMP authentication password environment variable.

        ```bash
        read -s SNMP_AUTH_PASS
        ```

    1. Set the SNMP privacy password environment variable.

        ```bash
        read -s SNMP_PRIV_PASS
        ```

1. (`ncn-mw#`) Set environment variable containing the switch `admin` user password for the management switches in the system.

    ```bash
    read -s SWITCH_ADMIN_PASSWORD
    ```

1. (`ncn-mw#`) Update SNMP credentials (desired SNMP user ID and authentication and privacy passwords) on leaf-BMC switches. The SNMP user IDs and passwords are not shown.

   Also note that this will change the SNMP credentials in Vault. See below for details on how to do that.

   ```bash
   SNMPNEWUSER=testuser \
             SNMPAUTHPW=$SNMP_AUTH_PASS SNMPPRIVPW=$SNMP_PRIV_PASS \
             SNMPMGMTPW=$SWITCH_ADMIN_PASSWORD \
             /opt/cray/csm/scripts/hms_verification/leaf_switch_snmp_creds.sh
   ```

   Example output:

   ```text
   ==> Getting management network leaf switch info from SLS...

   ==> Fetching switch hostnames...
   ===============================
   Checking SNMP default creds on Dell leaf switch: sw-leaf-002

   ==> SNMP user ID 'testuser' found on switch sw-leaf-002.
   Setting SNMP default creds on Aruba leaf switch: sw-leaf-002
   ===============================
   Checking SNMP default creds on Dell leaf switch: sw-leaf-001

   ==> SNMP user ID 'testuser' found on switch sw-leaf-001.
   Setting SNMP default creds on Dell leaf switch: sw-leaf-002

   ```

1. (`ncn-mw#`) Set the Vault alias, if it is not already set.

    ```bash
    VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

1. (`ncn-mw#`) Update Vault with new SNMP credentials.

    Either update the credentials in Vault for a single leaf switch, or update Vault for all leaf switches to have same global default value.

    - To update Vault for all leaf switches in the system to the same password:

        ```bash
        for XNAME in $(cray sls search hardware list --type comptype_mgmt_switch --format json | jq -r .[].Xname); do
            echo "Updating SNMP creds for $XNAME"
            vault kv get secret/hms-creds/$XNAME |
                jq --arg SNMP_AUTH_PASS "$SNMP_AUTH_PASS" --arg SNMP_PRIV_PASS "$SNMP_PRIV_PASS" \
                    '.data | .SNMPAuthPass=$SNMP_AUTH_PASS | .SNMPPrivPass=$SNMP_PRIV_PASS' |
                vault kv put secret/hms-creds/$XNAME -
        done
        ```

    - To update Vault for a single leaf switch:

        ```bash
        XNAME=x3000c0w22
        vault kv get secret/hms-creds/$XNAME |
            jq --arg SNMP_AUTH_PASS "$SNMP_AUTH_PASS" --arg SNMP_PRIV_PASS "$SNMP_PRIV_PASS" \
                '.data | .SNMPAuthPass=$SNMP_AUTH_PASS | .SNMPPrivPass=$SNMP_PRIV_PASS' |
            vault kv put secret/hms-creds/$XNAME -
        ```

1. (`ncn-mw#`) Restart the River Endpoint Discovery Service (REDS) to pick up the new SNMP credentials.

    ```bash
    kubectl -n services rollout restart deployment cray-reds
    kubectl -n services rollout status deployment cray-reds
    ```

1. Wait two minutes for REDS to initialize itself.

1. (`ncn-mw#`) Verify that REDS was able to communicate with the leaf-BMC switches with the updated credentials.

    1. Determine the name of the REDS pods.

        ```bash
        kubectl -n services get pods -l app.kubernetes.io/name=cray-reds
        ```

        Example output:

        ```text
        NAME                         READY   STATUS    RESTARTS   AGE
        cray-reds-6b99b9d5dc-c5g2t   2/2     Running   0          3m21s
        ```

    1. Check the logs of the REDS pod for SNMP communication issues.

        In the following command, replace `CRAY_REDS_POD_NAME` with the currently running pod for REDS:

        ```bash
        kubectl -n services logs CRAY_REDS_POD_NAME cray-reds | grep "Failed to get ifIndex<->name map"
        ```

        If nothing is returned, then REDS is able to successfully communicate to the leaf-BMC switches in the system via SNMP.

        Errors like the following occur when SNMP credentials in Vault to not match what is configured on the leaf-BMC switch.

        ```text
        2021/10/26 20:03:21 WARNING: Failed to get ifIndex<->name map (1.3.6.1.2.1.31.1.1.1.1) for x3000c0w22: Received a report from the agent - UsmStatsWrongDigests(1.3.6.1.6.3.15.1.1.5.0)
        ```

## Troubleshooting

If the credentials are not working, then check the Vault credentials as shown above.

If the `leaf_switch_snmp_creds.sh` script fails for whatever reason on any
leaf-BMC switch, then validate and change the credentials manually using the
procedures found in [Aruba SNMP Users Guide](../network/management_network/aruba/snmpv3_users.md) or [Dell SNMP Users Guide](../network/management_network/dell/snmpv3_users.md).

### Viewing SNMP credentials stored in Vault

**If desired** view the existing SNMP credentials stored in Vault for a `leaf-bmc` switch.

1. (`ncn-mw#`) Set up the `vault` alias.

    ```bash
    VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

1. (`ncn-mw#`) List the switches in the system.

    ```bash
    cray sls search hardware list --type comptype_mgmt_switch --format json | 
        jq '.[] | { Xname: .Xname, Aliases: .ExtraProperties.Aliases, Brand: .ExtraProperties.Brand}' -c
    ```

    Example output:

    ```json
    {"Xname":"x3000c0w37","Aliases":["sw-leaf-bmc-001"],"Brand":"Aruba"}
    ```

1. (`ncn-mw#`) Query Vault for the expected `sw-leaf-bmc` credentials.

    ```bash
    vault kv get secret/hms-creds/x3000c0w37
    ```

    Example output:

    ```json
    {
        "request_id": "62070a95-8bbb-6834-d707-c17ca9b565e3",
        "lease_id": "",
        "lease_duration": 2764800,
        "renewable": false,
        "data": {
            "Password": "",
            "SNMPAuthPass": "SNMP_AUTH_PASSWORD",
            "SNMPPrivPass": "SNMP_PRIV_PASSWORD",
            "URL": "",
            "Username": "testuser",
            "Xname": "x3000c0w37"
        },
        "warnings": null
    }
    ```
