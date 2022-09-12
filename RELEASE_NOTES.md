# Cray System Management (CSM) - Release Notes

CSM 1.3 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

* Temperature hardware monitoring dashboard for NCNs
* Support for export of SNMP data from multiple switches for population of SNMP Export `grafana` panel
* Space monitoring improvements - included volumes other than root file system

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
* Ability to set power cap on n number of computes
* Included SAT CLI in CSM (see [SAT in CSM](operations/sat/sat_in_csm.md))

### New hardware support

* Olympus Antero Blade (AMD Genoa) with Slingshot 11
* Aruba JL705C, JL706C, JL707C management network switches

### Automation improvements

* Support for Argo-driven upgrade of multiple Kubernetes Worker NCNs in parallel, using `cray-nls` (Tech Preview)
* Support for Argo-driven upgrade of Storage NCNs, serially, using `cray-nls` (Tech Preview)
* Ceph upgrade is now driven using a utility called the  `cubs_tool`.
* Re-organization of `goss` test execution during installs and upgrades to remove duplicated tests
* Improvement of `goss` test suite output to display summary of failing tests
* Removed manual prompts from upgrade of storage NCNs
* Introduced weekly spire-intermediate cron-job to check CA to see when it needs automatic renewal

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `16.2.9`       |
| `containerd`                 | `1.5.12`       |
| `coredns`                    | `1.8.0`        |
| `cray-dhcp-kea`              | `0.10.15`      |
| `cray-ipxe`                  | `1.11.0`       |
| Istio                        | `1.10.6`       |
| Kubernetes                   | `1.21.12`      |
| Kiali                        | `1.36.7`       |
| Nexus                        | `3.38.0-1`     |
| `podman`                     | `3.4.4`        |
| `postgreSQL`                 | `12.12`        |
| Prometheus                   | `2.36.1`       |
| `oauth2-proxy`               | `7.3.0`        |
| `cray-opa`                   | `0.42.1`       |
| `cray-velero`                | `1.6.3-2`      |

### Security improvements

* Boot Security - Randomized iPXE File Name
* Boot Security - NCN boots via pre-signed S3 URLs
* API least privileges (xname filtering)
* Role Based Access Control (RBAC) Role for monitoring
* Kubernetes Pod Runtime Security – Phase 1 (non-root)
* Kubernetes API (etcd) Encryption (opt-in)
* Tenant and Partition Management Service (TAPMS Tech Preview)
* Access allowed to heartbeat's tunables OPA for `cray-heartbeat`
* NCN CVE Remediation
* CVE remediation near zero - high/critical (container images)
* Replaced High/Critical CVE container use in Spire
* Addressed CVE remediation for `postgres-operator`
* Addressed Expat-15: High/Critical CVE container use in UAS/UAI

### Customer-requested enhancements

* Added the ability to list all lock conditions with `cray hsm locks` API
* Enabled pressure stats on all nodes with Linux 5.x kernel
* Added initial (Tech Preview) support for API-driven NCN lifecycle operations driven via Argo workflows (for worker and storage NCN upgrades)

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

* CAPMC v1 partial deprecation
* HSM v1 interface

See [Deprecated features](introduction/differences.md#deprecated-features).

## Removals

* TBD

## Known issues

### Security vulnerability exceptions in CSM 1.3

Significant effort went into the tracking, elimination, and/or reduction of critical or high (and lower) security vulnerabilities of container images included in the CSM 1.3 release.
There remain, however, a small number of exceptions that are listed below. General reasons for carrying exceptions include needing to version pin certain core components,
upstream fixes not being available, or new vulnerability detection or fixes occurring after release content is frozen. A new effort to track and address security vulnerabilities
of container images spins up with each major CSM release.

| Image | Reason |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `csm-dckr/stable/quay.io/ceph/ceph:v15.2.15`                                | This version of Ceph (Octopus) is needed in the upgrade procedure, but is not present after that. |
| `csm-docker/stable/quay.io/ceph/ceph:v15.2.16`                              | This version of Ceph (Octopus) is needed in the upgrade procedure, but is not present after that. |
| `csm-docker/stable/quay.io/ceph/ceph:v16.2.9`                               | This version of Ceph (Pacific) is pinned for the CSM 1.3 release.  The next CSM version released as a part of a recipe will support Ceph (`Quincy`). |
| `csm-docker/stable/quay.io/cephcsi/cephcsi:v3.6.2`                          | Upstream fixes became available after CSM 1.3 release content was frozen. |
| `csm-dckr/stable/dckr.io/bitnami/external-dns:0.10.2-debian-10-r23`         | Upstream fixes are needed and are not yet available. |
| `csm-docker/stable/quay.io/kiali/kiali-operator:v1.36.7`                    | The updated `RedHat` base image is available but not pulled in by upstream.  See procedure to [Remove Kiali](operations/system_management_health/Remove_Kiali.md) if desired. |
| `csm-dckr/stable/k8s.gcr.io/kube-proxy:v1.20.13`                            | This version is needed for the upgrade procedure but will not be running after the upgrade has been completed. |
| `csm-docker/stable/k8s.gcr.io/kube-proxy:v1.21.12`                          | Upstream fixes are needed and are not yet available for the `1.21.12` version of Kubernetes included in CSM 1.3. |
| `csm-docker/stable/cray-postgres-db-backup:0.2.3`                           | To ensure success of postgres restore functionality, we needed to pin to psql v12 in this image |
| `csm-dckr/stable/dckr.io/nfvpe/multus:v3.7`                                 | Upstream fixes are needed and are not yet available, however we have engaged with the project to make a reduced-vulnerability version available.|
| `csm-docker/stable/docker.io/sonatype/nexus3:3.38.0-1`                      | Upstream fixes are needed to the base image in order to address the remaining vulnerabilities. |
| `csm-docker/stable/cray-uas-mgr:1.21.0`                                     | This will be addressed in a future version of CSM. |
