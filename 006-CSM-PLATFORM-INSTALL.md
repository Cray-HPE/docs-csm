# CSM Platform Install

This page will go over how to install CSM applications and services (i.e.,
into the CSM Kubernetes cluster).

* [Verify Settings in customizations.yaml](#verify-settings)
* [Initialize Bootstrap Registry](#initialize-bootstrap-registry)
* [Run install.sh](#run-install-sh)
* [Known Issues](#known-issues)
  * [Error: not ready: https://packages.local](#error-not-ready)

<a name="verify-settings"></a>
## Verify Settings in customizations.yaml

Make sure the IP addresses in the `customizations.yaml` file in this repo
align with the IPs generated in CSI.

> File location: `/var/www/ephemeral/prep/site-init/customizations.yaml`

In particular, pay careful attention to these settings:

```
spec.network.static_ips.dns.site_to_system_lookups
spec.network.static_ips.ncn_masters
spec.network.static_ips.ncn_storage
```

> **`TODO`**: For automation this should be checked, if this step is still
> used when automation lands.


<a name="initialize-bootstrap-registry"></a>
## Initialize Bootstrap Registry

> **`SKIP IF ONLINE`** - Online installs cannot upload container images to the
> bootstrap registry since it proxies an upstream source. **DO NOT** perform
> this procedure if the bootstrap registry was [reconfigured to proxy from an
> upstream registry](005-CSM-METAL-INSTALL.md#configure-bootstrap-registry-to-proxy-an-upstream-registry). 

1.  Verify that Nexus is running:

    ```bash
    pit:~ # systemctl status nexus
    ```

2.  Verify that Nexus is _ready_. (Any HTTP response other than `200 OK`
    indicates Nexus is not ready.)

    ```bash
    pit:~ # curl -sSif http://localhost:8081/service/rest/v1/status/writable
    HTTP/1.1 200 OK
    Date: Thu, 04 Feb 2021 05:27:44 GMT
    Server: Nexus/3.25.0-03 (OSS)
    X-Content-Type-Options: nosniff
    Content-Length: 0

    ```

3.  Load the skopeo image installed by the cray-nexus RPM:

    ```bash
    pit:~ # podman load -i /var/lib/cray/container-images/cray-nexus/skopeo-stable.tar
    ```

4.  Use `skopeo sync` to upload container images from the CSM release:

    ```bash
    pit:~ # podman run --rm --network host -v /var/www/ephemeral/${CSM_RELEASE}/docker/dtr.dev.cray.com:/images:ro quay.io/skopeo/stable sync --scoped --src dir --dest docker --dest-tls-verify=false --dest-creds admin:admin123 /images localhost:5000
    ```


<a name="run-install-sh"></a>
## Run install.sh

> **`NOTE`** `install.sh` requires various system configuration which are
> expected to be found in the locations used in proceeding documentation;
> however, it needs to know `SYSTEM_NAME` in order to find `metallb.yaml` and
> `sls_input_file.json` configuration files.
>
> ```bash
> pit:~ # export SYSTEM_NAME=eniac
> ```

Complete the CSM install by running `install.sh`.

```bash
pit:~ # cd /var/www/ephemeral/$CSM_RELEASE
pit:/var/www/ephemeral/$CSM_RELEASE # ./install.sh
```

> **`NOTE`** `install.sh` will exit with instructions that may be copied and
> pasted to switch DNS settings from dnsmasq to Unbound and then to continue the
> installation. For example:
> 
> ```bash
> pit:/var/www/ephemeral/csm-0.7.24 # ./install.sh
> ...
> 
> Continue with the installation after performing the following steps to switch
> DNS settings from dnsmasq on the pit server to Unbound running in Kubernetes:
> 
> 1. Unbound is listening on 10.92.100.225, verify it is working by resolving
>    e.g., ncn-w001.nmn:
> 
>     pit:/var/www/ephemeral/csm-0.7.24 # dig "@10.92.100.225" +short ncn-w001.nmn
> 
> 2. Run the following two commands on all NCN manager, worker, and storage
>    nodes as well as the pit server:
> 
>     # sed -e "s/^\(NETCONFIG_DNS_STATIC_SERVERS\)=.*$/\1=\"10.92.100.225"/" -i /etc/sysconfig/network/config
>     # netconfig update -f
> 
> 3. Stop dnsmasq on the pit server:
> 
>     pit:/var/www/ephemeral/csm-0.7.24 # systemctl stop dnsmasq
>     pit:/var/www/ephemeral/csm-0.7.24 # systemctl disable dnsmasq
> 
> 4. Continue with the installation:
> 
>     pit:/var/www/ephemeral/csm-0.7.24 # ./install.sh --continue
> ```

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
