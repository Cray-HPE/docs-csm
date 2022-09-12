# Install CSM Services

This procedure will install CSM applications and services into the CSM Kubernetes cluster.

> **NOTE:** Check the information in [Known issues](#known-issues) before starting this procedure to be warned about possible problems.

1. [Install CSM services](#1-install-csm-services)
1. [Create base BSS global boot parameters](#2-create-base-bss-global-boot-parameters)
1. [Wait for everything to settle](#3-wait-for-everything-to-settle)
1. [Next topic](#4-next-topic)

* [Known issues](#known-issues)
  * [`Deploy CSM Applications and Services` known issues](#deploy-csm-applications-and-services-known-issues)
  * [`Setup Nexus` known issues](#setup-nexus-known-issues)

## 1. Install CSM services

> **NOTE**: During this step, only on systems with only three worker nodes (typically Testing and  Development Systems (TDS)), the `customizations.yaml` file will be
> automatically edited to lower pod CPU requests for some services, in order to better facilitate scheduling on smaller systems. See the file
> `/var/www/ephemeral/${CSM_RELEASE}/tds_cpu_requests.yaml` for these settings. This file can be modified with different values (prior to executing the
> `yapl` command below), if other settings are desired in the `customizations.yaml` file for this system. For more information about modifying `customizations.yaml`
> and tuning for specific systems, see
> [Post-Install Customizations](../operations/CSM_product_management/Post_Install_Customizations.md).

1. Install YAPL.

   ```bash
   pit# rpm -Uvh /var/www/ephemeral/${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/yapl-*.x86_64.rpm
   ```

1. Install CSM services using YAPL.

   ```bash
   pit# pushd /usr/share/doc/csm/install/scripts/csm_services && \
        yapl -f install.yaml execute
   pit# popd
   ```
   Expected Output -
   ```
   SUCCESS  Step: Initialize Bootstrap Registry --- Checking Precondition
     SUCCESS  Step: Initialize Bootstrap Registry --- Executing Action
     SUCCESS  Step: Initialize Bootstrap Registry --- Post action validation
    Done: Initialize Bootstrap Registry [1/7] █████████                                     14% | 5m37s
     SUCCESS  Step: Create Site-Init Secret --- Checking Precondition
     SUCCESS  Step: Create Site-Init Secret --- Executing Action
     SUCCESS  Step: Create Site-Init Secret --- Post action validation
    Done: Create Site-Init Secret [2/7] ███████████████████                                 29% | 5m40s
     SUCCESS  Step: Deploy Sealed Secret Decryption Key --- Checking Precondition
     SUCCESS  Step: Deploy Sealed Secret Decryption Key --- Executing Action
     SUCCESS  Step: Deploy Sealed Secret Decryption Key --- Post action validation
    Done: Deploy Sealed Secret Decryption Key [3/7] ████████████████████████                43% | 5m41s
     SUCCESS  Step: Deploy CSM Applications and Services --- Checking Precondition
     SUCCESS  Step: Deploy CSM Applications and Services --- Executing Action
     SUCCESS  Step: Deploy CSM Applications and Services --- Post action validation
    Done: Deploy CSM Applications and Services [4/7] ███████████████████████████████        57% | 30m6s
     SUCCESS  Step: Setup Nexus --- Checking Precondition
     SUCCESS  Step: Setup Nexus --- Executing Action
     SUCCESS  Step: Setup Nexus --- Post action validation
    Done: Setup Nexus [5/7] ████████████████████████████████████████████████████████        71% | 37m32s
     SUCCESS  Step: Set Management NCNs to use Unbound --- Checking Precondition
     SUCCESS  Step: Set Management NCNs to use Unbound --- Executing Action
     SUCCESS  Step: Set Management NCNs to use Unbound --- Post action validation
    Done: Set Management NCNs to use Unbound [6/7] █████████████████████████████████████     86% | 7s
    Done: CSM Services Install Pipeline [7/7] ██████████████████████████████████████████████ 100% | 7s

   ```
   This step failed as 1/16 interface and customer vrf was not configured
> **NOTES:**
>
> * This command may take up to 90 minutes to complete.
> * If any errors are encountered, then potential fixes should be displayed where the error occurred.
> * If the installation fails with a missing secret error message, then see [CSM Services Install Fails Because of Missing Secret](csm_installation_failure.md).
> * Output is redirected to `/usr/share/doc/csm/install/scripts/csm_services/yapl.log` . To show the output in the terminal, append
>   the `--console-output execute` argument to the `yapl` command.
> * The `yapl` command can safely be rerun. By default, it will skip any steps which were previously completed successfully. To force it to
>   rerun all steps regardless of what was previously completed, append the `--no-cache` argument to the `yapl` command.

## 2. Create base BSS global boot parameters

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
   date: Wed, 07 Sep 2022 09:30:09 GMT
   content-length: 0
   x-envoy-upstream-service-time: 4
   server: istio-envoy

   ```

1. Restart the `spire-update-bss` job.

   ```bash
   pit# SPIRE_JOB=$(kubectl -n spire get jobs -l app.kubernetes.io/name=spire-update-bss -o name)
   pit# kubectl -n spire get "${SPIRE_JOB}" -o json | jq 'del(.spec.selector)' \
            | jq 'del(.spec.template.metadata.labels."controller-uid")' \
            | kubectl replace --force -f -
   ```
   Expected Output -
   ```text
   job.batch "spire-update-bss-1" deleted
   job.batch/spire-update-bss-1 replaced
   ```
1. Wait for the `spire-update-bss` job to complete.

   ```bash
   pit# kubectl -n spire wait "${SPIRE_JOB}" --for=condition=complete --timeout=5m
   ```

## 3. Wait for everything to settle

Wait **at least 15 minutes** to let the various Kubernetes resources initialize and start before proceeding with the rest of the install.
Because there are a number of dependencies between them, some services are not expected to work immediately after the install script completes.

## 4. Next topic

The next step is to validate CSM health before redeploying the final NCN.

See [Validate CSM health before final NCN deployment](index.md#validate_csm_health_before_final_ncn_deploy).

## Known issues

### `Deploy CSM Applications and Services` known issues

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

### 5.2 `Setup Nexus` known issues

Known potential issues along with suggested fixes are listed in [Troubleshoot Nexus](../operations/package_repository_management/Troubleshoot_Nexus.md).
