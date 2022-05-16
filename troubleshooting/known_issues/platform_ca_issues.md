# Common Platform CA Issues

## NCN Platform CA Certificate Does Not Match Certificate in BSS

During install, if the beginning steps are re-run after the NCNs are booted,
then their `platform-ca` file will no longer match the server's CA. This can be
detected with a Goss test.

### Error Messages

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

### Check

Command:

```bash
goss -g /opt/cray/tests/install/ncn/tests/goss-platform-ca-certs-match-cloud-init.yaml v
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

### Solution

Run the following commands on any failed NCNs to update the `platform-ca` file.

```bash
curl http://10.92.100.71:8888/meta-data | jq -r  '.Global."ca-certs".trusted[]' > /etc/pki/trust/anchors/platform-ca-certs.crt
update-ca-certificates
```

If you are having problems with cfs-state-reporter then you should also restart
the cfs-state-reporter service:

```bash
systemctl restart cfs-state-reporter
```

## Certifi Has Been Updated and No Longer Respects the Local ca-bundle

SLES ships a modified version of the python3 certifi module. This module
uses the local ca-bundle.pem file. If certifi is updated, usually due to a pip
install, then the ca bundle that certifi uses will revert to the one that's
shipped with the module. This prevents any python program that uses certifi,
such as the ones that use the requests module, from being able to validate a
server that uses the platform CA.

### Error Message

```text
Error calling https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token: HTTPSConnectionPool(host='api-gw-service-nmn.local', port=443): Max retries exceeded with url: /keycloak/realms/shasta/protocol/openid-connect/token (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:852)'),))
```

### Check

Command:

```bash
ncn# pip show ceritfy
```

Example Output:

```text
ncn-m001:~ # pip show certifi
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
ncn-m001:~ #
```

### Solutions

If certifi is installed in `/root/.local/...`, then you can uninstall it by
running

```bash
  pip uninstall certifi
```

If certifi is installed in `/usr/lib/python3.6/site-packages` then you will need
to reinstall the certifi RPM that ships with SLES. If this is not possible,
you can run the following commands to replace the CA bundle that certifi uses
with a link to the system's ca-bundle.

```bash
CERTIFIDIR="$(pip show certifi | grep Location | awk '{print $2}')/certifi"
mv "$CERTIFIDIR"/cacert.pem "$CERTIFIDIR"/cacert.pem.orig
ln -s /var/lib/ca-certificates/ca-bundle.pem "$CERTIFIDIR"/cacert.pem
```

If you are having problems with cfs-state-reporter then you should also restart
the cfs-state-reporter service:

```bash
ncn# systemctl restart cfs-state-reporter
```

## update-ca-certificates Fails to Add platform-ca to ca-bundle

`update-ca-certificates` can occasionally fail to add the platform-ca-certs.crt
file to the system's ca-bundle.pem. This can cause the same error message as
the previous issues. If the previous checks don't show any issues then try
the solution outlined below.

### Error Messages

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

### Solution

Run the following commands to regenerate the ca-bundle.pem file with the
platform-ca-certs.crt file included.

```bash
rm /var/lib/ca-certificates/ca-bundle.pem
update-ca-certificates
```

If you are having problems with cfs-state-reporter then you should also restart
the cfs-state-reporter service:

```bash
ncn# systemctl restart cfs-state-reporter
```
