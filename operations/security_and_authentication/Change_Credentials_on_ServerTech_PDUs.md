# Change Credentials on ServerTech PDUs
This procedure changes password used by the `admn` user on ServerTech PDUs. Either a single PDU can be updated to a new credential, or update all ServerTech PDUs in the system to the same global credentials.

**NOTE:** This procedure does not update the default credentials that RTS uses for new ServerTech PDUs added to a system. To change the default credentials, follow the [Update default ServerTech PDU Credentials used by the Redfish Translation Service](Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md) procedure.

## Prerequisites
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

## Procedure

1. List the ServerTech PDUs currently discovered in the system:

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
        jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'
    ```

    Sample output:
    ```
    x3000m0
    ```

2.  Specify the existing password for the `admn` user:
    ```bash
    ncn-m001# read -s OLD_PDU_PASSWORD
    ncn-m001# echo $OLD_PDU_PASSWORD
    ```

    Expected output:
    ```
    secret
    ```

3.  Specify the new desired password for the `admn` user. The new password must between 1 and 32 characters.
    ```bash
    ncn-m001# read -s NEW_PDU_PASSWORD
    ncn-m001# echo $NEW_PDU_PASSWORD
    ```

    Expected output:
    ```
    supersecret
    ```

4.  Change password for the `admn` user on the ServerTech PDU.

    Either change the credentials on a single PDU or change all ServerTech PDUs to the same global default value:
    -   To update the password on a single ServerTech PDU in the system:
        ```bash
        ncn-m001# PDU=x3000m0
        ncn-m001# curl -i -k -u "admn:$OLD_PDU_PASSWORD" -X PATCH https://$PDU/jaws/config/users/local/admn \
            -d $(jq --arg PASSWORD "$NEW_PDU_PASSWORD" -nc '{password: $PASSWORD}')
        ```

        Expected output upon a successful password change:
        ```
        HTTP/1.1 204 No Content
        Content-Type: text/html
        Transfer-Encoding: chunked
        Server: ServerTech-AWS/v8.0p
        Set-Cookie: C5=1883488164; path=/
        Connection: close
        Pragma: JAWS v1.01
        ```

    -   To update all ServerTech PDUs in the system to the same password:
        ```bash
        ncn-m001# for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
          jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'); do
            echo "Updating password on $PDU"
            curl -i -k -u "admn:$OLD_PDU_PASSWORD" -X PATCH https://$PDU/jaws/config/users/local/admn \
                -d $(jq --arg PASSWORD "$NEW_PDU_PASSWORD" -nc '{password: $PASSWORD}')
        done
        ```

        Expected output upon a successful password change:
        ```
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

    **NOTE**: After 5 minutes the previous credential should stop working, as the existing session timed out.

5.  Update the PDU credentials stored in Vault:
    ```bash
    ncn-m001# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-m001# alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
    ```

    Either update the credentials in Vault for a single PDU or update Vault for all ServerTech PDUs to have same global default value:
    -   To update Vault for a single PDU:
        ```bash
        ncn-m001# PDU=x3000m0
        ncn-m001# vault kv get secret/pdu-creds/$PDU |
            jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
            vault kv put secret/pdu-creds/$PDU -
        ```

    -   To update Vault for all ServerTech PDUs in the system to the same password:
        ```bash
        ncn-m001# for PDU in $(cray hsm inventory redfishEndpoints list --type CabinetPDUController --format json |
          jq -r '.RedfishEndpoints[] | select(.FQDN | contains("rts")).ID'); do
            echo "Updating password on $PDU"
            vault kv get secret/pdu-creds/$PDU |
                jq --arg PASSWORD "$NEW_PDU_PASSWORD" '.data | .Password=$PASSWORD' |
                vault kv put secret/pdu-creds/$PDU -
        done
        ```

6.  Restart the Redfish Translation Service (RTS) to pickup the new PDU credentials:

    ```bash
    ncn-m001# kubectl -n services rollout restart deployment cray-hms-rts
    ncn-m001# kubectl -n services rollout status deployment cray-hms-rts
    ```

7.  Wait for RTS to initialize itself:
    ```bash
    ncn-m001# sleep 3m
    ```

8.  Verify RTS was able to communicate with the PDUs with the updated credentials:
    ```bash
    ncn-m001# kubectl -n services exec -it deployment/cray-hms-rts -c cray-hms-rts-redis -- redis-cli keys '*/redfish/v1/Managers'
    ```

    Expected output for a system with 2 PDUs.
    ```
    1) "x3000m0/redfish/v1/Managers"
    2) "x3001m0/redfish/v1/Managers"
    ```