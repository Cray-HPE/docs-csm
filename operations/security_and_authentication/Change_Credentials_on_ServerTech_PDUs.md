# Change Credentials on ServerTech PDUs

This procedure changes password used by the `admn` user on ServerTech PDUs. Either a single PDU can be updated to a new credential, or update all ServerTech PDUs in the system to the same global credentials.

**NOTE:** This procedure does not update the default credentials that RTS uses for new ServerTech PDUs added to a system.
To change the default credentials, follow the [Update default ServerTech PDU Credentials used by the Redfish Translation Service](Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md) procedure.

**NOTE:** ServerTech PDUs running firmware version `8.0q` or greater must have the password of the `admn` changed before the JAWS rest API functions as expected.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.
- The PDU is accessible over the network. A PDU can be reachable by its component name (xname) hostname, but may not yet be discovered by HSM.
- (`ncn#`) PDUs are manufactured by ServerTech.

    ```bash
    PDU=x3000m0
    curl -k https://$PDU -i | grep Server
    ```

    Expected output:

    ```text
    Server: ServerTech-AWS/v8.0v
    ```

## Procedure

1. (`ncn#`) List the ServerTech PDUs currently discovered in the system:

    ```bash
    cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
        jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'
    ```

    Sample output:

    ```text
    x3000m0
    ```

1. (`ncn#`) Set up aliases:

    ```bash
    VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

1. (`ncn#`) Specify the existing password for the `admn` user:

    To extract the global credentials from vault for the PDUs:

    ```bash
    vault kv get secret/pdu-creds/global/pdu
    ```

    To extract the credentials from vault for a single PDU:

    ```bash
    PDU=x3000m0
    vault kv get secret/pdu-creds/$PDU
    ```

    Store the current password:

    ```bash
    read -s OLD_PDU_PASSWORD
    echo $OLD_PDU_PASSWORD
    ```

    Expected output:

    ```text
    secret
    ```

1. Specify the new desired password for the `admn` user. The new password must follow the following criteria:
    - Minimum of 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 number character

    ```bash
    read -s NEW_PDU_PASSWORD
    echo $NEW_PDU_PASSWORD
    ```

    Expected output:

    ```text
    Super5ecret
    ```

1. Change and update the password for a ServerTech PDU(s). Either change the credentials on a single PDU or change all ServerTech PDUs to the same global default value:

     1. To update the password on a single ServerTech PDU in the system:
         **NOTE**: To change the password on a single PDU, the PDUs must be successfully discovered by HSM.

        1. (`ncn#`) Set the PDU hostname to change the `admn` credentials:

            ```bash
            PDU=x3000m0
            ```

        1. (`ncn#`) Verify the PDU is reachable:

            ```bash
            ping $PDU
            ```

        1. (`ncn#`) Change password for the `admn` user on the ServerTech PDU.

            ```bash
            curl -i -k -u "admn:$OLD_PDU_PASSWORD" -X PATCH https://$PDU/jaws/config/users/local/admn \
                -d $(jq --arg PASSWORD "$NEW_PDU_PASSWORD" -nc '{password: $PASSWORD}')
            ```

            Expected output upon a successful password change:

            ```text
            HTTP/1.1 204 No Content
            Content-Type: text/html
            Transfer-Encoding: chunked
            Server: ServerTech-AWS/v8.0p
            Set-Cookie: C5=1883488164; path=/
            Connection: close
            Pragma: JAWS v1.01
            ```

        1. (`ncn#`) Update the PDU credentials stored in Vault:

            ```bash
            vault kv get secret/pdu-creds/$PDU |
                    jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
                    vault kv put secret/pdu-creds/$PDU -
            ```

     1. Update all ServerTech PDUs in the system to the same password:

        1. (`ncn#`) Change password for the `admn` user on the ServerTech PDUs currently discovered in the system.

            ```bash
            for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
            jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'); do
                echo "Updating password on $PDU"
                curl -i -k -u "admn:$OLD_PDU_PASSWORD" -X PATCH https://$PDU/jaws/config/users/local/admn \
                    -d $(jq --arg PASSWORD "$NEW_PDU_PASSWORD" -nc '{password: $PASSWORD}')
            done
            ```

            Expected output upon a successful password change:

            ```text
            Updating password on x3000m0
            HTTP/1.1 204 No Content
            Content-Type: text/html
            Transfer-Encoding: chunked
            Server: ServerTech-AWS/v8.0p
            Set-Cookie: C5=1883488164; path=/
            Connection: close
            Pragma: JAWS v1.01
            Updating password on x3001m0
            HTTP/1.1 204 No Content
            Content-Type: text/html
            Transfer-Encoding: chunked
            Server: ServerTech-AWS/v8.0p
            Set-Cookie: C5=1883488164; path=/
            Connection: close
            Pragma: JAWS v1.01
            ```

        1. (`ncn#`) Update Vault for all ServerTech PDUs in the system to the same password:

            ```bash
            for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
              jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'); do
                echo "Updating password on $PDU"
                vault kv get secret/pdu-creds/$PDU |
                    jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
                    vault kv put secret/pdu-creds/$PDU -
            done
            ```

    **NOTE**: After five minutes, the previous credential should stop working as the existing session timed out.

1. (`ncn#`) Restart the Redfish Translation Service (RTS) to pickup the new PDU credentials:

    ```bash
    kubectl -n services rollout restart deployment cray-hms-rts
    kubectl -n services rollout status deployment cray-hms-rts
    ```

1. (`ncn#`) Wait for RTS to initialize itself:

    ```bash
    sleep 3m
    ```

1. (`ncn#`) Verify RTS was able to communicate with the PDUs with the updated credentials:

    ```bash
    kubectl -n services exec -it deployment/cray-hms-rts -c cray-hms-rts-redis -- redis-cli keys '*/redfish/v1/Managers'
    ```

    Expected output for a system with 2 PDUs.

    ```text
    1) "x3000m0/redfish/v1/Managers"
    2) "x3001m0/redfish/v1/Managers"
    ```
