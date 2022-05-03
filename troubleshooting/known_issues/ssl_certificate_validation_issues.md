# SSL Certificate Validation Issues

## SSL Validation Fails During the Installation Process

If the Intermediate CA that's used to sign service certificates changes after
the NCNs are brought up then this causes the platform-ca on the NCNs to no
longer be valid. This is due to the platform-ca only being pulled via cloud-init
on first boot. You can run the following Goss test to validate this is the
case.

### Example Error Messages of Failure During Install

```console
ncn# /opt/cray/tests/ncn-resources/hms/hms-test/hms_run_ct_smoke_tests_ncn-resources.sh
and get
{"ID":"x3007c0s12b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3007c0s15b0","LastDiscoveryStatus":"HTTPsGetFailed"}
{"ID":"x3007c0s16b0","LastDiscoveryStatus":"HTTPsGetFailed"}
FAIL: smd_discovery_status_test found no successfully discovered endpoints
'/opt/cray/tests/ncn-smoke/hms/hms-smd/smd_discovery_status_test_ncn-smoke.sh' exited with status code: 1
```

```console
ncn# curl https://api-gw-services-nmn.local/PATH
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

### Resolution of Failure During Install

```console
ncn# goss -g /opt/cray/tests/install/ncn/tests/goss-platform-ca-certs-match-cloud-init.yaml v
```

If this test fails, then run the following commands in order to update the `platform-ca`.

```console
ncn# mv /var/lib/ca-certificates/ca-bundle.pem /root/ca-bundle.pem.bak
ncn# curl http://10.92.100.71:8888/meta-data | jq -r  '.Global."ca-certs".trusted[]' \
        > /etc/pki/trust/anchors/platform-ca-certs.crt
ncn# update-ca-certificates
ncn# systemctl restart containerd
```

Note: This will save a copy of the original CA bundle in `/root/ca-bundle.pem.bak`.
Normally `update-ca-certificates` will update this file without having to move
it. However, there are times when `update-ca-certificates` fails to update the
CA bundle if the file exists.

## SSL Validation Only Fails in Python Applications

### Example Error Messages of Failure in Python Applications

```text
python3[3705657]: Unable to contact CFS to report component status: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443):
Max retries exceeded with url: /apis/cfs/v2/components/XNAME (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate
verify failed (_ssl.c:852)'),))
```

```text
Error calling https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443): 
Max retries exceeded with url: /keycloak/realms/shasta/protocol/openid-connect/token (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:852)'),))
```

### Resolution of Failure in Python Applications

Python3 applications, such as CFS, will fail to validate the API Gateway's SSL
certificate if a non-SuSE-provided `certifi` Python package is used. This is due
to the official `certifi` package using its own CA certificate bundle instead
of the system's bundle. This normally happens if `pip install` is used to
install an application with a `certifi` dependency. To see the version of `certifi`
on the system, run `pip show certifi`.

```console
ncn# pip show certifi
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
ncn# pip show certifi
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

## SSL Validation Only Fails with Podman and/or Pulling Down Kubernetes Containers

If the platform CA was not available in the system's CA certificate bundle when
containerd started then the system will show SSL validation errors when talking
to `https://registry.local`. This is due to containerd caching the CA bundle on
startup.

### Example Error Message of Failure Pulling Containers

```text
Get https://registry.local/v2/: x509: certificate signed by unknown authority
Error: unable to pull registry.local/IMAGE:TAG: Error initializing source docker://registry.local/IMAGE:TAG: error pinging docker registry
registry.local: Get https://registry.local/v2/: x509: certificate signed by unknown authority
```

### Resolution of Failure Pulling Containers

Restart the `containerd` service.

```console
ncn# systemctl restart containerd
```
