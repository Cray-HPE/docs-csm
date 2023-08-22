# CSM 1.3.1 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.3.1` from `v1.3.0`.
If upgrading from CSM `v1.2.2` directly to `v1.3.1`, follow the procedures described in [Upgrade CSM](../README.md) instead.

## Bug fixes and improvements

* Update `cfs-operator` for fixed session memory limits.
* Fix HSN NIC numbering in SMD for devices managed by HPE `Proliant` iLO (Redfish).
* Restrict accessible Keycloak endpoints in OPA Policy. Require use of CMN LB for Keycloak master realm or admin.
* Fix Prometheus error with web hook for node exporter fix.
* Add support for collapsing session layers in CFS.
* Mitigate security issue for Kea regarding RFC 8357 support.
* Increase CoreDNS forwarding `max_concurrent` tuning to `10000`.
* Remove deprecated Kubernetes API use in `cray-dns-unbound`.
* Allow BOS `non-rootfs_providers` to specify `root=<values>` in parameters `sessiontemplates`.
* Mitigate Keycloak vulnerability `CVE-2020-10770` via OPA Policy (API `AuthZ`).
* Add a message key (`hms-collector`) to Kafka messages to ensure events are sent to the same Kafka partition. The message key is the BMC Xname concatenated with the Redfish Event Message ID. For example `x3000c0s11b4.EventLog.1.0.PowerStatusChange`.
* Update FAS actions test to only require at least one 'Ready' BMC.
* Add TPM configuration support in SCSD.
* Remove Hexane repo from RPM index.
* Move Spire `jwks` URL in `cray-opa` to ingress gateway.
* Fix unbound forward to PowerDNS does not working in an air-gapped configuration.
* Update `cfs-operator` to remove the high priority on pods.
* Add `cray-console-*` timeout to allow more time for post-upgrade hooks to complete.
* Increase `cray-dhcp-kea` timeout on readiness check to from default value.
* Fix stuck sessions during staged shutdown operations in BOS v2.
* Add 'retry' in IMS when fetching files from S3.
* Update documentation to run Ceph latency adjustment script during install and upgrade.
* Add documentation to remove private key from SLS `loadstate` and `dumpstate`.
* Add documentation and tooling for Ceph latency recovery.
* Add documentation to resolve issue with Unbound not forwarding to PowerDNS in air-gapped configurations.
* Add documentation to increase `fs.inotify.max_user_watches` on Kubernetes worker nodes in response to `kubectl logs -f` returning `no space` errors.

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade services](#upgrade-services)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. (`ncn-m001#`) Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.3.1` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   CSM_DISTDIR="$(pwd)/csm-1.3.1"
   echo "${CSM_DISTDIR}"
   ```

1. (`ncn-m001#`) Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

### Setup Nexus

(`ncn-m001#`) Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
cd "$CSM_DISTDIR"
./lib/setup-nexus.sh ; echo "RC=$?"
```

On success, `setup-nexus.sh` will output `OK` on `stderr` and exit with status
code `0`. For example:

```text
+ Nexus setup complete
setup-nexus.sh: OK
RC=0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

### Upgrade services

(`ncn-m001#`) Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR"
./upgrade.sh
```

### Update test suite packages

(`ncn-m001#`) Update the `csm-testing` and `goss-servers` RPMs on the NCNs.

```bash
pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'zypper install -y csm-testing goss-servers'
```

### Verification

1. Verify that the new CSM version is in the product catalog.

   (`ncn-m001#`) Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.3.1`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.3.1".configuration.import_date'
   ```

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
