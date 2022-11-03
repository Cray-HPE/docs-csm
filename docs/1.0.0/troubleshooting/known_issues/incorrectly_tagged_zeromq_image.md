# Incorrectly Tagged `zeromq` Image

CSM 1.0.11 shipped a version of `shasta-cfg` which expects the `zeromq` image to be tagged differently to the one shipped in the product tarball. This may result in the following error when performing the "Generate Sealed Secrets" step in [prepare_site_init.md](../../install/prepare_site_init.md#generate-sealed-secrets).

```ShellSession
pit# /mnt/pitdata/prep/site-init/utils/secrets-seed-customizations.sh \
> /mnt/pitdata/prep/site-init/customizations.yaml
Creating Sealed Secret keycloak-certs
  Generating type static_b64...
Creating Sealed Secret keycloak-master-admin-auth
  Generating type static...
  Generating type static...
  Generating type randstr...
  Generating type static...
Creating Sealed Secret cray-reds-credentials
  Generating type static...
  Generating type static...
Creating Sealed Secret cray-meds-credentials
  Generating type static...
Creating Sealed Secret cray-hms-rts-credentials
  Generating type static...
  Generating type static...
Creating Sealed Secret vcs-user-credentials
  Generating type randstr...
  Generating type static...
Creating Sealed Secret generated-platform-ca-1
  Generating type platform_ca...
Creating Sealed Secret pals-config
  Generating type zmq_curve...
Trying to pull arti.dev.cray.com/third-party-docker-stable-local/zeromq/zeromq:v4.0.5...
  Get https://arti.dev.cray.com/v2/: dial tcp: lookup arti.dev.cray.com on 16.110.135.52:53: dial udp 16.110.135.52:53: connect: network is unreachable
Error: unable to pull arti.dev.cray.com/third-party-docker-stable-local/zeromq/zeromq:v4.0.5: Error initializing source docker://arti.dev.cray.com/third-party-docker-stable-local/zeromq/zeromq:v4.0.5: error pinging docker registry arti.dev.cray.com: Get https://arti.dev.cray.com/v2/: dial tcp: lookup arti.dev.cray.com on 16.110.135.52:53: dial udp 16.110.135.52:53: connect: network is unreachable
```

The `zeromq` image needs to be re-tagged to work around this issue.

1. Determine the image id of the `zeromq` image.
   
   ```bash
   pit# podman images *zeromq*
   ```

   Expected output looks similar to the following:

   ```text
   REPOSITORY                      TAG     IMAGE ID      CREATED      SIZE
   dtr.dev.cray.com/zeromq/zeromq  v4.0.5  1648d2dfc45f  7 years ago  462 MB
   ```

1. Tag the image.

   ```bash
   pit# podman tag 1648d2dfc45f arti.dev.cray.com/third-party-docker-stable-local/zeromq/zeromq:v4.0.5
   ```

1. Validate that the image was correctly re-tagged.

   ```bash
   pit# podman images *zeromq*
   ```

   Expected output will look similar to the following:

   ```text
   REPOSITORY                                                       TAG     IMAGE ID      CREATED      SIZE
   dtr.dev.cray.com/zeromq/zeromq                                   v4.0.5  1648d2dfc45f  7 years ago  462 MB
   arti.dev.cray.com/third-party-docker-stable-local/zeromq/zeromq  v4.0.5  1648d2dfc45f  7 years ago  462 MB
   ```

The "Generate Sealed Secrets" procedure will now succeed.
