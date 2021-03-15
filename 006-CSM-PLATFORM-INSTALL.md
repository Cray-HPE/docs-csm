# CSM Platform Install

This page will go over how to install CSM applications and services (i.e.,
into the CSM Kubernetes cluster).

* [Initialize Bootstrap Registry](#initialize-bootstrap-registry)
* [Create Site-Init Secret](#create-site-init-secret)
* [Deploy Sealed Secret Decryption Key](#deploy-sealed-secret-decryption-key)
* [Deploy CSM Applications and Services](#deploy-csm-applications-and-services)
  * [Setup Nexus](#setup-nexus)
  * [Set NCNs to use Unbound](#set-ncns-to-use-unbound)
  * [Validate CSM Install](#validate-csm-install)
  * [Reboot from the LiveCD to NCN](#reboot-from-the-livecd-to-ncn)
* [Add Compute Cabinet Routing to NCNs](#add-compute-cabinet-routing-to-ncns)
* [Known Issues](#known-issues)
  * [error: timed out waiting for the condition on jobs/cray-sls-init-load](#error-timed-out-sls-init-load-job)
  * [Error: not ready: https://packages.local](#error-not-ready)
  * [Error initiating layer upload ... in registry.local: received unexpected HTTP status: 200 OK](#error-initiating-layer-upload)
  * [Error lookup registry.local: no such host](#error-registry-local-no-such-host)


<a name="initialize-bootstrap-registry"></a>
## Initialize Bootstrap Registry

> **`SKIP IF ONLINE`** - Online installs cannot upload container images to the
> bootstrap registry since it proxies an upstream source. **DO NOT** perform
> this procedure if the bootstrap registry was [reconfigured to proxy from an
> upstream registry](005-CSM-METAL-INSTALL.md#configure-bootstrap-registry-to-proxy-an-upstream-registry). 

1.  Verify that Nexus is running:

    ```bash
    pit# systemctl status nexus
    ```

2.  Verify that Nexus is _ready_. (Any HTTP response other than `200 OK`
    indicates Nexus is not ready.)

    ```bash
    pit# curl -sSif http://localhost:8081/service/rest/v1/status/writable
    ```
   
    Expected output looks similar to the following:
    ```
    HTTP/1.1 200 OK
    Date: Thu, 04 Feb 2021 05:27:44 GMT
    Server: Nexus/3.25.0-03 (OSS)
    X-Content-Type-Options: nosniff
    Content-Length: 0
    ```

3.  Load the skopeo image installed by the cray-nexus RPM:

    ```bash
    pit# podman load -i /var/lib/cray/container-images/cray-nexus/skopeo-stable.tar quay.io/skopeo/stable
    ```

4.  Use `skopeo sync` to upload container images from the CSM release:

    ```bash
    pit# export CSM_RELEASE=csm-x.y.z
    pit# podman run --rm --network host -v /var/www/ephemeral/${CSM_RELEASE}/docker/dtr.dev.cray.com:/images:ro quay.io/skopeo/stable sync --scoped --src dir --dest docker --dest-tls-verify=false --dest-creds admin:admin123 /images localhost:5000
    ```


<a name="create-site-init-secret"></a>
## Create Site-Init Secret

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
```
secret/site-init created
```

> **`NOTE`** If the `site-init` secret already exists then `kubectl` will error
> with a message similar to:
>
> ```
> Error from server (AlreadyExists): secrets "site-init" already exists
> ```
>
> In this case, delete the `site-init` secret and recreate it.
>
> 1. First delete it:
>    ```bash
>    pit# kubectl delete secret -n loftsman site-init
>    ```
>    
>    Expected output looks similar to the following:
>    ```
>    secret "site-init" deleted
>    ```
>
> 2. Then recreate it:
>    ```bash
>    pit# kubectl create secret -n loftsman generic site-init --from-file=/var/www/ephemeral/prep/site-init/customizations.yaml
>    ```
>    
>    Expected output looks similar to the following:
>    ```
>    secret/site-init created
>    ```

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


<a name="deploy-sealed-secret-decryption-key"></a>
## Deploy Sealed Secret Decryption Key

Deploy the corresponding key necessary to decrypt sealed secrets:

```bash
pit# /var/www/ephemeral/prep/site-init/deploy/deploydecryptionkey.sh
```

An error similar to the following may occur when deploying the key:
```
Error from server (NotFound): secrets "sealed-secrets-key" not found
 
W0304 17:21:42.749101   29066 helpers.go:535] --dry-run is deprecated and can be replaced with --dry-run=client.
secret/sealed-secrets-key created
Restarting sealed-secrets to pick up new keys
No resources found
```

This is expected and can safely be ignored.


<a name="#deploy-csm-applications-and-services"></a>
## Deploy CSM Applications and Services

Run `install.sh` to deploy CSM applications services:

> **`NOTE`** `install.sh` requires various system configuration which are
> expected to be found in the locations used in proceeding documentation;
> however, it needs to know `SYSTEM_NAME` in order to find `metallb.yaml` and
> `sls_input_file.json` configuration files.
>
> Some commands will also need to have the CSM_RELEASE variable set.
>
> ```bash
> pit# export SYSTEM_NAME=eniac
> pit# export CSM_RELEASE=csm-x.y.z
> ```

```bash
pit# cd /var/www/ephemeral/$CSM_RELEASE
pit# ./install.sh
```

On success, `install.sh` will output `OK` to stderr and exit with status code
`0`, e.g.:

```bash
pit# ./install.sh
...
+ CSM applications and services deployed
install.sh: OK
```

In the event that `install.sh` does not complete successfully, consult the
[known issues](#known-issues) below to resolve potential problems and then try
running `install.sh` again.


<a name="setup-nexus"></a>
### Setup Nexus

Run `./lib/setup-nexus.sh` to configure Nexus and upload CSM RPM repositories,
container images, and Helm charts:

```bash
pit# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
pit# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
```

In the event of an error, consult the [known issues](#known-issues) below to
resolve potential problems and then try running `setup-nexus.sh` again. Note
that subsequent runs of `setup-nexus.sh` may report `FAIL` when uploading
duplicate assets. This is ok as long as `setup-nexus.sh` outputs
`setup-nexus.sh: OK` and exits with status code `0`.


<a name="set-ncns-to-use-unbound"></a>
### Set NCNs to use Unbound

First, verify that SLS properly reports all NCNs in the system:

```bash
pit# ./lib/list-ncns.sh
```

On success, each NCN will be output, e.g.:

```bash
pit# ./lib/list-ncns.sh
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

If any NCNs are missing from the output, take corrective action before
proceeding.

Next, run `lib/set-ncns-to-unbound.sh` to SSH to each NCN and update
/etc/resolv.conf to use Unbound as the nameserver.

```bash
pit# ./lib/set-ncns-to-unbound.sh
```

> **`NOTE`** If passwordless SSH is not configured, the administrator will have
> to enter the corresponding password as the script attempts to conenct to each
> NCN.

On success, the nameserver configuration in /etc/resolv.conf will be printed
for each NCN, e.g.,:

```bash
pit# ./lib/set-ncns-to-unbound.sh
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

> **`NOTE`** The script connects to ncn-m001 which will be the pit node, whose
> password may be different from that of the other NCNs.


<a name="validate-csm-install"></a>
### Validate CSM Install

After successfully completing the CSM platform install, quit the typescript
session with the `exit` command and copy the file (booted-csm-lived.<date>.txt)
to a location on another server for reference later. 

The administrator should wait at least 15 minutes to let the various Kubernetes resources
get initialized and started. Because there are a number of dependencies between them,
some services are not expected to work immediately after the install script completes.
After waiting, the administrator may start the [CSM Validation process](008-CSM-VALIDATION.md).


<a name="reboot-from-the-livecd-to-ncn"></a>
### Reboot from the LiveCD to NCN

Once the CSM services are deemed healthy the administrator may proceed to the
final step of the CSM install [Reboot from the LiveCD to NCN](007-CSM-INSTALL-REBOOT.md).


<a name="add-cabinet-routing-to-ncns"></a>
## Add Compute Cabinet Routing to NCNs

NCNs require additional routing to enable access to Mountain, Hill and River Compute cabinets.

Requires:
* Platform installation
* Running and configured SLS
* Can be run from PIT if passwordless SSH is set up to all NCNs, but should be run post ncn-m001 reboot.

To apply the routing, run:
```bash
ncn# /opt/cray/csm/workarounds/livecd-post-reboot/CASMINST-1570/CASMINST-1570.sh
```

> **`NOTE`** Currently, there is no automated procedure to apply routing changes to all worker NCNs to support Mountain, Hill and River
Compute Node Cabinets. 

----

<a name="known-issues"></a>
## Known Issues

The `install.sh` script changes cluster state and should not simply be rerun
in the event of a failure without careful consideration of the specific
error. It may be possible to resume installation from the last successful
command executed by `install.sh`, but admins will need to appropriately
modify `install.sh` to pick up where the previous run left off. (Note: The
`install.sh` script runs with `set -x`, so each command will be printed to
stderr prefixed with the expanded value of PS4, namely, `+ `.)

Known potential issues with suggested fixes are listed below.

<a name="error-timed-out-sls-init-load-job"></a>
### error: timed out waiting for the condition on jobs/cray-sls-init-load

The following error may occur when running `./install.sh`:
```
+ /var/www/ephemeral/csm-0.8.11/lib/wait-for-unbound.sh
+ kubectl wait -n services job cray-sls-init-load --for=condition=complete --timeout=20m
error: timed out waiting for the condition on jobs/cray-sls-init-load
```

Determine the name and state of the SLS init loader job pod:
```bash
pit# kubectl -n services get pods -l app=cray-sls-init-load
```
   
Expected output looks similar to the following:
```
NAME                       READY   STATUS      RESTARTS   AGE
cray-sls-init-load-nh5k7   2/2     Running     0          21m
```

If the state is `Running` after after the 20 minute timeout, this is likely that the SLS loader job is failing to ping the SLS S3 bucket due to a malformed URL. To verify this inspect the logs of the cray-sls-init-load pod:
```bash
pit# kubectl -n services logs -l app=cray-sls-init-load -c cray-sls-loader
```

The symptom of this situation is the present of something similar to the following in the output of the previous command:
```
{"level":"warn","ts":1612296611.2630196,"caller":"sls-s3-downloader/main.go:96","msg":"Failed to ping bucket.","error":"encountered error during head_bucket operation for bucket sls at https://: RequestError: send request failed\ncaused by: Head \"https:///sls\": http: no Host in request URL"}
```  

This error is most likely _intermittent_ and and deleting the cray-sls-init-load pod is expected to resolve this issue. You may need to delete the loader pod multiple times until it succeeds. 
```bash
pit# kubectl -n services delete pod cray-sls-init-load-nh5k7
```

Once the pod is deleted is deleted, verify the new pod started by k8s completes successfully. If it does not complete within a few minutes inspect the logs for the pod. If it is still failing to ping the S3 bucket, delete the pod again and try again.
```bash
pit# kubectl -n services get pods -l app=cray-sls-init-load
```

If the pod has completed successfully, the output looks similar to the following:
```
NAME                       READY   STATUS      RESTARTS   AGE
cray-sls-init-load-pbzxv   0/2     Completed   0          55m
```

Once the loader job has completed successfully running `./install.sh` again is expected to succeed.

<a name="error-not-ready"></a>
### Error: not ready: https://packages.local

The infamous `error: not ready: https://packages.local` indicates that from
the caller’s perspective, Nexus not ready to receive writes. However, it most
likely indicates that a Nexus setup utility was unable to connect to Nexus
via the `packages.local` name. Since the install does not attempt to connect
to `packages.local` until Nexus has been successfully deployed, the error
does not usually indicate something is actually wrong with Nexus. Instead, it
is most commonly a network issue with name resolution (i.e., DNS), IP
routes from the pit node, switch misconfiguration, or Istio ingress.

Verify that packages.local resolves to **ONLY** the load balancer IP for the
istio-ingressgateway service in the istio-system namespace, typically
10.92.100.71. If name resolution returns addresses on other networks (such as
HMN) this must be corrected. Prior to DNS/DHCP hand-off to Unbound, these
settings are controlled by dnsmasq. Unbound settings are based on SLS
settings in sls_input_file.json and must be updated via the Unbound manager.

If packages.local resolves to the correct addresses, verify basic
connectivity using ping. If `ping packages.local` is unsuccessful, verify the
IP routes from the pit node to the NMN load balancer network.  The
typical `ip route` configuration is `10.92.100.0/24 via 10.252.0.1 dev
vlan002`. If pings are successful, try checking the status of Nexus by
running `curl -sS https://packages.local/service/rest/v1/status/writable`. If
the connection times out, it indicates there is a more complex connection
issue. Verify switches are configured properly and BGP peering is operating
correctly, see docs/400-SWITCH-BGP-NEIGHBORS.md for more information. Lastly,
check Istio and OPA logs to see if connections to packages.local are not
reaching Nexus, perhaps due to an authorization issue.

If https://packages.local/service/rest/v1/status/writable returns an HTTP
code other than `200 OK`, it indicates there is an issue with Nexus. Verify
that the `loftsman ship` deployment of the nexus.yaml manifest was
successful. If `helm status -n nexus cray-nexus` indicates the status is
**NOT** `deployed`, then something is most likely wrong with the Nexus
deployment and additional diagnosis is required. In this case, the current
Nexus deployment probably needs to be uninstalled and the `nexus-data` PVC
removed before attempting to deploy again.


<a name="error-initiating-layer-upload"></a>
### Error initiating layer upload ... in registry.local: received unexpected HTTP status: 200 OK

The following error may occur when running `./install.sh --continue`:

```
time="2021-02-07T20:25:22Z" level=info msg="Copying image tag 97/144" from="dir:/image/jettech/kube-webhook-certgen:v1.2.1" to="docker://registry.local/jettech/kube-webhook-certgen:v1.2.1"
Getting image source signatures
Copying blob sha256:f6e131d355612c71742d71c817ec15e32190999275b57d5fe2cd2ae5ca940079
Copying blob sha256:b6c5e433df0f735257f6999b3e3b7e955bab4841ef6e90c5bb85f0d2810468a2
Copying blob sha256:ad2a53c3e5351543df45531a58d9a573791c83d21f90ccbc558a7d8d3673ccfa
time="2021-02-07T20:25:33Z" level=fatal msg="Error copying tag \"dir:/image/jettech/kube-webhook-certgen:v1.2.1\": Error writing blob: Error initiating layer upload to /v2/jettech/kube-webhook-certgen/blobs/uploads/ in registry.local: received unexpected HTTP status: 200 OK"
+ return
```

This error is most likely _intermittent_ and running `./install.sh --continue`
again is expected to succeed.

<a name="error-registry-local-no-such-host"></a>
### Error lookup registry.local: no such host

The following error may occur when running `./install.sh --continue`:
```
time="2021-02-23T19:55:54Z" level=fatal msg="Error copying tag \"dir:/image/grafana/grafana:7.0.3\": Error writing blob: Head \"https://registry.local/v2/grafana/grafana/blobs/sha256:cf254eb90de2dc62aa7cce9737ad7e143c679f5486c46b742a1b55b168a736d3\": dial tcp: lookup registry.local: no such host"
+ return
```

Or a similar error:
```
time="2021-03-04T22:45:07Z" level=fatal msg="Error copying ref \"dir:/image/cray/cray-ims-load-artifacts:1.0.4\": Error trying to reuse blob sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217 at destination: Head \"https://registry.local/v2/cray/cray-ims-load-artifacts/blobs/sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217\": dial tcp: lookup registry.local: Temporary failure in name resolution"
+ return
```

These errors are most likely _intermittent_ and running `./install.sh --continue`
again is expected to succeed.
