# Install CSM Services

This procedure will install CSM applications and services into the CSM Kubernetes cluster.

> **NOTE:** Check the information in [Known Issues](#known-issues) before starting this procedure to be warned about possible problems.

1. [Install YAPL](#install-yapl)
1. [Install CSM services](#install-csm-services)
1. [Create base BSS global boot parameters](#create-base-bss-global-boot-parameters)
1. [Wait for everything to settle](#wait-for-everything-to-settle)
1. [Known issues](#known-issues)
    * [`Deploy CSM Applications and Services` known issues](#known-issues-install-sh)
    * [`Setup Nexus` known issues](#known-issues-setup-nexus)
1. [Next topic](#next-topic)

<a name="install-yapl"></a>

## 1. Install YAPL

```bash
pit# rpm -Uvh /var/www/ephemeral/${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/yapl-*.x86_64.rpm
```

<a name="install-csm-services"></a>

## 2. Install CSM services

> **NOTE**: During this step, only on systems with only three worker nodes (typically Testing and  Development Systems (TDS)), the `customizations.yaml` file will be
> automatically edited to lower pod CPU requests for some services, in order to better facilitate scheduling on smaller systems. See the file:
> `/var/www/ephemeral/${CSM_RELEASE}/tds_cpu_requests.yaml` for these settings. This file can be modified with different values (prior to executing the
> `yapl` command below), if other settings are desired in the `customizations.yaml` file for this system. For more information about modifying `customizations.yaml`
> and tuning for specific systems, see
> [Post Install Customizations](../operations/CSM_product_management/Post_Install_Customizations.md).

Install CSM services using `yapl`:

```bash
pit# pushd /usr/share/doc/csm/install/scripts/csm_services && \
     yapl -f install.yaml execute
pit# popd
```

> **NOTES:**
>
> * This command may take up to 90 minutes to complete.
> * If any errors are encountered, then potential fixes should be displayed where the error occurred.
> * If the installation fails with a missing secret error message, then see [CSM Services Install Fails Because of Missing Secret](csm_installation_failure.md).
> * Output is redirected to `/usr/share/doc/csm/install/scripts/csm_services/yapl.log` . To show the output in the terminal, append
>   the `--console-output execute` argument to the `yapl` command.
> * The `yapl` command can safely be rerun. By default, it will skip any steps which were previously completed successfully. To force it to
>   rerun all steps regardless of what was previously completed, append the `--no-cache` argument to the `yapl` command.

<a name="create-base-bss-global-boot-parameters"></a>

## 3. Create base BSS global boot parameters

1. Wait for BSS to be ready.

   ```bash
   pit# kubectl -n services rollout status deployment cray-bss
   ```

1. Retrieve an API token.

   ```bash
   pit# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

1. Create empty boot parameters.

   ```bash
   pit# curl -i -k -H "Authorization: Bearer ${TOKEN}" -X PUT \
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

1. Restart the `spire-update-bss` job.

   ```bash
   pit# SPIRE_JOB=$(kubectl -n spire get jobs -l app.kubernetes.io/name=spire-update-bss -o name)
   pit# kubectl -n spire get $SPIRE_JOB -o json | jq 'del(.spec.selector)' \
            | jq 'del(.spec.template.metadata.labels."controller-uid")' \
            | kubectl replace --force -f -
   ```

1. Wait for the `spire-update-bss` job to complete.

   ```bash
   pit# kubectl -n spire wait  $SPIRE_JOB --for=condition=complete --timeout=5m
   ```

<a name="wait-for-everything-to-settle"></a>

## 4. Wait for everything to settle

Wait **at least 15 minutes** to let the various Kubernetes resources initialize and start before proceeding with the rest of the install.
Because there are a number of dependencies between them, some services are not expected to work immediately after the install script completes.

<a name="known-issues"></a>

## 5. Known issues

<a name="known-issues-install-sh"></a>

### 5.1 `Deploy CSM Applications and Services` known issues

The following error may occur during the `Deploy CSM Applications and Services` step:

```text
+ csi upload-sls-file --sls-file /var/www/ephemeral/prep/eniac/sls_input_file.json
2021/10/05 18:42:58 Retrieving S3 credentials ( sls-s3-credentials ) for SLS
2021/10/05 18:42:58 Unable to SLS S3 secret from k8s:secrets "sls-s3-credentials" not found
```

1. Verify that the `sls-s3-credentials` secret exists in the `default` namespace:

   ```bash
   pit# kubectl get secret sls-s3-credentials
   ```

   Example output:

   ```text
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      28d
   ```

1. Check for running `sonar-sync` jobs. If there are no `sonar-sync` jobs, then wait for one to complete. The `sonar-sync` `CronJob` is responsible
   for copying the `sls-s3-credentials` secret from the `default` namespace to the `services` namespace.

   ```bash
   pit# kubectl -n services get pods -l cronjob-name=sonar-sync
   ```

   Example output:

   ```text
   NAME                          READY   STATUS      RESTARTS   AGE
   sonar-sync-1634322840-4fckz   0/1     Completed   0          73s
   sonar-sync-1634322900-pnvl6   1/1     Running     0          13s
   ```

1. Verify that the `sls-s3-credentials` secret now exists in the `services` namespace.

   ```bash
   pit# kubectl -n services get secret sls-s3-credentials
   ```

   Example output:

   ```text
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      20s
   ```

1. Running the `yapl` command again is expected to succeed.

<a name="known-issues-setup-nexus"></a>

### 5.2 `Setup Nexus` known issues

Known potential issues along with suggested fixes are listed in [Troubleshoot Nexus](../operations/package_repository_management/Troubleshoot_Nexus.md).

<a name="next-topic"></a>

## 6. Next Topic

The next step is to validate CSM health before redeploying the final NCN.

See [Validate CSM Health Before Final NCN Deployment](index.md#validate_csm_health_before_final_ncn_deploy).
