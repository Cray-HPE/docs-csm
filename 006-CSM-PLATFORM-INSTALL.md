# CSM Platform Install

This page will go over how to install CSM applications and services (i.e., into
the CSM Kubernetes cluster).

* [Verify settings in `customizations.yaml`](#verify-customizations)
* [Initialize bootstrap container registry](#init-bootstrap-registry)
* [Configure proxy to upstream registry](#registry-proxy)
* [Follow `INSTALL` instructions](#install)


<a name="verfy-customizations" ></a>
## Verify settings in customizations.yaml

Make sure the IP addresses in the `customizations.yaml` file in this repo align
with the IPs generated in CSI.

> File location: `/var/www/ephemeral/prep/site-init/customizations.yaml`

In particular, pay careful attention to these settings:

```
spec.network.static_ips.dns.site_to_system_lookups
spec.network.static_ips.ncn_masters
spec.network.static_ips.ncn_storage
```

> **`TODO`**: For automation this should be checked, if this step is still used
> when automation lands.


<a name="init-bootstrap-registry"></a>
## Initialize bootstrap container registry

> **`SKIP IF ONLINE`** - Online installs cannot upload container images to the
> bootstrap registry since it proxies an upstream source.

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


<a name="registry-proxy"></a>
## Configure proxy to upstream registry

> **`SKIP IF AIRGAP/OFFLINE`** - Online installs require a URL to the proxied
> registry.

The default configuration sets up the Nexus registry on the LiveCD as `type:
hosted` and container images must be imported ([see
above](#init-bootstrap-registry)). In order to proxy container images from an
upstream registry:

1.  Stop Nexus:

    ```bash
    pit:~ # systemctl stop nexus
    ```

2.  Remove `nexus` container:

    ```bash
    pit:~ # podman container exists nexus && podman container rm nexus
    ```

3.  Remove `nexus-data` volume:

    ```bash
    pit:~# podman volume rm nexus-data
    ```

4.  Add the corresponding URL to the `ExecStartPost` script in
    /usr/lib/systemd/system/nexus.service. For example, Cray internal systems
    may want to proxy to https://dtr.dev.cray.com as follows:

    ```bash
    pit:~ # URL=https://dtr.dev.cray.com
    pit:~ # sed -e "s,^\(ExecStartPost=/usr/sbin/nexus-setup.sh\).*$,\1 $URL," -i /usr/lib/systemd/system/nexus.service
    ```

5.  Restart Nexus:

    ```bash
    pit:~ # systemctl start nexus
    ```


<a name="install"></a>
## Follow INSTALL instructions

Change into the directory where you extracted the CSM Release distribution,
`/var/www/ephemeral/${CSM_RELEASE}`, and complete the CSM install by following
instructions in `INSTALL`.
