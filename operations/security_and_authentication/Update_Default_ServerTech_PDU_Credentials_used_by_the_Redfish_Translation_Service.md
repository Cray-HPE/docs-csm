# Update Default ServerTech PDU Credentials used by the Redfish Translation Service (RTS)

This procedure updates the default credentials used by the Redfish Translation Service (RTS) for when new ServerTech PDUs are discovered in a system.

The Redfish Translation Service provides a Redfish interface that the Hardware State Manager (HSM) and Cray Advanced Platform Monitoring and Control (CAPMC) services can use interact with ServerTech PDUs which do not natively support Redfish. 

There are two sets of default credentials that are required for RTS to function:
1. The default credentials to use when new ServerTech PDUs are discovered in the system.
2. The global default credential that RTS uses for its Redfish interface with other CSM services.

**Important:**: After this procedure is completed **going forward all future ServerTech PDUs** added to the system will be assumed to be already configured with the new global default credential when getting added to the system.

**NOTE:** This procedure will not change the credentials on existing ServerTech PDUs in a system. To change the credential on existing air-cooled hardware, follow the [Change Credentials on ServerTech PDUs](Change_Credentials_on_ServerTech_PDUs.md) procedure. However, this procedure will update the global default credential that RTS uses for its Redfish interface to other CSM services.

## Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

## Procedure

#### 1.1 Acquire site-init.
Before redeploying RTS, update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1.  If the `site-init` repository is available as a remote repository [as described here](../../install/prepare_site_init.md#push-to-a-remote-repository), then clone it to `ncn-m001`. Otherwise, ensure that the `site-init` repository is available on `ncn-m001`.

    ```bash
    ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
    ```

2.  Acquire `customizations.yaml` from the currently running system:

    ```bash
    ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
    ```

3.  Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

    > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
    > there may not be any differences and hence nothing to commit. This is
    > okay. If there are differences between what is in the repository and what
    > was stored in the `site-init`, then it suggests settings were changed at some
    > point.
    ```bash
    ncn-m001# cd site-init
    ncn-m001# git diff
    ncn-m001# git add customizations.yaml
    ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
    ```

4.  Acquire sealed secret keys:
    ```bash
    ncn-m001# mkdir -p certs
    ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/sealed_secrets.crt
    ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > certs/sealed_secrets.key
    ```

#### 1.2 Modify RTS sealed secret to use new global default credentials.
1.  Inspect the original default ServerTech PDU credentials:
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_pdu_defaults -r | base64 -d | jq
    {
      "Username": "admn",
      "Password": "foo"
    }
    ```

2.  Inspect the original default RTS Redfish Interface credentials:
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_rts_defaults -r | base64 -d | jq
    {
      "Username": "root",
      "Password": "secret"
    }
    ```

2.  Update the default credentials in `customizations.yaml` for RTS:
    
    Specify the desired default ServerTech PDU credentials:
    ```bash
    ncn-m001# echo '{"Username":"admn", "Password":"foobar"}' | base64 > rts.pdu.creds.json.b64
    ```

    Specify the desired default RTS Redfish interface credentials:
    ```bash
    ncn-m001# echo '{"Username":"root", "Password":"supersecret"}' | base64 > rts.redfish.creds.json.b64
    ```


    Update and regenerate `cray_hms_rts_credentials` sealed secret:
    ```bash
    ncn-m001# cat << EOF | yq w - 'data.vault_pdu_defaults' "$(<rts.pdu.creds.json.b64)" | yq w - 'data.vault_rts_defaults' "$(<rts.redfish.creds.json.b64)" | yq r -j - | ./utils/secrets-encrypt.sh | yq w -f - -i ./customizations.yaml 'spec.kubernetes.sealed_secrets.cray_hms_rts_credentials'
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

4.  Decrypt generated secret for review.
    
    Default ServerTech PDU credentials:
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_pdu_defaults -r | base64 -d | jq
    {
      "Username": "admn",
      "Password": "foobar"
    }
    ```

    Default RTS Redfish interface credentials:
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_hms_rts_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_rts_defaults -r | base64 -d | jq
    {
      "Username": "root",
      "Password": "supersecret"
    }
    ```


5.  Update the site-init secret for the system:
    ```bash
    ncn-m001# kubectl delete secret -n loftsman site-init
    ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    ```

#### 1.3 Redeploy RTS to pick up the new sealed secret and push credentials into vault.
1.  Determine the version of RTS:
    ```bash
    ncn-m001# RTS_VERSION=$(kubectl -n loftsman get cm loftsman-core-services -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-rts).version')
    ncn-m001# echo $RTS_VERSION
    ```

2.  Create `rts-manifest.yaml`:
    ```bash
    ncn-m001# cat > rts-manifest.yaml << EOF 
    apiVersion: manifests/v1beta1
    metadata:
        name: rts
    spec:
        charts:
        - name: cray-hms-rts
          version: $RTS_VERSION
          namespace: services
    EOF
    ```

2.  Merge `customizations.yaml` with `rts-manifest.yaml`:
    ```bash
    ncn-m001# manifestgen -c customizations.yaml -i ./rts-manifest.yaml > ./rts-manifest.out.yaml
    ```

3.  Redeploy the RTS helm chart:
    ```bash
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path rts-manifest.out.yaml
    ```

5.  Wait for the RTS Init job to run to completion:
    ```bash
    ncn-m001# kubectl -n services wait job  cray-hms-rts-init --for=condition=complete --timeout=5m
    ```

6.  Verify the default ServerTech PDU credentials have updated in Vault:
    ```bash
    ncn-m001# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-m001# kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/pdu-creds/global/pdu
    ```

    Expected output:
    ```
    ====== Data ======
    Key         Value
    ---         -----
    Password    foobar
    Username    admn
    ```

7.  Verify that default RTS Redfish interface credential has updated in Vault:

    ```bash
    ncn-m001# kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/pdu-creds/global/rts
    ```

    Expected output:
    ```
    ====== Data ======
    Key         Value
    ---         -----
    Password    supersecret
    Username    root
    ```
