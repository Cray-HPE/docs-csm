# Recovering from Mismatched BMC Credentials

Use this procedure to recover from the situation when new or replacement hardware has `root` credentials that do not match the system's current default `root` user credentials.

This type of problem can occur in the following scenarios:

- The site has customized the default `root` credentials using either the
  [Updating the Liquid-Cooled EX Cabinet CEC with Default Credentials after a CEC Password Change](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md) or
  [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md) procedures.
- Hardware has the factory default `root` password or a different known `root` password configured. For example, hardware that has moved from a different system with a customized default `root` password.

## Procedure

1. Specify the BMC hostname with the mismatched credentials:

    ```bash
    BMC=x1000c0r1b0
    ```

1. Specify the current `root` user password for the BMC:

    > Depending on the origin of the piece of hardware, this could be the factory default password or a different system's default password.

    ```bash
    read -s CURRENT_ROOT_PASSWORD
    echo $CURRENT_ROOT_PASSWORD
    ```

1. Verify the credentials work with Redfish using `curl`:

    ```bash
    curl -k -u "root:$CURRENT_ROOT_PASSWORD" https://$BMC/redfish/v1/Managers -i
    ```

    The following example output shows the `CURRENT_ROOT_PASSWORD` environment variable contains a valid root password for the BMC.

    ```text
    HTTP/1.1 200 OK
    ...output truncated...
    ```

    Conversely, the following output shows the `CURRENT_ROOT_PASSWORD` environment variable contains an **invalid** `root` user password for the BMC. Update the `CURRENT_ROOT_PASSWORD` environment variable to contain a valid `root` user password for the BMC.

    ```text
    HTTP/1.1 401 Unauthorized
    ...output truncated...
    ```

1. Update the credentials for the Redfish endpoint stored in Vault using Hardware State Manager (HSM):

    ```bash
    cray hsm inventory redfishEndpoints update $BMC --user root --password $CURRENT_ROOT_PASSWORD 
    ```

1. Wait a few minutes for HSM to attempt to inventory the BMC:

    ```bash
    sleep 120
    ```

1. Verify the BMC's discovery status is `DiscoverOK`:

    ```bash
    cray hsm inventory redfishEndpoints describe $BMC
    ```

    If `DiscoveryStarted`, then wait and recheck the discovery status again. If `HTTPsGetFailed`, then examine the HSM logs to troubleshoot the issue.

1. Determine the system's default BMC `root` user password:

    ```bash
    VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

    1. Retrieve the default `root` password.

        - For liquid-cooled hardware:

            ```bash
            SYSTEM_ROOT_PASSWORD=$(vault kv get secret/meds-cred/global/ipmi | jq .data.Password -r)
            ```

        - For air-cooled hardware:

            ```bash
            SYSTEM_ROOT_PASSWORD=$(vault kv get secret/reds-creds/defaults | jq .data.Cray.password -r)
            ```

    1. Verify the systems's default `root` user password:

       ```bash
       echo $SYSTEM_ROOT_PASSWORD
       ```

1. Create a payload for the System Configuration Service (SCSD):

    ```bash
    jq --arg BMC "$BMC" --arg PASSWORD "$SYSTEM_ROOT_PASSWORD" -n \
                '{Targets:[{Xname: $BMC, Creds: {Username: "root", Password: $PASSWORD}}]}' > scsd_payload.json
    ```

1. Inspect the payload:

    ```bash
    jq . scsd_payload.json
    ```

    Example payload contents:

    ```json
    {
      "Targets": [
        {
        "Xname": "x1000c0r1b0",
        "Creds": {
            "Username": "root",
            "Password": "foobar"
          }
        }
      ]
    }
    ```

1. Apply the systems's default BMC `root` user credentials to the BMC:

    ```bash
    cray scsd bmc discreetcreds create scsd_payload.json
    ```

    Example of a successful credential change:

    ```toml
    [[Targets]]
    Xname = "x1000c0r1b0"
    StatusCode = 204
    StatusMsg = "No Content"
    ```

    If the operation is not successful inspect the SCSD logs.

1. Remove SCSD payload file containing credentials from the file system:

    ```bash
    rm scsd_payload.json
    ```
