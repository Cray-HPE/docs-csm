# SSL Certificate Validation Issues

## SSL Validation Fails During the Installation Process

If the Intermediate CA that's used to sign service certificates changes after
the NCNs are brought up then this causes the platform-ca on the NCNs to no
longer be valid. This is due to the platform-ca only being pulled via cloud-init
on first boot. You can run the following goss test to validate this is the
case.

```bash
goss -g /opt/cray/tests/install/ncn/tests/goss-platform-ca-certs-match-cloud-init.yaml v
```

If this test fails, then you should run the following commands to update the
platform-ca.

```bash
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

## SSL Validation Only Fails in Python Applications

Python3 applications, such as CFS, will fail to validate the API Gateway's SSL
certificate if a non-SuSE provided certifi python package is used. This is due
to the official certifi package using its own CA certificate bundle instead
of the system's bundle. This normally happens if `pip install` is used to
install an application with a certifi dependency. To see what version of certifi
you are using, run `pip show certifi`.

```bash
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
```

If this points to a local directory or is a different version then `2018.1.18`
then you will need to uninstall this certifi package in order to trust the
platform CA. The following command shows the expected output on a `1.2.5`
system.

```bash
ncn-m001:~ # pip show certifi
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

If the platform CA wasn't available in the system's CA certificate bundle when
containerd started then the system will show SSL validation errors when talking
to `https://registry.local`. This is due to containerd caching the CA bundle on
startup. In order to fix this you will need to restart the `containerd` service.

```bash
systemctl restart containerd
```
