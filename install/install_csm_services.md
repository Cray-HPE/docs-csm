# Install CSM Services

This procedure will install CSM applications and services into the CSM Kubernetes cluster.

> **`NOTE`** Check the information in [Known issues](#known-issues) before starting this procedure
> to be warned about possible problems.

1. [Install CSM services](#1-install-csm-services)
1. [Create base BSS global boot parameters](#2-create-base-bss-global-boot-parameters)
1. [Adding Switch Admin Password to Vault](#3-adding-switch-admin-password-to-vault)
1. [Wait for everything to settle](#4-wait-for-everything-to-settle)
1. [Next topic](#next-topic)
1. [Known issues](#known-issues)
    1. [`Deploy CSM Applications and Services` known issues](#deploy-csm-applications-and-services-known-issues)
    1. [`Setup Nexus` known issues](#setup-nexus-known-issues)

## 1. Install CSM services

> **`NOTE`**: During this step, only on systems with only three worker nodes (typically Testing and
> Development Systems (TDS)), the `customizations.yaml` file will be automatically edited to lower
> pod
> CPU requests for some services, in order to better facilitate scheduling on smaller systems. See
> the
> file `${CSM_PATH}/tds_cpu_requests.yaml` for these settings. This file can be modified with
> different values (prior to executing the `yapl` command below), if other settings are desired in
> the `customizations.yaml` file for this system. For more information about
> modifying `customizations.yaml` and tuning for specific systems,
> see [Post-Install Customizations](../operations/CSM_product_management/Post_Install_Customizations.md).

1. (`pit#`) Install YAPL.

   ```bash
   rpm -Uvh "${CSM_PATH}"/rpm/cray/csm/sle-15sp2/x86_64/yapl-*.x86_64.rpm
   ```

1. (`pit#`) Install CSM services using YAPL.

   ```bash
   pushd /usr/share/doc/csm/install/scripts/csm_services
   yapl -f install.yaml execute
   popd
   ```

   > **`NOTE`**
   >
   > * This command may take up to 90 minutes to complete.
   > * If any errors are encountered, then potential fixes should be displayed where the error
       occurred.
   > * If you are prompted for a password, this is the password for the PIT node (`ncn-m001`). Enter the password to continue.
   > * Output is redirected to `/usr/share/doc/csm/install/scripts/csm_services/yapl.log` . To show
       the output in the terminal, append the `--console-output execute` argument to the `yapl`
       command.
   > * The `yapl` command can safely be rerun. By default, it will skip any steps which were
       previously completed successfully. To force it to rerun all steps regardless of what was
       previously completed, append the `--no-cache`
       argument to the `yapl` command.
   > * The order of the `yapl` command arguments is important. The syntax
       is `yapl -f install.yaml [--console-output] execute [--no-cache]`.

## 2. Create base BSS global boot parameters

1. (`pit#`) Wait for BSS to be ready.

   ```bash
   kubectl -n services rollout status deployment cray-bss
   ```

1. (`pit#`) Retrieve an API token.

   ```bash
   export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                     -d client_id=admin-client \
                     -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                     https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. (`pit#`) Create empty boot parameters:

   ```bash
   curl -i -k -H "Authorization: Bearer ${TOKEN}" -X PUT \
       https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters \
       --data '{"hosts":["Global"]}'
   ```

   Example of successful output:

   ```text
   HTTP/2 200
   content-type: application/json; charset=UTF-8
   date: Mon, 27 Jun 2022 17:08:55 GMT
   content-length: 0
   x-envoy-upstream-service-time: 7
   server: istio-envoy
   ```

1. (`pit#`) Restart the `cray-spire-update-bss` job.

   ```bash
   SPIRE_JOB=$(kubectl -n spire get jobs -l app.kubernetes.io/name=cray-spire-update-bss -o name)
   kubectl -n spire get "${SPIRE_JOB}" -o json | jq 'del(.spec.selector)' \
       | jq 'del(.spec.template.metadata.labels."controller-uid")' \
       | kubectl replace --force -f -
   ```

1. (`pit#`) Wait for the `cray-spire-update-bss` job to complete.

   ```bash
   kubectl -n spire wait "${SPIRE_JOB}" --for=condition=complete --timeout=5m
   ```

## 3. Adding Switch Admin Password to Vault

If CSM has been installed and Vault is running, add the switch credentials into Vault. Certain
tests, including `goss-switch-bgp-neighbor-aruba-or-mellanox` use these credentials to test the
state of the switch. This step is not required to configure the management network. If Vault is
unavailable, this step can be temporarily skipped. Any automated tests that depend on the switch
credentials being in Vault will fail until they are added.

First, write the switch admin password to the `SW_ADMIN_PASSWORD` variable if it is not already
set.

```bash
read -s SW_ADMIN_PASSWORD
```

Once the `SW_ADMIN_PASSWORD` variable is set, run the following commands to add the switch admin
password to Vault.

```bash
VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' |  base64 -d)
alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
vault kv put secret/net-creds/switch_admin admin=$SW_ADMIN_PASSWORD
```

Note: The use of `read -s` is a convention used throughout this documentation which allows for the
user input of secrets without echoing them to the terminal or saving them in history.

## 4. Wait for everything to settle

Wait **at least 15 minutes** to let the various Kubernetes resources initialize and start before
proceeding with the rest of the install.
Because there are a number of dependencies between them, some services are not expected to work
immediately after the install script completes.

1. After having waited until services are healthy (
   run `kubectl get po -A | grep -v 'Completed\|Running'` to see which pods may still be `Pending`),
   take a manual backup of all Etcd clusters.
   These clusters are automatically backed up every 24 hours, but not until the clusters have been
   up that long.
   Taking a manual backup enables restoring from backup later in this install process if needed.

   ```bash
   /usr/share/doc/csm/scripts/operations/etcd/take-etcd-manual-backups.sh post_install
   ```

1. The next step is to validate CSM health before redeploying the final NCN.
   See [Validate CSM health before final NCN deployment](./README.md#3-validate-csm-health-before-final-ncn-deployment).

## Next Topic

After installing CSM, proceed
to [validate CSM health before final NCN deployment](./README.md#3-validate-csm-health-before-final-ncn-deployment).

## Known issues

### `Deploy CSM Applications and Services` known issues

The following error may occur during the `Deploy CSM Applications and Services` step:

```text
+ csi upload-sls-file --sls-file /var/www/ephemeral/prep/eniac/sls_input_file.json
2021/10/05 18:42:58 Retrieving S3 credentials ( sls-s3-credentials ) for SLS
2021/10/05 18:42:58 Unable to SLS S3 secret from k8s:secrets "sls-s3-credentials" not found
```

1. (`pit#`) Verify that the `sls-s3-credentials` secret exists in the `default` namespace:

   ```bash
   kubectl get secret sls-s3-credentials
   ```

   Example output:

   ```text
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      28d
   ```

1. (`pit#`) Check for running `sonar-sync` jobs. If there are no `sonar-sync` jobs, then wait for
   one to complete. The `sonar-sync` `CronJob` is responsible
   for copying the `sls-s3-credentials` secret from the `default` namespace to the `services`
   namespace.

   ```bash
   kubectl -n services get pods -l cronjob-name=sonar-sync
   ```

   Example output:

   ```text
   NAME                          READY   STATUS      RESTARTS   AGE
   sonar-sync-1634322840-4fckz   0/1     Completed   0          73s
   sonar-sync-1634322900-pnvl6   1/1     Running     0          13s
   ```

1. (`pit#`) Verify that the `sls-s3-credentials` secret now exists in the `services` namespace.

   ```bash
   kubectl -n services get secret sls-s3-credentials
   ```

   Example output:

   ```text
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      20s
   ```

1. Running the `yapl` command again is expected to succeed.

### `Setup Nexus` known issues

Known potential issues along with suggested fixes are listed
in [Troubleshoot Nexus](../operations/package_repository_management/Troubleshoot_Nexus.md).
