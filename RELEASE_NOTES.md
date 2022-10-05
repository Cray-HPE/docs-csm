# Cray System Management (CSM) - Release Notes

CSM 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

* TBD

### Networking

* TBD

### Miscellaneous functionality

* Integrated Kyverno Native Policy Management engine
* Ansible has been added to NCNs
* Added support for the Replace/Remove/Add NCN procedures
* Integrated Argo Server workflow engine for Kubernetes
* Technology Preview: BOS V2 (Boot Orchestration) Asynchronous boot state handling and CRUS replacement for rolling upgrade
* Technology Preview: Tenant and Partition Management Service (TAPMS)
* Support for setting of Bios Settings through SCSD
* Ability to set power cap on multiple computes
* Included SAT CLI in CSM (see [SAT in CSM](operations/sat/sat_in_csm.md))

### New hardware support

* Olympus Antero Blade (AMD Genoa) with Slingshot 11
* Aruba JL705C, JL706C, JL707C management network switches

### Automation improvements

* TBD

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `16.6.29`      |
| `containerd`                 | `1.5.10`       |
| Istio                        | `1.10.6`       |
| Kubernetes                   | `1.21.12`      |
| Nexus                        | `3.38.0-1`     |
| Prometheus                   | `2.36.1`       |
| `oauth2-proxy`               | `7.3.0`        |
| `cray-opa`                   | `0.42.1`       |
| `cray-velero`                | `1.6.3-2`      |

### Security improvements

* Replaced High/Critical CVE container use in Spire
* Addressed CVE remediation for `postgres-operator`
* Addressed Expat-15: High/Critical CVE container use in UAS/UAI
* IPXE binary name randomization for added security
* Access allowed to heartbeat's tunables OPA for `cray-heartbeat`

### Customer-requested enhancements

* Added the ability to list all lock conditions with `cray hsm locks` API
* Enabled pressure stats on all nodes with Linux 5.x kernel

### Documentation enhancements

* Added documentation for:
  * Add/Remove/Replace NCN procedures
  * Add/Remove/Replace compute nodes using `sat swap blade`
  * How to troubleshoot `ncn-m001` PXE loop
  * NCN image modification using IMS and CFS
  * Minimal space requirements for CSM V1.3.0
  * The new `cray-externaldns-manager` service
* CAN documentation updated to reflect BICAN

## Bug fixes

* TBD

## Deprecations

The following features are now deprecated and will be removed from CSM in a future release.

* CAPMC v1 partial deprecation
* HSM v1 interface
* [BOS](glossary.md#boot-orchestration-service-bos) v1 is now deprecated, in favor of BOS v2. BOS v1 will be removed from CSM in the CSM-1.9 release.
  * It is likely that even prior to BOS v1 being removed from CSM, the [Cray CLI](glossary.md#cray-cli-cray) will change its behavior when no
    version is explicitly specified in BOS commands. Currently it defaults to BOS v1, but it may change to default to BOS v2 even before BOS v1
    is removed from CSM.

See [Deprecated features](introduction/differences.md#deprecated-features).

## Removals

* TBD

## Known issues

### Security vulnerability exceptions in CSM 1.4

* TBD
