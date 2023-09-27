# CSM 1.3.3 Patch Installation Instructions

## Introduction

This document guides an administrator through the patch update to Cray Systems Management (CSM) `v1.3.3` from `v1.3.0`, `v1.3.1`, or `v1.3.2`.
If upgrading from CSM `v1.2.2` directly to `v1.3.3`, follow the procedures described in [Upgrade CSM](../README.md) instead.

## Bug Fixes and Improvements

* Added monitoring and a `grafana` dashboard for SMF `kafka` server and zookeeper metrics in `prometheus`.
* Fixed authentication failure with the `keycloak` integration into Nexus due to a change to the `keycloak` `opa` policy which was recently patched.
* Fixed `dvs-mqtt` error in the Spire server configuration - note this is only an issue for a customer already running `mqtt` in their environment.

## Steps

1. [Preparation](#preparation)
1. [Update `customizations.yaml`](#update-customizationsyaml)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade CANU](#upgrade-canu)
1. [Upgrade services](#upgrade-services)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

## Preparation

1. (`ncn-m001#`) Start a typescript to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.3.3` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   CSM_DISTDIR="$(pwd)/csm-1.3.3"
   echo "${CSM_DISTDIR}"
   ```

1. (`ncn-m001#`) Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Update `customizations.yaml`

1. (`ncn-m001#`) Retrieve `customizations.yaml` from the `site-init` secret:

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "customizations.yaml"
   ```

1. (`ncn-m001#`) Add customizations for the `cray-hms-hmcollector` Helm chart:

   ```bash
   yq w -i "customizations.yaml" 'spec.kubernetes.services.cray-hms-hmcollector.hmcollector_external_hostname' 'hmcollector.hmnlb.{{ network.dns.external }}'
   ```

1. (`ncn-m001#`) Update the `site-init` secret:

   ```bash
   kubectl delete secret -n loftsman site-init
   kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. (Optional) (`ncn-m001#`) Commit changes to `customizations.yaml`.

   `customizations.yaml` has been updated in this procedure. If using an external Git repository
   for managing customizations as recommended, then clone a local working tree and commit
   appropriate changes to `customizations.yaml`.

   For example:

   ```bash
   git clone <URL> site-init
   cd site-init
   kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   git add customizations.yaml
   git commit -m 'CSM 1.3 upgrade - customizations.yaml'
   git push
   ```

## Setup Nexus

(`ncn-m001#`) Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
cd "$CSM_DISTDIR"
./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on `stderr` and exit with status
code `0`. For example:

```console
./lib/setup-nexus.sh

[... output omitted ...]

+ Nexus setup complete
setup-nexus.sh: OK
echo $?
0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

## Upgrade CANU

CANU must be at version `1.7.1` or greater for this CSM patch release.
New features were delivered in [CANU 1.7.0](https://github.com/Cray-HPE/canu/releases/tag/1.7.0) and a critical bug fixed in [CANU 1.7.1](https://github.com/Cray-HPE/canu/releases/tag/1.7.1).

(`ncn-m001#`) Update CANU.

```bash
pdsh -b -S -w $(grep -oP 'ncn-[mw]\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'zypper install -y canu' && echo PASSED || echo FAILED
```

## Upgrade services

(`ncn-m001#`) Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR"
./upgrade.sh
```

## Update test suite packages

(`ncn-m001#`) Update select RPMs on the NCNs.

**NOTE:** The following message may be emitted after running the following `zypper` command. The message can be safely ignored.

```text
You may wish to restart these processes.
See 'man zypper' for information about the meaning of values in the above table.
No core libraries or services have been updated since the last system boot.
Reboot is probably not necessary.
```

```bash
pdsh -b -S -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') \
    'zypper install -y hpe-csm-goss-package csm-testing goss-servers && systemctl enable goss-servers && systemctl start goss-servers' \
    && echo PASSED || echo FAILED
```

## Verification

1. (`ncn-m001#`) Verify that the new CSM version is in the product catalog.

   Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.3.3`):

   ```text
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   1.0.1
   1.0.10
   1.2.0
   1.2.1
   1.2.2
   1.3.0
   1.3.1
   1.3.2
   1.3.3
   ```

1. (`ncn-m001#`) Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.3.3".configuration.import_date'
   ```

## Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
