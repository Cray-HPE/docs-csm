# CSM Platform Install

This page will go over how to install CSM applications and services (i.e.,
into the CSM Kubernetes cluster).

* [Initialize Bootstrap Registry](#initialize-bootstrap-registry)
* [Create Site-Init Secret](#create-site-init-secret)
* [Deploy Sealed Secret Decryption Key](#deploy-sealed-secret-decryption-key)
* [Start the Deployment](#start-the-deployment)
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
    HTTP/1.1 200 OK
    Date: Thu, 04 Feb 2021 05:27:44 GMT
    Server: Nexus/3.25.0-03 (OSS)
    X-Content-Type-Options: nosniff
    Content-Length: 0

    ```

3.  Load the skopeo image installed by the cray-nexus RPM:

    ```bash
    pit# podman load -i /var/lib/cray/container-images/cray-nexus/skopeo-stable.tar
    ```

4.  Use `skopeo sync` to upload container images from the CSM release:

    ```bash
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
secret/site-init created
```

> **`NOTE`** If the `site-init` secret already exists then `kubectl` will error:
>
> ```bash
> pit:~ # kubectl create secret -n loftsman generic site-init --from-file=/var/www/ephemeral/prep/site-init/customizations.yaml
> Error from server (AlreadyExists): secrets "site-init" already exists
> ```
>
> In this case, delete the `site-init` secret and re-create it:
>
> ```bash
> pit:~ # kubectl delete secret -n loftsman site-init
> secret "site-init" deleted
> pit:~ # kubectl create secret -n loftsman generic site-init --from-file=/var/www/ephemeral/prep/site-init/customizations.yaml
> secret/site-init created
> ```


<a name="deploy-sealed-secret-decryption-key"></a>
## Deploy Sealed Secret Decryption Key

Deploy the corresponding key necessary to decrypt sealed secrets:

```bash
pit# /var/www/ephemeral/prep/site-init/deploy/deploydecryptionkey.sh
```


<a name="start-the-deployment"></a>
## Start the Deployment

At this time the administrator can begin actually deploying the platform.

### Run `install.sh`

> **`NOTE`** `install.sh` requires various system configuration which are
> expected to be found in the locations used in proceeding documentation;
> however, it needs to know `SYSTEM_NAME` in order to find `metallb.yaml` and
> `sls_input_file.json` configuration files.
>
> ```bash
> pit# export SYSTEM_NAME=eniac
> ```

Complete the CSM install by running `install.sh`.

```bash
pit# cd /var/www/ephemeral/$CSM_RELEASE
pit# ./install.sh
```

> **`NOTE`** `install.sh` will exit with instructions that may be copied and
> pasted to switch DNS settings from dnsmasq to Unbound and then to continue the
> installation. **These should be ignored** unless the administrator did not run
> the pre-ncn-boot workarounds.

After successfully completing the CSM platform install, quit the typescript
session with the `exit` command and copy the file (booted-csm-lived.<date>.txt)
to a location on another server for reference later. The administrator may then
start the [CSM Validation process](008-CSM-VALIDATION.md).

Once the CSM services are deemed healthy the administrator way proceed to the
final step of the CSM install [Reboot from the LiveCD to NCN](007-CSM-INSTALL-REBOOT.md).

<a name="add-cabinet-routing-to-ncns"></a>
## Add Compute Cabinet Routing to NCNs
Currently there is no automated procedure to apply routing changes to all worker NCNs to support Mountain, Hill and River
Compute Node Cabinets.  This should be applied now to all NCNs as explained in [Add Compute Cabinet Routes](109-COMPUTE-CABINET-ROUTES-FOR-NCN.md).


----

<a name="known-issues"></a>
## Known Issues

The `install.sh` script changes cluster state and should not simply be rerun
in the event of a failure without careful consideration of the specific
error. It may be possible to resume installation from the last successful
command executed by `install.sh`, but admins will need to appropriately
modify `install.sh` to pick up where the previous run left off. (Note: The
`install.sh` script runs with `set -x`, so each command will be printed to
stderr prefixed with the expanded value of PS4, e.g., `+ `.)

Known potential issues with suggested fixes are listed below.

<a name="error-timed-out-sls-init-load-job"></a>
### error: timed out waiting for the condition on jobs/cray-sls-init-load

The following error may occur when running `./install.sh`:
```bash
pit# ./install.sh
...
+ /var/www/ephemeral/csm-0.8.11/lib/wait-for-unbound.sh
+ kubectl wait -n services job cray-sls-init-load --for=condition=complete --timeout=20m
error: timed out waiting for the condition on jobs/cray-sls-init-load
```

Determine the name and state of the SLS init loader job pod:
```bash
pit# kubectl -n services get pods -l app=cray-sls-init-load
NAME                       READY   STATUS      RESTARTS   AGE
cray-sls-init-load-nh5k7   2/2     Running     0          21m
```

If the state is `Running` after after the 20 minute timeout, this is likely that the SLS loader job is failing to ping the SLS S3 bucket due to a malformed URL. To verify this inspect the logs of the cray-sls-init-load pod:
```bash
pit# kubectl -n services logs -l app=cray-sls-init-load -c cray-sls-loader
...
{"level":"warn","ts":1612296611.2630196,"caller":"sls-s3-downloader/main.go:96","msg":"Failed to ping bucket.","error":"encountered error during head_bucket operation for bucket sls at https://: RequestError: send request failed\ncaused by: Head \"https:///sls\": http: no Host in request URL"}
```  

This error is most likely _intermittent_ and and deleting the cray-sls-init-load pod is expected to resolve this issue. You may need to delete the loader pod multiple times until it succeeds. 
```bash
pit# kubectl -n services delete pod cray-sls-init-load-nh5k7
```

Once the pod is deleted is deleted, verify the new pod started by k8s completes successfully. If it does not complete within a few minutes inspect the logs for the pod. If it is still failing to ping the S3 bucket, delete the pod again and try again.
```bash
pit# kubectl -n services get pods -l app=cray-sls-init-load
NAME                       READY   STATUS      RESTARTS   AGE
cray-sls-init-load-pbzxv   0/2     Completed   0          55m
```

<a name="error-not-ready"></a>
### Error: not ready: https://packages.local

The infamous `error: not ready: https://packages.local` indicates that from
the caller’s perspective, Nexus not ready to receive writes. However, it most
likely indicates that a Nexus setup utility was unable to connect to Nexus
via the `packages.local` name. Since the install does not attempt to connect
to `packages.local` until Nexus has been successfully deployed, the error
does not usually indicate something is actually wrong with Nexus. Instead, it
is most commonly a network issue with e.g., name resolution (i.e., DNS), IP
routes from the pit node, switch misconfiguration, or Istio ingress.

Verify that packages.local resolves to **ONLY** the load balancer IP for the
istio-ingressgateway service in the istio-system namespace, typically
10.92.100.71. If name resolution returns addresses on other networks (e.g.,
HMN) this must be corrected. Prior to DNS/DHCP hand-off to Unbound, these
settings are controlled by dnsmasq. Unbound settings are based on SLS
settings in sls_input_file.json and must be updated via the Unbound manager.

If packages.local resolves to the correct addresses, verify basic
connectivity using ping. If `ping packages.local` is unsuccessful, verify the
IP routes from the pit node to the NMN load balancer network, e.g., the
typical `ip route` configuration is `10.92.100.0/24 via 10.252.0.1 dev
vlan002`. If pings are successful, try checking the status of Nexus by
running `curl -sS https://packages.local/service/rest/v1/status/writable`. If
the connection times out, it indicates there is a more complex connection
issue. Verify switches are configured properly and BGP peering is operating
correctly, see docs/400-SWITCH-BGP-NEIGHBORS.md for more information. Lastly,
check Istio and OPA logs to see if connections to packages.local are not
reaching Nexus, e.g., perhaps due to an authorization issue.

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

```bash
pit# ./install.sh --continue
...
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
```bash
pit# ./install.sh --continue
...
time="2021-02-23T19:55:54Z" level=fatal msg="Error copying tag \"dir:/image/grafana/grafana:7.0.3\": Error writing blob: Head \"https://registry.local/v2/grafana/grafana/blobs/sha256:cf254eb90de2dc62aa7cce9737ad7e143c679f5486c46b742a1b55b168a736d3\": dial tcp: lookup registry.local: no such host"
+ return
```

This error is most likely _intermittent_ and running `./install.sh --continue`
again is expected to succeed.