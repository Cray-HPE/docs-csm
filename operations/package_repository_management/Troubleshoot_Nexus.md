# Troubleshoot Nexus

This page contains general Nexus troubleshooting topics.

- [`lookup registry.local: no such host`](#lookup-registrylocal-no-such-host)
- [`Error initiating layer upload` ... `in registry.local`](#error-initiating-layer-upload--in-registrylocal)
- [`error: not ready: https://packages.local`](#error-not-ready-httpspackageslocal)

## `lookup registry.local: no such host`

The following error may occur when running `./lib/setup-nexus.sh`:

```text
time="2021-02-23T19:55:54Z" level=fatal msg="Error copying tag \"dir:/image/grafana/grafana:7.0.3\": Error writing blob: Head \"https://registry.local/v2/grafana/grafana/blobs/sha256:cf254eb90de2dc62aa7cce9737ad7e143c679f5486c46b742a1b55b168a736d3\": dial tcp: lookup registry.local: no such host"
+ return
```

Or a similar error:

```text
time="2021-03-04T22:45:07Z" level=fatal msg="Error copying ref \"dir:/image/cray/cray-ims-load-artifacts:1.0.4\": Error trying to reuse blob sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217 at destination: Head \"https://registry.local/v2/cray/cray-ims-load-artifacts/blobs/sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217\": dial tcp: lookup registry.local: Temporary failure in name resolution"
+ return
```

These errors are most likely _intermittent_ and running `./lib/setup-nexus.sh`
again is expected to succeed.

## `Error initiating layer upload` ... `in registry.local`

The following error may occur when running `./lib/setup-nexus.sh`:

```text
time="2021-02-07T20:25:22Z" level=info msg="Copying image tag 97/144" from="dir:/image/jettech/kube-webhook-certgen:v1.2.1" to="docker://registry.local/jettech/kube-webhook-certgen:v1.2.1"
Getting image source signatures
Copying blob sha256:f6e131d355612c71742d71c817ec15e32190999275b57d5fe2cd2ae5ca940079
Copying blob sha256:b6c5e433df0f735257f6999b3e3b7e955bab4841ef6e90c5bb85f0d2810468a2
Copying blob sha256:ad2a53c3e5351543df45531a58d9a573791c83d21f90ccbc558a7d8d3673ccfa
time="2021-02-07T20:25:33Z" level=fatal msg="Error copying tag \"dir:/image/jettech/kube-webhook-certgen:v1.2.1\": Error writing blob: Error initiating layer upload to /v2/jettech/kube-webhook-certgen/blobs/uploads/ in registry.local: received unexpected HTTP status: 200 OK"
+ return
```

This error is most likely _intermittent_ and running `./lib/setup-nexus.sh`
again is expected to succeed.

## `error: not ready: https://packages.local`

The `error: not ready: https://packages.local` indicates that from
the caller's perspective, Nexus is not ready to receive writes. However, it most
likely indicates that a Nexus setup utility was unable to connect to Nexus
via the `packages.local` name. Because the install does not attempt to connect
to `packages.local` until Nexus has been successfully deployed, the error
does not usually indicate something is actually wrong with Nexus. Instead, it
is most commonly a network issue with name resolution (i.e., DNS), IP
routes from the PIT node, switch misconfiguration, or Istio ingress.

Verify that `packages.local` resolves to **ONLY** the load balancer IP address for the
`istio-ingressgateway` service in the `istio-system` namespace, typically
`10.92.100.71`. If name resolution returns addresses on other networks (such as
HMN), this must be corrected. Prior to DNS/DHCP hand-off to Unbound, these
settings are controlled by `dnsmasq`. Unbound settings are based on SLS
settings in `sls_input_file.json` and must be updated via the Unbound manager.

If `packages.local` resolves to the correct addresses, verify basic
connectivity using `ping`. If `ping packages.local` is unsuccessful, verify the
IP routes from the PIT node to the NMN load balancer network. The
typical `ip route` configuration is `10.92.100.0/24 via 10.252.0.1 dev bond0.nmn0`.
If `ping` attempts are successful, then try checking the status of Nexus by
running `curl -sS https://packages.local/service/rest/v1/status/writable`. If
the connection times out, it indicates there is a more complex connection
issue. Lastly, check Istio and OPA logs to see if connections to `packages.local` are not
reaching Nexus, perhaps because of an authorization issue.

If `https://packages.local/service/rest/v1/status/writable` returns an HTTP
code other than `200 OK`, it indicates there is an issue with Nexus. Verify
that the `loftsman ship` deployment of the `nexus.yaml` manifest was
successful. If `helm status -n nexus cray-nexus` indicates the status is
**NOT** `deployed`, then something is most likely wrong with the Nexus
deployment and additional diagnosis is required. In this case, the current
Nexus deployment probably needs to be uninstalled and the `nexus-data` PVC
removed before attempting to deploy again.
