# Update Default ServerTech PDU Credentials used by the Redfish Translation Service (RTS)

This procedure updates the default credentials used by the Redfish Translation Service (RTS) for when new ServerTech PDUs are discovered in a system.

The Redfish Translation Service provides a Redfish interface that the Hardware State Manager (HSM) and Cray Advanced Platform Monitoring and Control (CAPMC) services can use interact with ServerTech PDUs which do not natively support Redfish.

There are two sets of default credentials that are required for RTS to function:

1. The default credentials to use when new ServerTech PDUs are discovered in the system.
2. The global default credential that RTS uses for its Redfish interface with other CSM services.

**Important:**: After this procedure is completed **going forward all future ServerTech PDUs** added to the system will be assumed to be already configured with the new global default credential when getting added to the system.

**NOTE:** This procedure will not change the credentials on existing ServerTech PDUs in a system.
To change the credential on existing air-cooled hardware, follow the [Change Credentials on ServerTech PDUs](Change_Credentials_on_ServerTech_PDUs.md) procedure.
However, this procedure will update the global default credential that RTS uses for its Redfish interface to other CSM services.

## Procedure

Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure **with the following specifications**:

- Chart name: `cray-hms-rts`
- Base manifest name: `sysmgmt`
- When reaching the step to update the customizations, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    1. Clone the CSM repository.

        ```bash
        ncn-mw# git clone https://github.com/Cray-HPE/csm.git
        ```

    1. Copy the directory `vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils` from the cloned repository into the desired working directory.

        ```bash
        cp -vr ./csm/vendor/stash.us.cray.com/scm/shasta-cfg/stable/utils .
        ```

    1. Acquire sealed secret keys.

        ```bash
        ncn-mw# mkdir -pv certs
        ncn-mw# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/sealed_secrets.crt
        ncn-mw# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > certs/sealed_secrets.key
        ```

    1. Modify RTS sealed secret to use new global default credentials.

        1. Inspect the original default ServerTech PDU credentials.

            ```bash
            ncn-mw# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_pdu_defaults -r | base64 -d | jq
            ```

            Expected output looks similar to the following:

            ```json
            {
              "Username": "admn",
              "Password": "foo"
            }
            ```

        1. Inspect the original default RTS Redfish interface credentials.

            ```bash
            ncn-mw# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_rts_defaults -r | base64 -d | jq
            ```

            Expected output looks similar to the following:

            ```json
            {
              "Username": "root",
              "Password": "secret"
            }
            ```

        1. Update the default credentials in `customizations.yaml` for RTS.

            1. Specify the desired default ServerTech PDU credentials.

                ```bash
                ncn-mw# echo '{"Username":"admn", "Password":"foobar"}' | base64 > rts.pdu.creds.json.b64
                ```

            1. Specify the desired default RTS Redfish interface credentials.

                ```bash
                ncn-mw# echo '{"Username":"root", "Password":"supersecret"}' | base64 > rts.redfish.creds.json.b64
                ```

        1. Update and regenerate the `cray_hms_rts_credentials` sealed secret.

            ```bash
            ncn-mw# cat << EOF | yq w - 'data.vault_pdu_defaults' "$(<rts.pdu.creds.json.b64)" | yq w - 'data.vault_rts_defaults' "$(<rts.redfish.creds.json.b64)" | yq r -j - | ./utils/secrets-encrypt.sh | yq w -f - -i ./customizations.yaml 'spec.kubernetes.sealed_secrets.cray_hms_rts_credentials'
            {
                "kind": "Secret",
                "apiVersion": "v1",
                "metadata": {
                    "name": "cray-hms-rts-credentials",
                    "namespace": "services",
                    "creationTimestamp": null
                },
                "data": {}
            }
            EOF
            ```

        1. Decrypt generated secret for review.

            1. Review the default ServerTech PDU credentials.

                ```bash
                ncn-mw# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_pdu_defaults -r | base64 -d | jq
                ```

                Expected output looks similar to the following:

                ```json
                {
                  "Username": "admn",
                  "Password": "foobar"
                }
                ```

            1. Review the Default RTS Redfish interface credentials.

                ```bash
                ncn-mw# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_rts_defaults -r | base64 -d | jq
                ```

                Expected output looks similar to the following:

                ```json
                {
                  "Username": "root",
                  "Password": "supersecret"
                }
                ```

- When reaching the step to validate the redeployed chart, perform the following steps:

    **Only follow these steps as part of the previously linked chart redeploy procedure.**

    1. Wait for the RTS job to run to completion:

        ```bash
        ncn-mw# kubectl -n services wait job cray-hms-rts-init --for=condition=complete --timeout=5m
        ```

    1. Verify that the default ServerTech PDU credentials have updated in Vault.

        ```bash
        ncn-mw# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
        ncn-mw# kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/pdu-creds/global/pdu
        ```

        Expected output:

        ```text
        ====== Data ======
        Key         Value
        ---         -----
        Password    foobar
        Username    admn
        ```

    1. Verify that the default RTS Redfish interface credential has updated in Vault.

        ```bash
        ncn-mw# kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/pdu-creds/global/rts
        ```

        Expected output:

        ```text
        ====== Data ======
        Key         Value
        ---         -----
        Password    supersecret
        Username    root
        ```

- **Make sure to perform the entire linked procedure, including the step to save the updated customizations.**
