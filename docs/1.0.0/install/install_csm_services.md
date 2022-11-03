# Install CSM Services

This procedure will install CSM applications and services into the CSM Kubernetes cluster.

> **NOTE:** Check the information in [Known issues](#known-issues) before starting this procedure to be warned about possible problems.

1. [Initialize bootstrap registry](#1-initialize-bootstrap-registry)
1. [Create `Site-Init` secret](#2-create-site-init-secret)
1. [Deploy sealed secret decryption key](#3-deploy-sealed-secret-decryption-key)
1. [Deploy CSM applications and services](#4-deploy-csm-applications-and-services)
1. [Setup Nexus](#5-setup-nexus)
1. [Set management NCNs to use Unbound](#6-set-management-ncns-to-use-unbound)
1. [Apply pod priorities](#7-apply-pod-priorities)
1. [Apply `After Sysmgmt Manifest` workarounds](#8-apply-after-sysmgmt-manifest-workarounds)
1. [Wait for everything to settle](#9-wait-for-everything-to-settle)
1. [Next topic](#10-next-topic)

* [Known issues](#known-issues)
  * [`install.sh` known issues](#installsh-known-issues)

## 1. Initialize bootstrap registry

> **`NOTE`** The bootstrap registry runs in a default Nexus configuration,
> which is started and populated in this section. It only exists during initial
> CSM install on the PIT node in order to bootstrap CSM services. Once CSM
> install is completed and the PIT node is rebooted as an NCN, the bootstrap
> Nexus no longer exists.

1. Verify that Nexus is running:

    ```bash
    pit# systemctl status nexus
    ```

1. Verify that Nexus is _ready_. (Any HTTP response other than `200 OK`
    indicates Nexus is not ready.)

    ```bash
    pit# curl -sSif http://localhost:8081/service/rest/v1/status/writable
    ```

    Expected output looks similar to the following:

    ```text
    HTTP/1.1 200 OK
    Date: Thu, 04 Feb 2021 05:27:44 GMT
    Server: Nexus/3.25.0-03 (OSS)
    X-Content-Type-Options: nosniff
    Content-Length: 0
    ```

1. Load the Skopeo image installed by the `cray-nexus` RPM:

    ```bash
    pit# podman load -i /var/lib/cray/container-images/cray-nexus/skopeo-stable.tar quay.io/skopeo/stable
    ```

1. Use `skopeo sync` to upload container images from the CSM release:

    ```bash
    pit# export CSM_RELEASE=csm-x.y.z
    pit# podman run --rm --network host -v /var/www/ephemeral/${CSM_RELEASE}/docker/dtr.dev.cray.com:/images:ro quay.io/skopeo/stable sync \
    --scoped --src dir --dest docker --dest-tls-verify=false --dest-creds admin:admin123 /images localhost:5000
    ```

    > **`NOTE`** As the bootstrap Nexus uses the default configuration, the
    > above command uses the default admin credentials (`admin` user with
    > password `admin123`) in order to upload to the bootstrap registry, which
    > is listening on localhost:5000.

## 2. Create `Site-Init` secret

The `site-init` secret in the `loftsman` namespace makes
`/var/www/ephemeral/prep/site-init/customizations.yaml` available to product
installers. The `site-init` secret should only be updated when the
corresponding `customizations.yaml` data is changed, such as during system
installation or upgrade. Create the `site-init` secret to contain
`/var/www/ephemeral/prep/site-init/customizations.yaml`:

```bash
pit# kubectl create secret -n loftsman generic site-init --from-file=/var/www/ephemeral/prep/site-init/customizations.yaml
```

Expected output looks similar to the following:

```text
secret/site-init created
```

> **`NOTE`** If the `site-init` secret already exists, then `kubectl` will error
> with a message similar to:
>
> ```text
> Error from server (AlreadyExists): secrets "site-init" already exists
> ```
>
> In this case, delete the `site-init` secret and recreate it.
>
> 1. Delete it:
>
>    ```bash
>    pit# kubectl delete secret -n loftsman site-init
>    ```
>
>    Expected output looks similar to the following:
>
>    ```text
>    secret "site-init" deleted
>    ```
>
> 1. Recreate it:
>
>    ```bash
>    pit# kubectl create secret -n loftsman generic site-init --from-file=/var/www/ephemeral/prep/site-init/customizations.yaml
>    ```
>
>    Expected output looks similar to the following:
>
>    ```text
>    secret/site-init created
>    ```
>
> **`WARNING`** If for some reason the system customizations need to be
> modified to complete product installation, administrators must first update
> `customizations.yaml` in the `site-init` Git repository, which may no longer
> be mounted on any cluster node, and then delete and recreate the `site-init`
> secret as shown below.
>
> To **read** `customizations.yaml` from the `site-init` secret:
>
> ```bash
> ncn# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > customizations.yaml
> ```
>
> To **delete** the `site-init` secret:
>
> ```bash
> ncn# kubectl -n loftsman delete secret site-init
> ```
>
> To **recreate** the `site-init` secret:
>
> ```bash
> ncn# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
> ```

## 3. Deploy sealed secret decryption key

Deploy the corresponding key necessary to decrypt sealed secrets:

```bash
pit# /var/www/ephemeral/prep/site-init/deploy/deploydecryptionkey.sh
```

An error similar to the following may occur when deploying the key:

```text
Error from server (NotFound): secrets "sealed-secrets-key" not found

W0304 17:21:42.749101   29066 helpers.go:535] --dry-run is deprecated and can be replaced with --dry-run=client.
secret/sealed-secrets-key created
Restarting sealed-secrets to pick up new keys
No resources found
```

This is expected and can safely be ignored.

## 4. Deploy CSM applications and services

> **NOTE**: During this step, only on systems with only three worker nodes (typically Testing and  Development Systems (TDS)), the `customizations.yaml` file will be
> automatically edited to lower pod CPU requests for some services, in order to better facilitate scheduling on smaller systems. See the file
> `/var/www/ephemeral/${CSM_RELEASE}/tds_cpu_requests.yaml` for these settings. This file can be modified with different values (prior to executing the
> `yapl` command below), if other settings are desired in the `customizations.yaml` file for this system. For more information about modifying `customizations.yaml`
> and tuning for specific systems, see
> [Post-Install Customizations](../operations/CSM_product_management/Post_Install_Customizations.md).

Run `install.sh` to deploy CSM applications services. This command may take 25 minutes or more to run.

> **`NOTE`** `install.sh` requires various system configuration which are
> expected to be found in the locations used in proceeding documentation;
> however, it needs to know `SYSTEM_NAME` in order to find `metallb.yaml` and
> `sls_input_file.json` configuration files.
>
> Some commands will also need to have the `CSM_RELEASE` variable set.
>
> Verify that the `SYSTEM_NAME` and `CSM_RELEASE` environment variables are set:
>
> ```bash
> pit# echo $SYSTEM_NAME
> pit# echo $CSM_RELEASE
> ```
>
> If they are not set perform the following:
>
> ```bash
> pit# export SYSTEM_NAME=eniac
> pit# export CSM_RELEASE=csm-x.y.z
> ```

```bash
pit# cd /var/www/ephemeral/$CSM_RELEASE
pit# ./install.sh
```

On success, `install.sh` will output `OK` to `stderr` and exit with status code
`0`, e.g.:

```console
pit# ./install.sh
...
+ CSM applications and services deployed
install.sh: OK
```

In the event that `install.sh` does not complete successfully, consult the
[known issues](#known-issues) below to resolve potential problems and then try
running `install.sh` again.

**IMPORTANT:** If having to re-run `install.sh` to re-deploy failed `ceph-csi` provisioners make sure to delete the jobs that have not completed.
These are left there for investigation on failure. They are automatically removed on a successful deployment.

```bash
pit# kubectl get jobs
```

Example output:

```text
NAME                   COMPLETIONS   DURATION   AGE
cray-ceph-csi-cephfs   0/1                      3m35s
cray-ceph-csi-rbd      0/1                      8m36s
```

> If these jobs exist, then delete them with `kubectl delete job <jobname>` before running `install.sh` again.

## 5. Setup Nexus

Run `./lib/setup-nexus.sh` to configure Nexus and upload CSM RPM repositories,
container images, and Helm charts. This command may take 20 minutes or more to run.

```bash
pit# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on `stderr` and exit with status
code `0`, e.g.:

```console
pit# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
```

In the event of an error, consult [Troubleshoot Nexus](../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note
that subsequent runs of `setup-nexus.sh` may report `FAIL` when uploading
duplicate assets. This is okay as long as `setup-nexus.sh` outputs
`setup-nexus.sh: OK` and exits with status code `0`.

## 6. Set management NCNs to use Unbound

1. Verify that SLS properly reports all management NCNs in the system.

    ```bash
    pit# ./lib/list-ncns.sh
    ```

    On success, each management NCN will be output. For example:

    ```text
    + Getting admin-client-auth secret
    + Obtaining access token
    + Querying SLS
    ncn-m001
    ncn-m002
    ncn-m003
    ncn-s001
    ncn-s002
    ncn-s003
    ncn-w001
    ncn-w002
    ncn-w003
    ```

    If any management NCNs are missing from the output, then take corrective action before proceeding.

1. Update management NCNs to use Unbound for DNS.

    ```bash
    pit# ./lib/set-ncns-to-unbound.sh
    ```

    > **`NOTES`**
    >
    > * If passwordless SSH is not configured, then the administrator will have
    >   to enter the corresponding password as the script attempts to connect to each
    >   NCN.
    > * The script connects to `ncn-m001` which will be the PIT node; the PIT node
    >   password may be different from that of the other NCNs.

    On success, the `nameserver` configuration in `/etc/resolv.conf` will be printed
    for each management NCN. For example:

    ```text
    + Getting admin-client-auth secret
    + Obtaining access token
    + Querying SLS
    + Updating ncn-m001
    Password:
    ncn-m001: nameserver 127.0.0.1
    ncn-m001: nameserver 10.92.100.225
    + Updating ncn-m002
    Password:
    ncn-m002: nameserver 10.92.100.225
    + Updating ncn-m003
    Password:
    ncn-m003: nameserver 10.92.100.225
    + Updating ncn-s001
    Password:
    ncn-s001: nameserver 10.92.100.225
    + Updating ncn-s002
    Password:
    ncn-s002: nameserver 10.92.100.225
    + Updating ncn-s003
    Password:
    ncn-s003: nameserver 10.92.100.225
    + Updating ncn-w001
    Password:
    ncn-w001: nameserver 10.92.100.225
    + Updating ncn-w002
    Password:
    ncn-w002: nameserver 10.92.100.225
    + Updating ncn-w003
    Password:
    ncn-w003: nameserver 10.92.100.225
    ```

## 7. Apply pod priorities

Run the `add_pod_priority.sh` script to create and apply a pod priority class to services critical to CSM.
This will give these services a higher priority than others to ensure they get scheduled by Kubernetes in the event that resources limited on smaller deployments.

```bash
pit# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/add_pod_priority.sh
```

Example output:

```text
Creating csm-high-priority-service pod priority class
priorityclass.scheduling.k8s.io/csm-high-priority-service configured

Patching cray-postgres-operator deployment in services namespace
deployment.apps/cray-postgres-operator patched

Patching cray-postgres-operator-postgres-operator-ui deployment in services namespace
deployment.apps/cray-postgres-operator-postgres-operator-ui patched

Patching istio-operator deployment in istio-operator namespace
deployment.apps/istio-operator patched

Patching istio-ingressgateway deployment in istio-system namespace
deployment.apps/istio-ingressgateway patched
.
.
.
```

After running the `add_pod_priority.sh` script, the affected pods will be restarted as the pod priority class is applied to them.

> **`NOTE`** It is possible that the script may not finish, and will end up looping on this message:
>
> ```text
> Sleeping for ten seconds waiting for 3 pods in cray-bss-etcd etcd cluster
> Sleeping for ten seconds waiting for 3 pods in cray-bss-etcd etcd cluster
> Sleeping for ten seconds waiting for 3 pods in cray-bss-etcd etcd cluster
> ```
>
> If it has been looping with that message for more than five minutes, then refer to [Restore an etcd Cluster from a Backup](../operations/kubernetes/Restore_an_etcd_Cluster_from_a_Backup.md)
> for instructions on how to repair the `cray-bss-etcd` cluster, and then re-run the `add_pod_priority.sh` script.

## 8. Apply `After Sysmgmt Manifest` workarounds

Follow the [workaround instructions](../update_product_stream/index.md#apply-workarounds) for the `after-sysmgmt-manifest` breakpoint.

## 9. Wait for everything to settle

Wait **at least 15 minutes** to let the various Kubernetes resources initialize and start before proceeding with the rest of the install.
Because there are a number of dependencies between them, some services are not expected to work immediately after the install script completes.

## 10. Next topic

The next step is to redeploy the PIT node.

See [Validate CSM Health Before PIT Node Redeploy](index.md#validate_csm_health_before_pit_redeploy).

## Known issues

### `install.sh` Known Issues

The `install.sh` script changes cluster state and should not simply be rerun
in the event of a failure without careful consideration of the specific
error. It may be possible to resume installation from the last successful
command executed by `install.sh`, but administrators will need to appropriately
modify `install.sh` to pick up where the previous run left off. (Note: The
`install.sh` script runs with `set -x`, so each command will be printed to
`stderr` prefixed with the expanded value of PS4, namely, `+`.)

The following error may occur during `install.sh`:

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

1. Running `install.sh` again is expected to succeed.
