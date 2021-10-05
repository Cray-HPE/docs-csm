## Updating the Liquid-Cooled EX Cabinet CEC with Default Credentials

This procedure changes the credential for liquid-cooled EX cabinet chassis controllers and node controller (BMCs) used by CSM services after the CECs have been set to a new global default credential. 

**NOTE:** This procedure does not provision Slingshot switch BMCs. Slingshot switch BMC default credentials must be changed using the procedures in the Slingshot product documentation. Refer to "Change Switch BMC Passwords" in the Slingshot product documentation for more information. 

This procedure provisions only the default Redfish root account passwords. It does not modify Redfish accounts that have been added after an initial system installation.

### Prerequisites

- Perform procedures in [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default Credentials.md) to all CECs in the system.  
- All of the CECs must be configured to the __same__ global credential.

### Procedure

### 1. Update the Default credentials used by MEDS for new hardware.

The MEDS sealed secret contains the default global credential used by MEDS when it discovers new liquid-cooled EX cabinet hardware.

#### 1.1 Acquire site-init.
Before redeploying MEDS, update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1. If the `site-init` repository is available as a remote repository, then clone it on the host orchestrating the upgrade [as described here](https://github.com/Cray-HPE/docs-csm/blob/main/install/prepare_site_init.md#5-version-control-site-init-files).

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

2. Acquire `customizations.yaml` from the currently running system:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

3. Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what's in the repository and what
   > was stored in the `site-init`, then it suggests settings were changed at some 
   > point.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

4. Acquire sealed secret keys:
    ```bash
    ncn-m001# mkdir -p certs
    ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > certs/sealed_secrets.crt
    ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d > certs/sealed_secrets.key
    ```

#### 1.2 Modify MEDS sealed secret to use new global default credential.

1. Inspect the original default credentials for MEDS:
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults -r | base64 -d | jq
    ```

    ```json
    {
        "Username": "root",
        "Password": "bar"
    }
    ```

2. Specify the desired default credentials for MEDS to use with new hardware:
    > Replace `foobar` with the root password configured on the CEC(s).
    ```bash
    ncn-m001# echo '{ "Username": "root", "Password": "foobar" }' | base64 > creds.json.b64
    ```

3. Update and regenerate the `cray_meds_credentials` sealed secret:
    ```bash
    ncn-m001# cat << EOF | yq w - 'data.vault_redfish_defaults' "$(<creds.json.b64)" | yq r -j - | ./utils/secrets-encrypt.sh | yq w -f - -i ./customizations.yaml 'spec.kubernetes.sealed_secrets.cray_meds_credentials'
    {
        "kind": "Secret",
        "apiVersion": "v1",
        "metadata": {
            "name": "cray-meds-credentials",
            "namespace": "services",
            "creationTimestamp": null
        },
        "data": {}
    }
    EOF
    ```

4. Decrypt updated sealed secret for review. The sealed secret should match the credentials set on the CEC.
    ```bash
    ncn-m001# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults -r | base64 -d | jq
    ```

    ```json
    {
        "Username": "root",
        "Password": "foobar"
    }
    ```

5. Update the site-init secret containing `customizations.yaml` for the system:
    ```bash
    ncn-m001# kubectl delete secret -n loftsman site-init
    ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    ```

6. Check in changes made to `customizations.yaml`
    ```bash
    ncn-m001# git diff
    ncn-m001# git add customizations.yaml
    ncn-m001# git commit -m 'Update customizations.yaml with global default credential for MEDS'
    ```

7. Push to the remote repository as appropriate:
    ```bash
    ncn-m001# git push
    ```

#### 1.3 Redeploy MEDS to pick up the new sealed secret and push credentials into vault.
1. Determine the version of MEDS:
    ```bash
    ncn-m001# MEDS_VERSION=$(kubectl -n loftsman get cm loftsman-core-services -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-hms-meds).version')
    ncn-m001# echo $MEDS_VERSION
    ```

2. Create `meds-manifest.yaml`:
    ```bash
    ncn-m001# cat > meds-manifest.yaml << EOF 
    apiVersion: manifests/v1beta1
    metadata:
        name: meds
    spec:
        charts:
        - name: cray-hms-meds
          version: $MEDS_VERSION
          namespace: services
    EOF
    ```

3. Merge `customizations.yaml` with `meds-manifest.yaml`:
    ```bash
    ncn-m001# manifestgen -c customizations.yaml -i ./meds-manifest.yaml > ./meds-manifest.out.yaml
    ```

4. Redeploy the MEDS helm chart:
    ```bash
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path meds-manifest.out.yaml
    ```

5. Wait for the MEDS Vault loader job to run to completion:
    ```bash
    ncn-m001# kubectl wait -n services job cray-meds-vault-loader --for=condition=complete --timeout=5m
    ```

6. Verify the default credentials have changed in Vault:
    ```bash
    ncn-m001# VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
    ncn-m001# kubectl -n vault exec -it cray-vault-0 -c vault -- env VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 vault kv get secret/meds-cred/global/ipmi
    ```

    ```
    ====== Data ======
    Key         Value
    ---         -----
    Password    foobar
    Username    root
    ```

### 2. Update credentials for existing EX hardware in the system
1. Set `CRED_PASSWORD` to the new updated password:
    ```bash
    ncn-m001# CRED_PASSWORD=foobar
    ```

2. Update the credentials used by CSM services for all previously discovered EX cabinet BMCs to the new global default:
    ```bash
    ncn-m001# \
    REDFISH_ENDPOINTS=$(cray hsm inventory redfishEndpoints list --format json | jq .RedfishEndpoints[].ID -r | sort -V )
    cray hsm state components list --format json  > /tmp/components.json
    
    for RF in $REDFISH_ENDPOINTS; do
        echo "$RF: Checking..."
        CLASS=$(jq -r --arg XNAME "$RF" '.Components[] | select(.ID == $XNAME).Class' /tmp/components.json)
        if [[ "$CLASS" != "Mountain" ]]; then
            echo "$RF is not Mountain, skipping..."
            continue
        fi
        echo "$RF: Updating credentials"
        cray hsm inventory redfishEndpoints update ${RF} --user root --password ${CRED_PASSWORD}
    done
    ```

    It will take some time for the above bash script to run. It will take approximately 5 minutes to update all of the credentials for a single fully populated cabinet.

    > Alternatively, use the following command on each BMC. Replace `<BMC>` with the BMC xname to update the credentials:
    > ```bash
    > ncn-m001# cray hsm inventory redfishEndpoints update <BMC> --user root --password ${CRED_PASSWORD}
    > ```