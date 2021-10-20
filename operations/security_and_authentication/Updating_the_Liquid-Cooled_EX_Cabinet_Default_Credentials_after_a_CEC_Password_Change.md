## Updating the Liquid-Cooled EX Cabinet CEC with Default Credentials after a CEC Password Change

This procedure changes the credential for liquid-cooled EX cabinet chassis controllers and node controller (BMCs) used by CSM services after the CECs have been set to a new global default credential.

**NOTE:** This procedure does not provision Slingshot switch BMCs (RouterBMCs). Slingshot switch BMC default credentials must be changed using the procedures in the Slingshot product documentation. To update Slingshot switch BMCs, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide* (1.6.0).

This procedure provisions only the default Redfish root account passwords. It does not modify Redfish accounts that have been added after an initial system installation.

### Prerequisites

- Perform procedures in [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md) on all CECs in the system.
- All of the CECs must be configured with the __same__ global credential.
- The previous default global credential for liquid-cooled BMCs needs to be known.

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
   > okay. If there are differences between what is in the repository and what
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
    REDFISH_ENDPOINTS=$(cray hsm inventory redfishEndpoints list --type '!RouterBMC' --format json | jq .RedfishEndpoints[].ID -r | sort -V )
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

    > Alternatively, use the following command on each BMC. Replace `BMC_XNAME` with the BMC xname to update the credentials:
    > ```bash
    > ncn-m001# cray hsm inventory redfishEndpoints update BMC_XNAME --user root --password ${CRED_PASSWORD}
    > ```

3. Wait for HSM to re-discover the updated RedfishEndpoints:
    ```bash
    ncn-m001# sleep 180
    ```

