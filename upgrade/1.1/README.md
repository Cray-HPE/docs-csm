Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 1.1.0 Upgrade Guide

This guide contains procedures for upgrading systems running CSM 1.0.0 to CSM
1.1.0. It is intended for system installers, system administrators, and network
administrators. It assumes some familiarity with standard Linux and associated
tooling.

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Update customizations.yaml](#update-customizations)
- [Setup Nexus](#setup-nexus)
- [Upgrade Services](#upgrade-services)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Verify CSM Version in Product Catalog](#verify-version)
- [Exit Typescript](#exit-typescript)


<a name="changes"></a>
## Changes

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.

<a name="preparation"></a>
## Preparation

For convenience, these procedures make use of environment variables. This
section sets the expected environment variables to appropriate values.

1. Start a typescript to capture the commands and output from this procedure.

   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set `CSM_DISTDIR` to the directory of the extracted release distribution for
   CSM 1.1.0:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to
   > `tar` when extracting a CSM release distribution as `root` to ensure the
   > extracted files are owned by `root` and have permissions based on the current
   > `umask` value.

   If using a release distribution:
   
   ```bash
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-1.1.0.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-1.1.0"
   ```
   
   Else if using a hotfix distribution:
   
   ```bash
   ncn-m001# CSM_HOTFIX="csm-1.1.0-hotfix-0.0.1"
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf ${CSM_HOTFIX}.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/${CSM_HOTFIX}"
   ncn-m001# echo $CSM_DISTDIR
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by
   `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```

1. Download and install/upgrade the _latest_ workaround and
   documentation RPMs. If this machine does not have direct internet access
   these RPMs will need to be externally downloaded and then copied to be
   installed.

   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/csm-1.1/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/csm-1.1/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

1. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM
   for the CSM 1.1.0 upgrade:

   ```bash
   ncn-m001# CSM_SCRIPTDIR=/usr/share/doc/csm/upgrade/1.1/scripts
   ```

<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../operations/validate_csm_health.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.

<a name="update-customizations"></a>
## Update customizations.yaml

Perform these steps to update customizations.yaml:

 1. Prepare work area

     If you manage customizations.yaml in an external Git repository (as recommended), then clone a local working tree.

    ```
    ncn-m001:~ # git clone <URL> /root/site-init
    ncn-m001:~ # cd /root/site-init
    ```

    If you do not have a backup of site-init then perform the following steps to create a new one using the values stored in the Kubernetes cluster.

    * Create a new site-init directory using from the CSM tarball

      ```
      ncn-m001:~ # cp -r ${CSM_DISTDIR}/shasta-cfg /root/site-init
      ncn-m001:~ # cd /root/site-init
      ```
	
    * Extract customizations.yaml from the site-init secret
	
      ```
      ncn-m001:~/site-init # kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```
	
    * Extract the certificate and key used to create the sealed secrets
	
      ```
      ncn-m001:~/site-init # mkdir certs
      ncn-m001:~/site-init # kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn-m001:~/site-init # kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

  > **Note**: All subsequent steps of this procedure should be performed within the `/root/site-init` directory created in this step.

1. Update customizations.yaml

   Apply new values required for PowerDNS

   ```
   ncn-m001:~/site-init # ${CSM_SCRIPTDIR}/upgrade/update-customizations.sh -i customizations.yaml
   ```
   
   Generate the new PowerDNS API key secret

   ```
   ncn-m001:~/site-init # ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

1. Update the `site-init` secret

   ```
   ncn-m001:~/site-init # kubectl delete secret -n loftsman site-init
   ncn-m001:~/site-init # kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Commit changes to customizations.yaml if using an external Git repository.

   ```
   ncn-m001:~/site-init # git add customizations.yaml
   ncn-m001:~/site-init # git commit -m 'Add required PowerDNS configuration'
   ncn-m001:~/site-init # git push
   ```

<a name="setup-nexus"></a>
## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult the [known
issues](../../install/install_csm_services.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.

<a name="upgrade-services"></a>
## Upgrade Services

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:

   ```bash
   ncn-m001# ./upgrade.sh
   ```

**Note**: If you have not already installed the workload manager product
including slurm and munge, then the `cray-crus` pod is expected to be in the
`Init` state. After running `upgrade.sh`, you may observe there are now *two*
copies of the `cray-crus` pod in the `Init` state. This situation is benign and
should resolve itself once the workload manager product is installed.


<a name="run-validation-checks-post-upgrade"></a>
## Run Validation Checks (Post-Upgrade)

> **`IMPORTANT:`** Wait at least 15 minutes after
> [`upgrade.sh`](#upgrade-services) completes to let the various Kubernetes
> resources get initialized and started.

Run the following validation checks to ensure that everything is still working
properly after the upgrade:

- [Platform health checks](../../operations/validate_csm_health.md#platform-health-checks)


Other health checks may be run as desired.

> **`CAUTION:`** The following HMS functional tests may fail because of locked
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
> Failures of these tests because of locked components as shown above can be safely
> ignored.

**`NOTE:`** If you plan to do any further CSM health validation, you should follow the validation
procedures found in the CSM v1.1 documentation. Some of the information in the CSM v1.0 validation
documentation is no longer accurate in CSM v1.1.

<a name="verify-version"></a>
## Verify CSM Version in Product Catalog

1. Verify the CSM version has been updated in the product catalog. Verify that the
   following command includes version `1.1.0`:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key'
   1.1.0
   1.0.0
   ```

2. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.1.0".configuration.import_date'
   ```


<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
