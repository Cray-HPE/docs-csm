# SSL Certificate Validation Issues

## 1 SSL validation fails during the installation process

If the intermediate CA that is used to sign service certificates changes after
the NCNs are brought up, then this causes the `platform-ca` on the NCNs to no
longer be valid. This is due to the `platform-ca` only being pulled via `cloud-init`
on first boot. Run the following Goss test to validate this is the case.

### 1.1 Error messages

```console
/opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
{"ID":"x3007c0s12b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3007c0s15b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3007c0s16b0","LastDiscoveryStatus":"HTTPsGetFailed"}
FAIL: smd_discovery_status_test found no successfully discovered endpoints
'/opt/cray/tests/ncn-smoke/hms/hms-smd/smd_discovery_status_test_ncn-smoke.sh' exited with status code: 1
```

```console
curl https://api-gw-services-nmn.local/PATH
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

### 1.2 Solution

```console
goss -g /opt/cray/tests/install/ncn/tests/goss-platform-ca-certs-match-cloud-init.yaml v
```

If this test fails, then run the following commands in order to update the `platform-ca`.

```console
mv /var/lib/ca-certificates/ca-bundle.pem /root/ca-bundle.pem.bak
curl http://10.92.100.71:8888/meta-data | jq -r  '.Global."ca-certs".trusted[]' \
        > /etc/pki/trust/anchors/platform-ca-certs.crt
update-ca-certificates
systemctl restart containerd
```

Note: This will save a copy of the original CA bundle in `/root/ca-bundle.pem.bak`.
Normally `update-ca-certificates` will update this file without having to move
it. However, there are times when `update-ca-certificates` fails to update the
CA bundle if the file exists.

## 2 SSL validation only fails in Python applications

### 2.1 Error messages

```text
python3[3705657]: Unable to contact CFS to report component status: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443):
Max retries exceeded with url: /apis/cfs/v3/components/XNAME (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate
verify failed (_ssl.c:852)'),))
```

```text
Error calling https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443):
Max retries exceeded with url: /keycloak/realms/shasta/protocol/openid-connect/token (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:852)'),))
```

### 2.2 Solution

`python3` applications, such as CFS, will fail to validate the API Gateway's SSL
certificate if a non-SuSE-provided `certifi` Python package is used. This is due
to the official `certifi` package using its own CA certificate bundle instead
of the system's bundle. This normally happens if `pip install` is used to
install an application with a `certifi` dependency. To see the version of `certifi`
on the system, run `pip show certifi`.

```console
pip show certifi
Name: certifi
Version: 2021.10.8
Summary: Python package for providing Mozilla's CA Bundle.
Home-page: https://certifiio.readthedocs.io/en/latest/
Author: Kenneth Reitz
Author-email: me@kennethreitz.com
License: MPL-2.0
Location: /root/.local/lib/python3.6/site-packages/certifi-2021.10.8-py3.6.egg
Requires:
Required-by: canu, kubernetes, requests
```

If this points to a local directory or is a different version then `2018.1.18`
then uninstall this `certifi` package in order to trust the
platform CA. The following command shows the expected output on a CSM v1.3
system.

```console
pip show certifi
Name: certifi
Version: 2018.1.18
Summary: Python package for providing Mozilla's CA Bundle.
Home-page: http://certifi.io/
Author: Kenneth Reitz
Author-email: me@kennethreitz.com
License: MPL-2.0
Location: /usr/lib/python3.6/site-packages
Requires:
Required-by: kubernetes, requests
```

If `certifi` is installed in `/usr/lib/python3.6/site-packages`, then
reinstall the `certifi` RPM that ships with SLES. If this is not possible,
run the following commands to replace the `ca-bundle` that `certifi` uses
with a link to the system's `ca-bundle`.

```bash
CERTIFIDIR="$(pip show certifi | grep Location | awk '{print $2}')/certifi"
mv "$CERTIFIDIR"/cacert.pem "$CERTIFIDIR"/cacert.pem.orig
ln -s /var/lib/ca-certificates/ca-bundle.pem "$CERTIFIDIR"/cacert.pem
```

## 3 SSL validation only fails with `podman` and/or pulling down Kubernetes containers

If the platform CA was not available in the system's CA certificate bundle when
`containerd` started then the system will show SSL validation errors when talking
to `https://registry.local`. This is due to `containerd` caching the CA bundle on
startup.

### 3.1 Error message

```text
Get https://registry.local/v2/: x509: certificate signed by unknown authority
Error: unable to pull registry.local/IMAGE:TAG: Error initializing source docker://registry.local/IMAGE:TAG: error pinging docker registry
registry.local: Get https://registry.local/v2/: x509: certificate signed by unknown authority
```

### 3.2 Resolution of failure pulling containers

Restart the `containerd` service.

```console
systemctl restart containerd
```

## 4 `update-ca-certificates` fails to add `platform-ca` to `ca-bundle`

`update-ca-certificates` can occasionally fail to add the `platform-ca-certs.crt`
file to the system's `ca-bundle.pem`. This can cause the same error message as the
previous issues. If the previous checks do not show any issues, then try the
solution outlined below.

### 4.1 Error messages

```text
(Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:852)'),))
```

```text
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

### 4.2 Solution

Run the following commands on the affected node to regenerate the `ca-bundle.pem` file with the `platform-ca-certs.crt` file included.

```bash
rm -v /var/lib/ca-certificates/ca-bundle.pem
update-ca-certificates
```

If these issues are suspected to have caused problems with `cfs-state-reporter`, then restart the `cfs-state-reporter` service:

```bash
systemctl restart cfs-state-reporter
```
