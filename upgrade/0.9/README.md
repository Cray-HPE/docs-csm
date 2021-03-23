Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9 Patch Upgrade Guide


## About

This guide contains procedures for upgrading systems running CSM 0.9 to the
latest available patch release. It is intended for system installers, system
administrators, and network administrators. It assumes some familiarity with
standard Linux and associated tooling.

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.


### Conventions


#### Restricting procedures to a specific patch release

Select procedures are annotated to indicate they are only applicable to
specific Shasta patch releases.

> **`WARNING:`** Follow this procedure only when upgrading to CSM 0.9.1.

> **`WARNING:`** Follow this procedure only when upgrading from CSM 0.9.0.


#### Environment variables

For convenience these procedures use the following environment variables:

- `CSM_RELEASE` - The CSM release version, e.g., `0.9.1`.
- `CSM_DISTDIR` - The directory of the _extracted_ CSM release distribution.


## Preparation

The remainder of this guide assumes the new CSM release distribution has been
extracted at `$CSM_DISTDIR`.

> **`NOTE`**: Use `--no-same-owner` and `--no-same-permissions` options to
> `tar` when extracting a CSM release distribution as `root` to ensure the
> extracted files are owned by `root` and have permissions based on the current
> `umask` value.

List current CSM versions in the product catalog:

```bash
ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
```

Run `${CSM_DISTDIR}/lib/version.sh` to verify that the intended CSM release is
being used for the upgrade.


## Update Customizations.yaml and Site-Init Secret

TODO


## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# ${CSM_DISTDIR}/lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ${CSM_DISTDIR}/lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
```

In the event of an error, consult the [known issues](#known-issues) below to
resolve potential problems and then try running `setup-nexus.sh` again. Note
that subsequent runs of `setup-nexus.sh` may report `FAIL` when uploading
duplicate assets. This is ok as long as `setup-nexus.sh` outputs
`setup-nexus.sh: OK` and exits with status code `0`.


### Known Issues

#### Error initiating layer upload ... in registry.local: received unexpected HTTP status: 200 OK

The following error may occur when running `lib/setup-nexus.sh`:

```
time="2021-02-07T20:25:22Z" level=info msg="Copying image tag 97/144" from="dir:/image/jettech/kube-webhook-certgen:v1.2.1" to="docker://registry.local/jettech/kube-webhook-certgen:v1.2.1"
Getting image source signatures
Copying blob sha256:f6e131d355612c71742d71c817ec15e32190999275b57d5fe2cd2ae5ca940079
Copying blob sha256:b6c5e433df0f735257f6999b3e3b7e955bab4841ef6e90c5bb85f0d2810468a2
Copying blob sha256:ad2a53c3e5351543df45531a58d9a573791c83d21f90ccbc558a7d8d3673ccfa
time="2021-02-07T20:25:33Z" level=fatal msg="Error copying tag \"dir:/image/jettech/kube-webhook-certgen:v1.2.1\": Error writing blob: Error initiating layer upload to /v2/jettech/kube-webhook-certgen/blobs/uploads/ in registry.local: received unexpected HTTP status: 200 OK"
+ return
```

This error is most likely _intermittent_ and running `lib/setup-nexus.sh`
again is expected to succeed.

#### Error lookup registry.local: no such host

The following error may occur when running `lib/setup-nexus.sh`:
```
time="2021-02-23T19:55:54Z" level=fatal msg="Error copying tag \"dir:/image/grafana/grafana:7.0.3\": Error writing blob: Head \"https://registry.local/v2/grafana/grafana/blobs/sha256:cf254eb90de2dc62aa7cce9737ad7e143c679f5486c46b742a1b55b168a736d3\": dial tcp: lookup registry.local: no such host"
+ return
```

Or a similar error:
```
time="2021-03-04T22:45:07Z" level=fatal msg="Error copying ref \"dir:/image/cray/cray-ims-load-artifacts:1.0.4\": Error trying to reuse blob sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217 at destination: Head \"https://registry.local/v2/cray/cray-ims-load-artifacts/blobs/sha256:1ec886c351fa4c330217411b0095ccc933090aa2cd7ae7dcd33bb14b9f1fd217\": dial tcp: lookup registry.local: Temporary failure in name resolution"
+ return
```

These errors are most likely _intermittent_ and running `lib/setup-nexus.sh`
again is expected to succeed.


## Deploy Upgraded Manifests

```bash
ncn-m001# ${CSM_DISTDIR}/install.sh --upgrade
```


## Upgrade NCN RPMs

TODO Use CFS?
