# Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials

This procedure updates the default credentials used when new air-cooled hardware is discovered for the first time. This includes the default Redfish credentials used for
new air-cooled `NodeBMCs` and Slingshot switch BMCs (`RouterBMCs`), and SNMP credentials for new management leaf-BMC switches.

***IMPORTANT*** After this procedure is completed, **all future air-cooled hardware** added to the system will be assumed to be configured with the new global default credential.

> ***NOTE*** This procedure will not update the Redfish or SNMP credentials for existing air-cooled devices. To change the credentials on existing air-cooled hardware follow the
> [Change Air-Cooled Node BMC Credentials](Change_Air-Cooled_Node_BMC_Credentials.md) and [Configuring SNMP in CSM]( ../../operations/network/management_network/configure_snmp.md) procedures.

## Limitation

The default global credentials used for liquid-cooled BMCs in the [Change Cray EX Liquid-Cooled Cabinet Global Default Password](Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md)
procedure needs to be the same as the one used in this procedure for air-cooled BMCs river hardware.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

## Procedure

### 1.1 Acquire `site-init`

Before redeploying the River Endpoint Discovery Service (REDS), update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1. If the `site-init` repository is available as a remote repository, then clone it to `ncn-m001`. Otherwise, ensure that the `site-init` repository is available on `ncn-m001`.

    ```bash
    git clone "$SITE_INIT_REPO_URL" site-init
    ```

1. Acquire `customizations.yaml` from the currently running system:

    ```bash
    kubectl get secrets -n loftsman `site-init` -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
    ```

1. Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

    > **`NOTE`** If `site-init` was cloned from a remote repository in step 1,
    > there may not be any differences and hence nothing to commit. This is
    > okay. If there are differences between what is in the repository and what
    > was stored in the `site-init`, then it suggests settings were changed at some
    > point.

    ```bash
    cd site-init
    git diff
    git add customizations.yaml
    git commit -m 'Add customizations.yaml from site-init secret'
    ```

1. Acquire sealed secret keys:

    ```bash
    mkdir -p certs
    kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/sealed_secrets.crt
    kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > certs/sealed_secrets.key
    ```

### 1.2 Modify REDS sealed secret to use new global default credentials

1. Inspect the original default Redfish credentials used by REDS and HMS Discovery:

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

1. Inspect the original default switch SNMP credentials used by REDS and HMS Discovery:

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

1. Update the default credentials in `customizations.yaml` for REDS and HMS Discovery to use:

    Specify the desired default Redfish credentials:

    ```bash
    echo '{"Cray":{"Username":"root","Password":"foobar"}}' | base64 > reds.redfish.creds.json.b64
    ```

    Specify the desired default SNMP credentials:

    ```bash
    echo '{"SNMPUsername":"testuser","SNMPAuthPassword":"foo1","SNMPPrivPassword":"bar2"}' | base64 > reds.switch.creds.json.b64
    ```

    Update and regenerate `cray_reds_credentials` sealed secret:

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

    Default Redfish credentials:

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

    Default Switch SNMP credentials:

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

1. Update the `site-init` secret for the system:

    ```bash
    kubectl delete secret -n loftsman site-init
    kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    ```

### 1.3 Redeploy REDS to pick up the new sealed secret and push credentials into vault

1. Determine the version of REDS:

    ```bash
    REDS_VERSION=$(kubectl -n loftsman get cm loftsman-core-services -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-reds).version')
    echo $REDS_VERSION
    ```

1. Create `reds-manifest.yaml`:

    ```bash
    cat > reds-manifest.yaml << EOF
    apiVersion: manifests/v1beta1
    metadata:
        name: reds
    spec:
        charts:
        - name: cray-hms-reds
          version: $REDS_VERSION
          namespace: services
    EOF
    ```

1. Merge `customizations.yaml` with `reds-manifest.yaml`:

    ```bash
    manifestgen -c customizations.yaml -i ./reds-manifest.yaml > ./reds-manifest.out.yaml
    ```

1. Redeploy the REDS helm chart:

    ```bash
    loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path reds-manifest.out.yaml
    ```

1. Wait for the REDS Vault loader job to run to completion:

    ```bash
    kubectl -n services wait job cray-reds-vault-loader --for=condition=complete --timeout=5m
    ```

1. Verify the default Redfish credentials have updated in Vault:

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

1. Verify the default SNMP credentials have updated in Vault:

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