4. Wait for all updated Redfish endpoints to become `DiscoverOK`:
    
    The following bash script will find all Redfish endpoints for the liquid-cooled BMCs that are not in `DiscoverOK`, and display their last Discovery Status.
    ```bash
    ncn-m001# \
    cray hsm inventory redfishEndpoints list --laststatus '!DiscoverOK' --type '!RouterBMC' --format json > /tmp/redfishEndpoints.json
    cray hsm state components list --format json  > /tmp/components.json
    
    REDFISH_ENDPOINTS=$(jq .RedfishEndpoints[].ID -r /tmp/redfishEndpoints.json | sort -V)
    for RF in $REDFISH_ENDPOINTS; do
        CLASS=$(jq -r --arg XNAME "$RF" '.Components[] | select(.ID == $XNAME).Class' /tmp/components.json)
        if [[ "$CLASS" != "Mountain" ]]; then
            continue
        fi
        DISCOVERY_STATUS=$(jq -r --arg XNAME "$RF" '.RedfishEndpoints[] | select(.ID == $XNAME).DiscoveryInfo.LastDiscoveryStatus' /tmp/redfishEndpoints.json)
        echo "$RF: $DISCOVERY_STATUS"
    done
    ```

    Example output:
    ```
    x1001c0r5b0: HTTPsGetFailed
    x1001c1s0b0: HTTPsGetFailed
    x1001c1s0b1: HTTPsGetFailed
    x1001c2s0b1: DiscoveryStarted
    ```

    For each Redfish endpoint that is reported use the following to troubleshoot why it is not `DiscoverOK` or `DiscoveryStarted`:
    - If the Redfish endpoint is `DiscoveryStarted`, then that BMC is currently in the process of being inventoried by HSM. Wait a few minutes and re-try the bash script above to re-check the current discovery status of the RedfishEndpoints.
        > The hms-discovery cronjob (if enabled) will trigger a discover on BMCs that are not currently in `DiscoverOK` or `DiscoveryStarted` every 3 minutes.
    - If the Redfish endpoint is `HTTPsGetFailed`, then HSM had issues contacting BMC.
    
        1. Verify that the BMC xname is resolvable and pingable:
           > If the BMC is a ChassisBMC, then the `b0` in its xname needs to be removed to get its hostname. Otherwise, for NodeBMCs their xnames is their BMC hostname.
           > For example, the ChassisBMC has the xname `x1000c0b0`, and its hostname is `x1000c0`.
           > <!-- This changes in CSM 1.0, where the hostname for the ChassisBMC is its xname -->
           ```
           ncn-m001# ping x1001c1s0b0
           ```

        2. If a NodeBMC is not pingable, then verify that the slot powering the BMC is powered on. If this is a ChassisBMC, skip this step. For example, the NodeBMC x1001c1s0b0 is in slot x1001c1s0.
            ```bash
            ncn-m001# cray capmc get_xname_status create --xnames x1001c1s0
            e = 0
            err_msg = ""
            on = [ "x1001c1s0b0",]
            ```
    
            If the slot is off, power it on:
            ```bash
            ncn-m001# cray capmc xname_on create --xnames x1001c1s0
            ```
 
        3. If the BMC is reachable and in `HTTPsGetFailed`, then verify that the BMC is accessible with the new default global credential. Replace `BMC_HOSTNAME` with the hostname of the Redfish Endpoint. For a NodeBMC its hostname is its xname. For a ChassisBMC, then the `b0` in its xname needs to be removed to get its hostname.
            > For example, the ChassisBMC has the xname `x1000c0b0`, and its hostname is `x1000c0`.
            > <!-- In CSM 1.0 the hostname for a ChassisBMC matches its xname -->
            ```bash
            ncn-m001# curl -k -u root:$CRED_PASSWORD https://BMC_HOSTNAME/redfish/v1/Managers | jq
            ```

            If the error message below is returned, then the BMC needs to be have a StatefulReset action performed on it. The StatefulReset action will clear out any previously user defined credentials that are taking precedence over the CEC supplied credential. It will also clear out NTP, Syslog, and SSH Key configurations on the BMC.
    
            ```json
            {
                "error": {
                    "@Message.ExtendedInfo": [
                    {
                        "@odata.type": "#Message.v1_0_5.Message",
                        "Message": "While attempting to establish a connection to /redfish/v1/Managers, the service was denied access.",
                        "MessageArgs": [
                        "/redfish/v1/Managers"
                        ],
                        "MessageId": "Security.1.0.AccessDenied",
                        "Resolution": "Attempt to ensure that the URI is correct and that the service has the appropriate credentials.",
                        "Severity": "Critical"
                    }
                    ],
                    "code": "Security.1.0.AccessDenied",
                    "message": "While attempting to establish a connection to /redfish/v1/Managers, the service was denied access."
                }
            }
            ```

            Perform a StatefulReset on the liquid-cooled BMC replace `BMC_HOSTNAME` with the hostname of the BMC. The `OLD_DEFAULT_PASSWORD` needs to match the credential that was perviously set on the BMC. This is mostly likely to be the pervious global default credential for liquid-cooled BMCs.
            ```bash
            ncn-m001# curl -k -u root:OLD_DEFAULT_PASSWORD -X POST -H 'Content-Type: application/json' -d \
            '{"ResetType": "StatefulReset"}' \
            https://BMC_HOSTNAME/redfish/v1/Managers/BMC/Actions/Manager.Reset
            ```

            After the StatefulReset action has been issued, the BMC will be unreachable for a few minutes as it performs the StatefulReset.

### 3. Reapply BMC settings if a StatefullReset was performed on any BMC.
This section only needs to be performed if any liquid-cooled Node or Chassis BMCs that had to be StatefulReset.

1. For each liquid-cooled BMC that the StatefulReset action was applied delete the BMC from HSM. Replace `BMC_XNAME` with the BMC xname to delete.
    > ```bash
    > ncn-m001# cray hsm inventory redfishEndpoints delete BMC_XNAME
    > ```

2. Restart MEDS to re-setup the NTP and Syslog configuration the RedfishEndpoints:

    View Running MEDS pods:
    ```bash
    ncn-m001# kubectl -n services get pods -l app.kubernetes.io/instance=cray-hms-meds
    NAME                         READY   STATUS    RESTARTS   AGE
    cray-meds-6d8b5875bc-4jngc   2/2     Running   0          17d
    ```

    Restart MEDS:
    ```bash
    ncn-m001# kubectl -n services rollout restart deployment cray-meds
    ncn-m001# kubectl -n services rollout status deployment cray-meds
    ```

3. Wait for MEDS to re-discover the deleted RedfishEndpoints:
    ```bash
    ncn-m001# sleep 300
    ```

