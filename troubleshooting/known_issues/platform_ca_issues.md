# Common Platform CA Issues

## 1 NCN platform CA certificate does not match certificate in BSS

During install, if the beginning steps are re-run after the NCNs are booted,
then `platform-ca` files on those NCNs will no longer match the server's CA certificate.
This can be detected with a Goss test.

### 1.1 Error messages

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

### 1.2 Check

Command:

```bash
ncn# goss -g /opt/cray/tests/install/ncn/tests/goss-platform-ca-certs-match-cloud-init.yaml v
```

Example output:

```text
Failures/Skipped:

Title: Validate that the local platform CA bundle matches the one in cloud-init
Meta:
    desc: Validates that the local platform CA bundle matches the one in cloud-init
    sev: 0
Command: goss_platform_ca_certs_match_cloud_init: exit-status:
Expected
    <int>: 1
to equal
    <int>: 0

Total Duration: 0.058s
Count: 1, Failed: 1, Skipped: 0
```

### 1.3 Solution

Run the following commands on any affected NCNs in order to update the `platform-ca` file.

```bash
ncn# curl http://10.92.100.71:8888/meta-data | jq -r  '.Global."ca-certs".trusted[]' > /etc/pki/trust/anchors/platform-ca-certs.crt
ncn# update-ca-certificates
```

If the certificate issues are suspected to have caused problems with `cfs-state-reporter`, then restart
the `cfs-state-reporter` service:

```bash
ncn# systemctl restart cfs-state-reporter
```

## 2 `certifi` has been updated and no longer respects the local `ca-bundle`

SLES ships a modified version of the `python3` `certifi` module. This module
uses the local `ca-bundle.pem` file. If `certifi` is updated (usually due to a
`pip install`), then the `ca-bundle` that `certifi` uses will revert to the one that
is shipped with the module. This prevents any Python program that uses `certifi`,
such as the ones that use the `requests` module, from being able to validate a
server that uses the platform CA.

### 2.1 Error message

```text
Error calling https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443):
Max retries exceeded with url: /keycloak/realms/shasta/protocol/openid-connect/token (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:852)'),))
```

### 2.2 Check

Command:

```bash
ncn# pip show certifi
```

Example output:

```text
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

### 2.3 Solutions

If `certifi` is installed in `/root/.local/...`, then uninstall it by running the following command:

```bash
ncn# pip uninstall certifi
```

If `certifi` is installed in `/usr/lib/python3.6/site-packages`, then
reinstall the `certifi` RPM that ships with SLES. If this is not possible,
run the following commands to replace the `ca-bundle` that `certifi` uses
with a link to the system's `ca-bundle`.

```bash
ncn# CERTIFIDIR="$(pip show certifi | grep Location | awk '{print $2}')/certifi"
ncn# mv "$CERTIFIDIR"/cacert.pem "$CERTIFIDIR"/cacert.pem.orig
ncn# ln -s /var/lib/ca-certificates/ca-bundle.pem "$CERTIFIDIR"/cacert.pem
```

If these issues are suspected to have caused problems with `cfs-state-reporter`, then restart
the `cfs-state-reporter` service:

```bash
ncn# systemctl restart cfs-state-reporter
```

## 3 `update-ca-certificates` fails to add `platform-ca` to `ca-bundle`

`update-ca-certificates` can occasionally fail to add the `platform-ca-certs.crt`
file to the system's `ca-bundle.pem`. This can cause the same error message as
the previous issues. If the previous checks do not show any issues, then try
the solution outlined below.

### 3.1 Error messages

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

### 3.2 Solution

Run the following commands on the affected node to regenerate the `ca-bundle.pem` file with the
`platform-ca-certs.crt` file included.

```bash
ncn# rm -v /var/lib/ca-certificates/ca-bundle.pem
ncn# update-ca-certificates
```

If these issues are suspected to have caused problems with `cfs-state-reporter`, then restart
the `cfs-state-reporter` service:

```bash
ncn# systemctl restart cfs-state-reporter
```
