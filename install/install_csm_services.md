# Install CSM Services

This procedure will install CSM applications and services into the CSM Kubernetes cluster.

> **NOTE:** Check the information in [Known Issues](#known-issues) before starting this procedure to be warned about possible problems.

1. [Install Yapl](#install-yapl)
1. [Install CSM Services](#install-csm-services)
1. [Wait For Everything To Settle](#wait-for-everything-to-settle)
1. [Known Issues](#known-issues)
    * [install.sh known issues](#known-issues-install-sh)
    * [Setup Nexus known issues](#known-issues-setup-nexus)
1. [Next Topic](#next-topic)

## Details

<a name="install-yapl"></a>

### 1. Install Yapl

```bash
pit# rpm -Uvh /var/www/ephemeral/${CSM_RELEASE}/rpm/cray/csm/sle-15sp2/x86_64/yapl-*.x86_64.rpm
```

<a>install-csm-services</a>

### 2. Install CSM Services

> **NOTE**: During this step, on (only) TDS systems with three worker nodes the `customizations.yaml` file will be edited (automatically) to lower pod
CPU requests for some services in order to better facilitate scheduling on smaller systems. See the file:
`/var/www/ephemeral/${CSM_RELEASE}/tds_cpu_requests.yaml` for these settings. If desired, this file can be modified with different values (prior to executing the
`yapl` command below) if other settings are desired in the `customizations.yaml` file for this system. For more information about modifying `customizations.yaml`
and tuning based on specific systems, see
[Post Install Customizations](https://github.com/Cray-HPE/docs-csm/blob/release/1.2/operations/CSM_product_management/Post_Install_Customizations.md).

1. Install CSM services using `yapl`:

    ```bash
    pit# pushd /usr/share/doc/csm/install/scripts/csm_services && \
         yapl -f install.yaml execute
    pit# popd
    ```

    > **NOTES:**
    >
    > * If any errors are encountered, then potential fixes should be displayed where the error occurred. You can rerun above command any time.
    > * Output is redirected to `/usr/share/doc/csm/install/scripts/csm_services/yapl.log` . To show stdout in the terminal, use
    >   `yapl -f install.yaml --console-output execute`
    > * To force a rerun, use `yapl -f install.yaml execute --no-cache`

<a name="wait-for-everything-to-settle"></a>

### 3. Wait For Everything To Settle

Wait **at least 15 minutes** to let the various Kubernetes resources get initialized and started before proceeding with the rest of the install.
Because there are a number of dependencies between them, some services are not expected to work immediately after the install script completes.

<a name="known-issues"></a>

### 4. Known Issues

<a name="known-issues-install-sh"></a>

#### 4.1 install.sh known issues

The `install.sh` script changes cluster state and should not simply be rerun
in the event of a failure without careful consideration of the specific
error. It may be possible to resume installation from the last successful
command executed by `install.sh`, but administrators will need to appropriately
modify `install.sh` to pick up where the previous run left off. (Note: The
`install.sh` script runs with `set -x`, so each command will be printed to
stderr prefixed with the expanded value of PS4, namely, `+`.)

The following error may occur when running `./install.sh`:

```text
+ csi upload-sls-file --sls-file /var/www/ephemeral/prep/eniac/sls_input_file.json
2021/10/05 18:42:58 Retrieving S3 credentials ( sls-s3-credentials ) for SLS
2021/10/05 18:42:58 Unable to SLS S3 secret from k8s:secrets "sls-s3-credentials" not found
```

1. Verify that the `sls-s3-credentials` secret exists in the `default` namespace:

   ```bash
   pit# kubectl get secret sls-s3-credentials
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      28d
   ```

1. Check for running `sonar-sync` jobs. If there are no `sonar-sync` jobs, then wait for one to complete. The `sonar-sync` cronjob is responsible
   for copying the `sls-s3-credentials` secret from the `default` to `services` namespaces.

   ```bash
   pit# kubectl -n services get pods -l cronjob-name=sonar-sync
   NAME                          READY   STATUS      RESTARTS   AGE
   sonar-sync-1634322840-4fckz   0/1     Completed   0          73s
   sonar-sync-1634322900-pnvl6   1/1     Running     0          13s
   ```

1. Verify that the `sls-s3-credentials` secret now exists in the `services` namespaces.

   ```bash
   pit# kubectl -n services get secret sls-s3-credentials
   NAME                 TYPE     DATA   AGE
   sls-s3-credentials   Opaque   7      20s
   ```

1. Running `install.sh` again is expected to succeed.

<a name="known-issues-setup-nexus"></a>

#### 4.2 Setup Nexus known issues

Known potential issues with suggested fixes are listed in [Troubleshoot Nexus](../operations/package_repository_management/Troubleshoot_Nexus.md).

<a name="next-topic"></a>

### 5. Next Topic

After completing this procedure the next step is to validate CSM health before redeploying the final NCN.

See [Validate CSM Health Before Final NCN Deployment](index.md#validate_csm_health_before_final_ncn_deploy)