4. Verify all expected hardware has been discovered:
   
    The following bash script will find all Redfish endpoints for the liquid-cooled BMCs that are not in `DiscoverOK`, and display their last Discovery Status.
    ```bash
    ncn-m001# \
    cray hsm inventory redfishEndpoints list --laststatus '!DiscoverOK' --type '!RouterBMC' --format json > /tmp/redfishEndpoints.json
    cray hsm state components list --format json  > /tmp/components.json
   
    REDFISH_ENDPOINTS=$(jq .RedfishEndpoints[].ID -r /tmp/redfishEndpoints.json | sort -V)
    for RF in $REDFISH_ENDPOINTS; do
        CLASS=$(jq -r --arg XNAME "$RF" '.Components[] | select(.ID == $XNAME).Class' /tmp/components.json)
        if [[ "$CLASS" != "Mountain" ]]; then
            continue
        fi
        DISCOVERY_STATUS=$(jq -r --arg XNAME "$RF" '.RedfishEndpoints[] | select(.ID == $XNAME).DiscoveryInfo.LastDiscoveryStatus' /tmp/redfishEndpoints.json)
        echo "$RF: $DISCOVERY_STATUS"
    done
    ```

5. Restore SSH Keys configured by cray-conman on liquid-cooled Node BMCs.
    <!-- This step is only applicable to CSM 0.9, and will be different in CSM 1.0 -->
    View the current status of the cray-conman pods:
    ```bash
    ncn-m001# kubectl -n services get pods -l app.kubernetes.io/instance=cray-conman
    NAME                           READY   STATUS    RESTARTS   AGE
    cray-conman-7f956fc9bc-97rx4   3/3     Running   0          47d
    ```

    Restart cray-conman deployment:
    ```bash
    ncn-m001# kubectl -n services rollout restart deployment cray-conman
    ncn-m001# kubectl -n services rollout status deployment cray-conman
    ```

6. Restore passwordless SSH connections to the liquid-cooled Node BMCs that have had the StatefulReset applied to them by following the procedure `30.23 Enable Passwordless Connections to Liquid Cooled Node BMCs` of the _HPE Cray EX System Administration Guide 1.4 S-80001_.
    > __WARNING__: If an admin uses SCSD to update the SSHConsoleKey value outside of ConMan, it will disrupt the ConMan connection to the console and collection of console logs.
    > Refer to "About the ConMan Containerized Service" in the _HPE Cray EX System Administration Guide 1.4 S-8001_.

7. Restore passwordless SSH connections to the liquid-cooled Chassis BMCs that have had the SateFulReset applied to them. Follow the steps below for each Chassis BMC that was StatefulReset:
    <!-- This step is only applicable to CSM 0.9, and not required in CSM 1.0 as SCSD is able to manage ChassisBMCs -->
    1. Save the public SSH key for the root user.
        ```bash
        ncn-m001# export SSH_PUBLIC_KEY=$(cat /root/.ssh/id_rsa.pub | sed 's/[[:space:]]*$//')
        ```

    2. Enable passwordless SSH to the root user of the BMCs. Skip this step if passwordless SSH to the root user is not desired. Replace `BMC_HOSTNAME` with the hostname name of the Chassis BMC. The hostname of a ChassisBMC is its xname with the ending `b0` removed.
        ```bash
        ncn-m001# curl -k -u root:$CRED_PASSWORD -X PATCH https://BMC_HOSTNAME/redfish/v1/Managers/BMC/NetworkProtocol \
            -H 'Content-Type: application/json' \
            -d "{\"Oem\":{\"SSHAdmin\":{\"AuthorizedKeys\":\"ssh-rsa $SSH_PUBLIC_KEY\"}}}"
        ```

    3. Enable passwordless SSH to the consoles on the BMCs. Skip this step if passwordless SSH to the root user is not desired. Replace `BMC_HOSTNAME` with the hostname name of the Chassis BMC. The hostname of a ChassisBMC is its xname with the ending `b0` removed.
        ```bash
        ncn-m001# curl -k -u root:$CRED_PASSWORD -X PATCH https://BMC_HOSTNAME/redfish/v1/Managers/BMC/NetworkProtocol \
            -H 'Content-Type: application/json' \
            -d "{\"Oem\":{\"SSHConsole\":{\"AuthorizedKeys\":\"ssh-rsa $SSH_PUBLIC_KEY\"}}}"
        ```
