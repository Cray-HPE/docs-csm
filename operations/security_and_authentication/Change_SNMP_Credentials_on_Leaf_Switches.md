# Change SNMP Credentials on Leaf Switches

This procedure changes the SNMP credentials on management leaf switches in the system. Either a single leaf switch can be updated to use new SNMP credentials, or update all leaf switches in the system to use the same global SNMP credentials.

**NOTE:** This procedure will not update the default SNMP credentials used when new leaf switches are added to the system. To update the default SNMP credentials for new hardware, follow
the [Update Default Air-Cooled BMC and Leaf Switch SNMP Credentials](Update_Default_Air-Cooled_BMC_and_Leaf_Switch_SNMP_Credentials.md) procedure.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

1. List leaf switches in the system.

    ```bash
    ncn-m001# cray sls search hardware list --type comptype_mgmt_switch --format json |
                jq -r '["Xname", "Brand", "Alias"], (.[] | [.Xname, .ExtraProperties.Brand, .ExtraProperties.Aliases[0]]) | @tsv' | column -t
    ```

    Sample output for a system with one Aruba leaf switch:

    ```text
    Xname       Brand  Alias
    x3000c0w14  Aruba  sw-leaf-001
    ```

    Sample output for a system with two Dell leaf switches:

    ```text
    Xname       Brand  Alias
    x3000c0w14  Dell   sw-leaf-002
    x3000c0w13  Dell   sw-leaf-001
    ```

1. Update SNMP credentials for the `testuser` user on each leaf switch in the system. The SNMP `testuser` user requires two
   password to be provided for the SNMP authentication and privacy protocol passwords. Both of these passwords must be eight
   characters or longer. In the examples below, `foobar01` is the new SNMP authentication password, and `foobar02` is the
   new SNMP privacy password.

    1. Configure the Aruba leaf switch.

        ```console
        ncn-m001# ssh admin@sw-leaf-001
        sw-leaf-001# configure terminal
        sw-leaf-001(config)# snmpv3 user testuser auth md5 auth-pass plaintext foobar01 priv des priv-pass plaintext foobar02
        sw-leaf-001(config)# exit
        sw-leaf-001# write memory
        sw-leaf-001# exit
        ```

    1. Configure the Dell leaf switch.

        ```console
        ncn-m001# ssh admin@sw-leaf-001
        sw-leaf-001# configure terminal
        sw-leaf-001(config)# snmp-server user testuser cray-reds-group 3 auth md5 foobar01 priv des foobar02
        sw-leaf-001(config)# exit
        sw-leaf-001# write memory
        sw-leaf-001# exit
        ```

1. Set environment variables containing the new SNMP credentials.

    1. Set the SNMP authentication password environment variable.

        ```bash
        ncn-mw# read -s SNMP_AUTH_PASS
        ```

    1. Set the SNMP privacy password environment variable.

        ```bash
        ncn-mw# read -s SNMP_PRIV_PASS
        ```

1. Set environment variable containing the switch `admin` user password for the management switches in the system.

1. Set the Vault alias, if it is not already set.

    ```bash
    ncn-mw# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-mw# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

1. Update Vault with new SNMP credentials.

    Either update the credentials in Vault for a single leaf switch, or update Vault for all leaf switches to have same global default value.

    - To update Vault for all leaf switches in the system to the same password:

        ```bash
        ncn-mw# for XNAME in $(cray sls search hardware list --type comptype_mgmt_switch --format json | jq -r .[].Xname); do
                  echo "Updating SNMP creds for $XNAME"
                  vault kv get secret/hms-creds/$XNAME |
                    jq --arg SNMP_AUTH_PASS "$SNMP_AUTH_PASS" --arg SNMP_PRIV_PASS "$SNMP_PRIV_PASS" '.data | .SNMPAuthPass=$SNMP_AUTH_PASS | .SNMPPrivPass=$SNMP_PRIV_PASS' |
                    vault kv put secret/hms-creds/$XNAME -
                done
        ```

    - To update Vault for a single leaf switch:

        ```bash
        ncn-mw# XNAME=x3000c0w22
                echo "Updating SNMP creds for $XNAME"
                vault kv get secret/hms-creds/$XNAME |
                  jq --arg SNMP_AUTH_PASS "$SNMP_AUTH_PASS" --arg SNMP_PRIV_PASS "$SNMP_PRIV_PASS" '.data | .SNMPAuthPass=$SNMP_AUTH_PASS | .SNMPPrivPass=$SNMP_PRIV_PASS' |
                  vault kv put secret/hms-creds/$XNAME -
        ```

1. Restart the River Endpoint Discovery Service (REDS) to pick up the new SNMP credentials.

    ```bash
    ncn-mw# kubectl -n services rollout restart deployment cray-reds
    ncn-mw# kubectl -n services rollout status deployment cray-reds
    ```

1. Wait two minutes for REDS to initialize itself.

1. Verify that REDS was able to communicate with the leaf switches with the updated credentials.

    1. Determine the name of the REDS pods.

        ```bash
        ncn-mw# kubectl -n services get pods -l app.kubernetes.io/name=cray-reds
        ```

        Example output:

        ```text
        NAME                         READY   STATUS    RESTARTS   AGE
        cray-reds-6b99b9d5dc-c5g2t   2/2     Running   0          3m21s
        ```

    1. Check the logs of the REDS pod for SNMP communication issues.

        In the following command, replace `CRAY_REDS_POD_NAME` with the currently running pod for REDS:

        ```bash
        ncn-mw# kubectl -n services logs CRAY_REDS_POD_NAME cray-reds | grep "Failed to get ifIndex<->name map"
        ```

        If nothing is returned, then REDS is able to successfully communicate to the leaf switches in the system via SNMP.

        Errors like the following occur when SNMP credentials in Vault to not match what is configured on the leaf switch.

        ```text
        2021/10/26 20:03:21 WARNING: Failed to get ifIndex<->name map (1.3.6.1.2.1.31.1.1.1.1) for x3000c0w22: Received a report from the agent - UsmStatsWrongDigests(1.3.6.1.6.3.15.1.1.5.0)
        ```
