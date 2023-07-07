# Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials

This procedure updates the default credentials used when new air-cooled hardware is discovered for the first time. This includes the default Redfish credentials used for
new air-cooled `NodeBMCs` and Slingshot switch BMCs (`RouterBMCs`), and SNMP credentials for new management leaf-BMC switches.

***IMPORTANT*** After this procedure is completed, **all future air-cooled hardware** added to the system will be assumed to be configured with the new global default credential.

> ***NOTE*** This procedure will not update the Redfish or SNMP credentials for existing air-cooled devices. To change the credentials on existing air-cooled hardware follow the
> [Change Air-Cooled Node BMC Credentials](Change_Air-Cooled_Node_BMC_Credentials.md) and [Configuring SNMP in CSM]( ../../operations/network/management_network/configure_snmp.md) procedures.

- [Limitation](#limitation)
- [Procedure](#procedure)
    1. [Update the default credentials used by REDS](#1-update-the default-credentials-used-by-reds)
    1. [Restart the SNMP-backed RTS to pick up the SNMP credential changes](#2-restart-the-snmp-backed-rts-to-pick-up-the-snmp-credential-changes)

## Limitation

The default global credentials used for liquid-cooled BMCs in the [Change Cray EX Liquid-Cooled Cabinet Global Default Password](Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md)
procedure needs to be the same as the one used in this procedure for air-cooled BMCs (River hardware).

## Procedure

The River Endpoint Discovery Service (REDS) sealed secret contains the default global credential used by REDS.

### 1. Update the default credentials used by REDS

Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure **with the following specifications**:

- Chart name: `cray-hms-reds`
- Base manifest name: `core-services`
- (`ncn-mw#`) When reaching the step to update the customizations, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    1. Run `git clone https://github.com/Cray-HPE/csm.git`.

    1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

        ```bash
        cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
        ```

    1. Acquire sealed secret keys.

        ```bash
        mkdir -pv certs
        kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/sealed_secrets.crt
        kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > certs/sealed_secrets.key
        ```

    1. Modify REDS sealed secret to use new global default credentials.

        1. Inspect the original default Redfish credentials used by REDS and HMS discovery.

            ```bash
            ./utils/secrets-decrypt.sh cray_reds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults -r | base64 -d | jq
            ```

            Expected output looks similar to the following:

            ```json
            {
                "Cray": {
                    "Username": "root",
                    "Password": "foo"
                }
            }
            ```

        1. Inspect the original default switch SNMP credentials used by REDS and HMS discovery.

            ```bash
            ./utils/secrets-decrypt.sh cray_reds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_switch_defaults -r | base64 -d | jq
            ```

            Expected output looks similar to the following:

            ```json
            {
                "SNMPUsername": "testuser",
                "SNMPAuthPassword": "foo",
                "SNMPPrivPassword": "bar"
            }
            ```

        1. Update the default credentials in `customizations.yaml` for REDS and HMS discovery to use.

            1. Specify the desired default Redfish credentials.

                ```bash
                echo '{"Cray":{"Username":"root","Password":"foobar"}}' | base64 > reds.redfish.creds.json.b64
                ```

            1. Specify the desired default SNMP credentials.

                ```bash
                echo '{"SNMPUsername":"testuser","SNMPAuthPassword":"foo1","SNMPPrivPassword":"bar2"}' | base64 > reds.switch.creds.json.b64
                ```

        1. Update and regenerate the `cray_reds_credentials` sealed secret.

            ```bash
            cat << EOF | yq w - 'data.vault_redfish_defaults' "$(<reds.redfish.creds.json.b64)" | yq w - 'data.vault_switch_defaults' "$(<reds.switch.creds.json.b64)" | yq r -j - | ./utils/secrets-encrypt.sh | yq w -f - -i ./customizations.yaml 'spec.kubernetes.sealed_secrets.cray_reds_credentials'
            {
                "kind": "Secret",
                "apiVersion": "v1",
                "metadata": {
                    "name": "cray-reds-credentials",
                    "namespace": "services",
                    "creationTimestamp": null
                },
                "data": {}
            }
            EOF
            ```

        1. Decrypt generated secret for review.

            1. Review the default Redfish credentials.

                ```bash
                ./utils/secrets-decrypt.sh cray_reds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults -r | base64 -d | jq
                ```

                Expected output looks similar to the following:

                ```json
                {
                    "Username": "root",
                    "Password": "foobar"
                }
                ```

            1. Review the default switch SNMP credentials.

                ```bash
                ./utils/secrets-decrypt.sh cray_reds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_switch_defaults -r | base64 -d | jq
                ```

                Expected output looks similar to the following:

                ```json
                {
                    "SNMPUsername": "testuser",
                    "SNMPAuthPassword": "foo1",
                    "SNMPPrivPassword": "bar2"
                }
                ```

- (`ncn-mw#`) When reaching the step to validate the redeployed chart, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    1. Wait for the REDS Vault loader job to run to completion.

        ```bash
        kubectl -n services wait job cray-reds-vault-loader --for=condition=complete --timeout=5m
        ```

    1. Verify that the default Redfish credentials have updated in Vault.

        ```bash
        VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
        kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/reds-creds/defaults
        ```

        Expected output:

        ```text
        ==== Data ====
        Key     Value
        ---     -----
        Cray    map[password:foobar username:root]
        ```

    1. Verify that the default SNMP credentials have updated in Vault.

        ```bash
        kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/reds-creds/switch_defaults
        ```

        Expected output:

        ```text
        ========== Data ==========
        Key                 Value
        ---                 -----
        SNMPAuthPassword    foo1
        SNMPPrivPassword    bar2
        SNMPUsername        testuser
        ```

- **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**

### 2. Restart the SNMP-backed RTS to pick up the SNMP credential changes

1. Scale the SNMP-backed RTS down.

    ```bash
    kubectl scale deployment cray-hms-rts-snmp -n services --replicas=0
    ```

1. Scale the SNMP-backed RTS up.

    ```bash
    kubectl scale deployment cray-hms-rts-snmp -n services --replicas=1
    ```
