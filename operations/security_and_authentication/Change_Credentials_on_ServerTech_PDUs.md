# Change Credentials on ServerTech PDUs

This procedure changes password used by the `admn` user on ServerTech PDUs. Either a single PDU can be updated to a new credential, or
all ServerTech PDUs in the system can be updated to the same global credentials.

**NOTES:**

- This procedure does not update the default credentials that RTS uses for new ServerTech PDUs added to a system. To change the default credentials, see
  [Update default ServerTech PDU Credentials used by the Redfish Translation Service](Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md).
- ServerTech PDUs running firmware version `8.0q` or greater must have the password of the `admn` user changed before the JAWS REST API will function as expected.
- The default username and password for ServerTech PDUs is `admn` and `admn`.

## Prerequisites

- The Cray command line interface (CLI) is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The PDU is accessible over the network. A PDU can be reachable by its component name (xname) hostname, but may not yet be discovered by HSM.
- PDUs are manufactured by ServerTech.

    This can be verified by the following command

    ```bash
    ncn-mw# PDU=x3000m0
    ncn-mw# curl -k -s --compressed  https://$PDU -i | grep Server:
    ```

    Expected output for a ServerTech PDU:

    ```text
    Server: ServerTech-AWS/v8.0v
    ```

    **`NOTE`**: The firmware version is listed after the '/'. In this case, the firmware version is `8.0v`.

## Procedure

1. List the ServerTech PDUs currently discovered in the system.

    ```bash
    ncn-mw# cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
        jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'
    ```

    Example output:

    ```text
    x3000m0
    ```

    If some or all of the PDUs are not discovered by HSM, you must obtain the component name (`xname`) for each of the ServerTech PDUs on the system.

1. Set up Vault password variable and command alias.

    ```bash
    ncn-mw# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-mw# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

1. Look up the existing password for the `admn` user.

    - To extract the global credentials from Vault for the PDUs:

        ```bash
        ncn-mw# vault kv get secret/pdu-creds/global/pdu
        ```

    - To extract the credentials from Vault for a single PDU:

        ```bash
        PDU=x3000m0
        vault kv get secret/pdu-creds/$PDU
        ```

1. Store the existing password for the `admn` user.

    ```bash
    ncn-mw# read -s OLD_PDU_PASSWORD
    ```

1. Specify the new desired password for the `admn` user. The new password must follow the following criteria:

    - Minimum of 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 number character

    ```bash
    read -s NEW_PDU_PASSWORD
    ```

1. Change and update the password for ServerTech PDUs.

    Either change the credentials on a single PDU or change all ServerTech PDUs to the same global default value:

    - Update the password on a single ServerTech PDU

        1. Set the PDU hostname to change the `admn` credentials:

            ```bash
            ncn-mw# PDU=x3000m0
            ```

        1. Verify that the PDU is reachable:

            ```bash
            ncn-mw# ping $PDU
            ```

        1. Change password for the `admn` user on the ServerTech PDU.

            ```bash
            ncn-mw# curl -i -k -u "admn:$OLD_PDU_PASSWORD" -X PATCH https://$PDU/jaws/config/users/local/admn \
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

        1. Update the PDU credentials stored in Vault.

            ```bash
            ncn-mw# vault kv get secret/pdu-creds/$PDU |
                    jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
                    vault kv put secret/pdu-creds/$PDU -
            ```

    - Update all ServerTech PDUs in the system to the same password.

        **`NOTE`**: To change the password on all PDUs, PDUs must be successfully discovered by HSM.

        1. Change password for the `admn` user on the ServerTech PDUs currently discovered in the system.

            ```bash
            ncn-mw# for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
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

        1. Update Vault for all ServerTech PDUs in the system to the same password:

            ```bash
            ncn-mw# for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
              jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'); do
                echo "Updating password on $PDU"
                vault kv get secret/pdu-creds/$PDU |
                    jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
                    vault kv put secret/pdu-creds/$PDU -
            done
            ```

            **`NOTE`**: After five minutes, the previous credential should stop working as the existing sessions time out.

1. Restart the Redfish Translation Service (RTS) to pickup the new PDU credentials.

    ```bash
    ncn-mw# kubectl -n services rollout restart deployment cray-hms-rts
    ncn-mw# kubectl -n services rollout status deployment cray-hms-rts
    ```

1. Wait for RTS to initialize itself.

    ```bash
    ncn-mw# sleep 3m
    ```

1. Verify that RTS was able to communicate with the PDUs with the updated credentials.

    ```bash
    ncn-mw# kubectl -n services exec -it deployment/cray-hms-rts -c cray-hms-rts-redis -- redis-cli keys '*/redfish/v1/Managers'
    ```

    Expected output for a system with two PDUs.

    ```text
    1) "x3000m0/redfish/v1/Managers"
    2) "x3001m0/redfish/v1/Managers"
    ```
