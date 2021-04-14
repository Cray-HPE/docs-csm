Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9.3 Patch Upgrade Guide

This guide contains procedures for upgrading systems running CSM 0.9.2 to CSM
0.9.3. It is intended for system installers, system administrators, and network
administrators. It assumes some familiarity with standard Linux and associated
tooling.

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Setup Nexus](#setup-nexus)
- [Deploy Manifests](#deploy-manifests)
- [Upgrade NCN RPMs](#upgrade-ncn-rpms)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)


<a name="preparation"></a>
## Preparation

For convenience, these procedures make use of environment variables. This
section sets the expected environment variables to the appropriate values.

1. Set `CSM_DISTDIR` to the directory of the extracted release distribution for
   CSM 0.9.3:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to
   > `tar` when extracting a CSM release distribution as `root` to ensure the
   > extracted files are owned by `root` and have permissions based on the current
   > `umask` value.

   ```bash
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.3.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-0.9.3"
   ```

2. Set `CSM_RELEASE_VERSION` to the version reported by
   `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ```

3. Set `CSM_SYSTEM_VERSION` to `0.9.2`:

   ```bash
   ncn-m001# CSM_SYSTEM_VERSION="0.9.2"
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```bash
   > ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
   > ```


<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../008-CSM-VALIDATION.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.


<a name="setup-nexus"></a>
## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ./lib/setup-nexus.sh
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


<a name="deploy-manifests"></a>
## Deploy Manifests

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# ./upgrade.sh
```


<a name="upgrade-ncn-packages"></a>
## Upgrade NCN Packages

Upgrade CSM packages on NCNs:

```bash
ncn-m001# pdsh -w $(./lib/list-ncns.sh | paste -sd,) "zypper ar -fG https://packages.local/repository/csm-sle-15sp2/ csm-sle-15sp2 && zypper up -y"
```


<a name="run-validation-checks-post-upgrade"></a>
## Run Validation Checks (Post-Upgrade)

> **`IMPORTANT:`** Wait at least 15 minutes after
> [`upgrade.sh`](#deploy-manifests) completes to let the various Kubernetes
> resources get initialized and started.

Run the following validation checks to ensure that everything is still working
properly after the upgrade:

1. [Platform health checks](../../008-CSM-VALIDATION.md#platform-health-checks)
2. [Network health checks](../../008-CSM-VALIDATION.md#network-health-checks)

Other health checks may be run as desired.

> **`CAUTION:`** The following HMS functional tests may fail due to locked
> components in HSM:
>
> 1. `test_bss_bootscript_ncn-functional_remote-functional.tavern.yaml`
> 2. `test_smd_components_ncn-functional_remote-functional.tavern.yaml`
>
> ```bash
>         Traceback (most recent call last):
>           File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
>             verifier.validate()
>           File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
>             raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
>         pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
>          - Key 'Locked' was not defined. Path: '/Components/0'.
>          - Key 'Locked' was not defined. Path: '/Components/5'.
>          - Key 'Locked' was not defined. Path: '/Components/6'.
>          - Key 'Locked' was not defined. Path: '/Components/7'.
>          - Key 'Locked' was not defined. Path: '/Components/8'.
>          - Key 'Locked' was not defined. Path: '/Components/9'.
>          - Key 'Locked' was not defined. Path: '/Components/10'.
>          - Key 'Locked' was not defined. Path: '/Components/11'.
>          - Key 'Locked' was not defined. Path: '/Components/12'.: Path: '/'>
> ```
>
> Failures of these tests due to locked components as shown above can be safely
> ignored.
