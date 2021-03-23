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

TODO Consult the [SHASTA-CFG guide](../../067-SHASTA-CFG.md)


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

In the event of an error, consult the [known
issues](../../006-CSM-PLATFORM-INSTALL.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.


## Deploy Upgraded Manifests

```bash
ncn-m001# ${CSM_DISTDIR}/upgrade.sh
```


## Upgrade NCN RPMs

TODO Use CFS?
