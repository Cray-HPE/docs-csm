# Cray System Management (CSM) 1.7.1 Release Notes

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.7 release notes page, including links to other patch release notes,
see [CSM 1.7 release notes](RELEASE_NOTES.md).

* [CSM 1.7.1 patch releases](#csm-171-patch-releases)
* [Additions and improvements](#additions-and-improvements)
* [Customer-requested](#customer-requested)
* [Bug fixes](#bug-fixes)
* [Known issues](#known-issues)
* [All resolved issues](#all-resolved-issues)
    * [IUF](#iuf)
    * [iSCSI SBPS](#iscsi-sbps)
    * [Rack Resiliency](#rack-resiliency)
    * [CASM](#casm)
    * [CASMCMS](#casmcms)
    * [CASMDIAG](#casmdiag)
    * [CASMHMS](#casmhms)
    * [CASMINST](#casminst)
    * [CASMMON](#casmmon)
    * [CASMNET](#casmnet)
    * [CASMPET](#casmpet)
    * [CASMSEC](#casmsec)
    * [CASMSMF](#casmsmf)
    * [CASMTRIAGE](#casmtriage)
    * [DOCS](#docs)
    * [CRAYSAT](#craysat)
    * [MTL](#mtl)

## CSM 1.7.1 patch releases

This is the release notes page for CSM 1.7.1. Each patch for CSM 1.7.1 has its own release notes, detailing what
changes it includes.

* [CSM 1.7.1-patch.1 Release Notes](RELEASE_NOTES_1.7.1-patch.1.md)

## Additions and improvements

* Updated `ims-python-helper` to support logging level configuration as part of IMS configuration for image create/build
* IMS jobs run on remote build nodes have performance improvements and can better recover from errors regarding the remote execution.
* IUF supports deletion of activities.

### General

* Updated SLES base OS to SLES 15 SP7.
* Added a procedure to [Enable Rack Resiliency on running system](operations/rack_resiliency/Enabling_RR_on_running_system.md).
* Refactored Rack Resiliency workflows to use native Ansible execution with centralized fact management for zone prefixes and Kubernetes label application via `kubernetes.core.k8s` module.

### Security

* Updated several HMS services to point to latest upstream image and Go module dependencies.
* Upgrade `metacontroller` container image from `v4.10.3` to `v4.11.25`
* Many SLES security vulnerabilities remediated
* Addressed Kyverno deployment and policy enforcement issues, including version alignment in platform
  manifests, webhook timeout handling, and baseline policy violations in IUF automation tests.
* Remediated KEVs and CVEs across platform components (`cray-sts`, IMS kiwi-ng builder, CFS operator,
  `argoexec`, `kubectl`, product-deletion-utility), updated Kata for security fixes, and addressed kernel `CVE-2025-38083`.

### Tests

* Fixed several issues in HMS services that resulted in false positives when CT tests were run.
* Many improvements were made to automated SAT functional tests included in the `csm-testing` RPM.
  This includes the following:
    * Created additional functional tests for `sat status`, `sat bootprep`, and `sat hwinv`
    * Split `sat bootprep` tests into separate test cases that can run in parallel
    * Added cleanup of deleted images and completed IMS jobs created by `sat bootprep` tests
    * Added dynamic generation of SAT Goss tests
    * Fixed bugs and improved resiliency of tests for `sat version`, `sat nid2xname`, `sat
      firmware`, and `sat bootprep`
    * Extended timeout to 30m for SAT functional tests
* Added comprehensive automated testing improvements for CMS:
    * Added new `cmsdev` testing options and CRUD tests for CFS and BOS services
    * Added `multitenancy` BOS CRUD tests to `cmsdev`
    * Added `multitenancy` CFS CRUD tests to `cmsdev`
    * Added read-only `multitenancy` CFS tests to `cmsdev`
    * Added CFS Sessions Race Condition Test to validate concurrent session handling. See [CFS Sessions Race Condition Test](troubleshooting/cfs_sessions_race_condition_test.md)
* Added timeouts for `cli` commands and API calls in `cmsdev`
* Updated `cmsdev` to put logs and artifacts in separate timestamped directories. See [Logging](troubleshooting/known_issues/sms_health_check.md#logging)
* Updated `cmsdev` to not run CFS and BOS tenant tests by default; added `--include-tenant` flag to include them.
* Updated `cmsdev` to not run CLI commands by default; added `--include-cli` flag to include them
* Fixed `cmsdev` BOS test failure to properly capture artifacts
* Fixed `cmsdev` to retry `503s` a limited number of times
* Fixed `cmsdev` to avoid skipped CFS tests due to product catalog failure
* Fixed `cmsdev` to avoid repeated product catalog lookup
* Fixed `cmsdev` TFTP test that could report false errors
* Fixed `cmsdev` to correctly report pods as Running that are in CLBO status
* Updated tests to log a warning instead of failure if a pod is in `Succeeded` state
* Added Goss tests for Rack Resiliency
* Added CI Unit test cases for [Resiliency Monitoring Service](operations/rack_resiliency/Resiliency_Monitoring_Service.md)

## Customer-requested

* Updated the `sat bmccreds` command to log a warning and prompt whether the user wants to continue
  if the provided password is longer than 20 characters. This is the maximum password length
  supported by `ipmitool`, which is required to control management nodes during system boot and
  shutdown procedures.
* Enhanced the CSM Upgrade documentation to describe the procedures done during CSM Upgrade through IUF hooks.

## Bug fixes

* After upgrading to Kubernetes 1.32 in CSM 1.7.0, some Pod Security Policy (PSP) Role Bindings and Service Accounts still exist.

  Since PSP is not supported in Kubernetes 1.25+, these unneeded Role Bindings and Service Accounts are removed after Kubernetes
  is upgraded to 1.32.
* Fixed a bug in SMD where HTTP code 400 was returned if a GET on the lock status API found no matching components.  HTTP code 200 is now returned along with an empty list.
* Fixed a bug in CAPMC where power requests would fail if too many xnames were specified.
* Enhanced management of `iptables` rules for TFTP traffic
* Fixed a bug in `sat hwinv` that caused values in multi-value fields to be printed in a
  non-deterministic order. Such fields are now always printed in sorted order.
* Fixed a bug in `sat bootsys` that resulted in an `AttributeError` exception when the `known_hosts`
  file contains invalid lines with the incorrect number of fields.
* Fixed `sat bootprep` to no longer perform its own resolution of branch names to commit hashes when
  creating CFS configurations with CFS v3. This allows the use of external repositories with branch
  names for CFS configurations created by `sat bootprep`.
* Resolved multiple CFS stability issues: no-op handling in bulk patch, race conditions that caused
  failures or invalid data, log level updates, and prevention of jobs starting for deleted sessions.
* Addressed BOS and IMS defects including fatal HSM error reporting, excess BOS session templates
  from test runs, IMS remote build port cleanup, and improved IMS logging level configuration and
  product catalog usage.
* Fixed CFS session handling when IMS job containers are killed and improved remote node teardown
  space usage.
* Resolved monitoring and diagnostics issues such as Victoria Metrics agent scraping of `istio-proxy`
  sidecars and unintended `cray-console-node` SSH attempts to NCNs on vShasta.
* Corrected Rack Resiliency automation playbooks that were disruptive, restarted wrong deployments,
  overwrote Kyverno policy, or assumed `kubectl` on storage nodes.
* Fixed Rack Resiliency Ceph HAProxy script to properly handle config generation, backups, and conditional restarts, improving idempotency and ease of debugging.
* Victoria metrics can now be collected for BOS and CFS database pods.

## Known issues

* In multi-tenant configurations leveraging Slingshot networking as described in the "HPE Slingshot Network Operator for CSM Multi-Tenancy"
  section of the HPE Slingshot Administration Guide, the iSCSI protocol cannot be routed over the High-Speed Network (HSN). While compute
  nodes remain in the same HSN subnet, they are assigned to a different VLAN than Non-Compute Nodes (NCNs). This VLAN isolation prevents
  compute nodes from accessing iSCSI services hosted on NCNs via the HSN.

  Compute nodes must be configured to use iSCSI over the Node Management Network (NMN) to successfully boot and to prevent iSCSI access
  issues when running nodes are moved into tenant-specific VLANs.

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

## All resolved issues

### IUF

```text
CASM-4543 docs-csm rpm installation now updates tags and uploads workflow templates to Argo.
CASM-5756 CAST-38483 DOCS: How to identify old Nexus repositories for cleanup during upgrades.
The documentation now includes steps to retrieve a list of older Nexus repositories that are safe candidates for deletion, so administrators can free space and resume the upgrade if Nexus storage becomes full.
CASM-5744 CAST-38982 Upgrade fix: prevent the legacy cos-prechecks-for-worker-reboots hook from running during CSM 1.7.x upgrades
CASMINST-6636 IUF CLI enhancement: display the log file name on failures
When an IUF command fails, the iuf CLI now prints the relevant log file name, making it easier to locate detailed error output and troubleshoot the failure.
CASMINST-7090 IUF now supports deletion of activities.
CASMTRIAGE-8916/CASMTRIAGE-8917 DOCS: Corrected Cilium migration guidance to prevent unintended migration and node isolation
Note: This Cilium migration guidance is applicable to upgrades from CSM 1.6 → 1.7, and is not intended for 1.7.0 → 1.7.1 in-place upgrades.
CASMTRIAGE-8843/CASMTRIAGE-6297 DOCS: Added documentation for resolving merge conflicts during iuf update-vcs-config.
CASMTRIAGE-8729 DOCS: Reboot Managed nodes after updating managed host Slingshot NIC firmware, ensuring the firmware update is fully applied.
CASMTRIAGE-8606 CAST-38666 DOCS: IUF management-rollout behavior is dependent on the current state of the node and does not re-run those backup steps on subsequent runs.
CASMTRIAGE-8605 CAST-38666 DOCS: IUF preserves local customizations in /etc/motd and /root/.bashrc during management-rollout on ncn-m001.
CASMTRIAGE-8604 DOCS: Mitigate disk-pressure during IUF worker rolling upgrades when /var/lib/containerd is highly utilized.
CASMTRIAGE-8584 DOCS: Enhanced the CSM upgrade documentation to better describe the actions performed during upgrade by IUF hooks.
CASMTRIAGE-8863 DOCS: Added Kubernetes upgrade time estimates after IUF deploy-product.
MTL-2572 DOCS: Moved the kernel-parameter update into the NCN rebuild workflow step where kernel/initramfs/rootfs are updated immediately before reboot.
CAST-38971 DOCS: Restored IUF troubleshooting documentation for "iuf_unable_to_run_next_stage.md".
```

### iSCSI SBPS

```text
CASMTRIAGE-7844 DOCS: Missing files remain inaccessible when bringing iscsi targets back online
CASMTRIAGE-8523 DOCS: Investigate why iSCSI client is consuming a lot of memory
CASMTRIAGE-8834 DOCS: Provide documenation to remove iSCSI sessions for the nodes not part of  HSM group for iSCSI
CASMTRIAGE-8835 DOCS: Document about necessary action if the compute/UANs are booted with DVS during upgrade from 1.6.x to 1.7.x
CASMTRIAGE-8848 SQUASHFS error occurred for booted computes while worker nodes were rebuilt
CASMTRIAGE-8912 DOCS: CA for CAST-39136 for cleanup of unused Luns
CASMTRIAGE-8984 After worker node 1 rollout, its path is not active in compute node
CASMTRIAGE-8999 Recurrence of LUN assigments messages seen in compute node
CASMPET-7500 DOCS: Update iSCSI SBPS top level document with latest flow diagram
```

### Rack Resiliency

```text
CASM-5717 DOCS: Document lack of RR support for some dynamic NCN changes
CASM-5705 DOCS: Need to document (@csm-docs) steps on enabling Rack Resiliency post install/ upgrade
CASM-5662/CASM-5649 RR CFS Ansible plays: Fixes for RR Ansible plays and improvements to use Ansible modules
CASM-5644 TESTS: Add more unit tests for RRS/RMS
CASM-5643 TESTS: Add bad path unit tests for RRS/RMS
CASMINST-7369 TESTS: Create RRS/RMS health checks in csm-testing
CASMTRIAGE-8975 BUG: Issue faced while rebuilding cray-rrs images/charts
CASMTRIAGE-8945 RR cfs issues for master nodes
CASMTRIAGE-8926 Wrong file name for RR goss-test
CASMTRIAGE-8730 DOCS: Rack Resiliency logic in CSM 1.6 to 1.7 upgrades
CASMTRIAGE-8450 DOCS: Rack-Resiliency : RMS is not picking up node being moved from one rack to another
```

### CASM

```text
CASM-5716 CASTS fixes in CSM 1.7.1 release for MON
CASM-5715 CSM 1.7.1 release activities for SMA
CASM-5714 Support for SLES15-SP7 for MON
CASM-5686 Bugs in rack_to_node_mapping.py in csm-config
CASM-5683 As a developer, I need to make Kyverno policy as part of RRS helm chart
CASM-5681 RR storage play assumes kubectl configured on all storage nodes
CASM-5679 RR playbook disruptive to system
CASM-5678 RR playbook restarts wrong deployments
CASM-5677 RR playbook always overwrites Kyverno policy
CASM-5676 RR playbook needlessly restarts deployments
CASM-5670 kernel CVE-2025-38083 for SLES 15 SP6 / SP7
CASM-5669 Modify csm-supplemental to handle different target repos
CASM-5662 RR Ansible Playbook should make better use of Ansible
CASM-5624 HMS: Specific Scaling Improvements for CSM 1.7.1
CASM-5617 MTLNET: CAST and CVE-related Bugs
CASM-5367 SLE-15-SP7 CSM Images
```

### CASMCMS

```text
CASMCMS-9613 Auto-rebuild forced upgrade of Kiwi-NG to new version that broke recipe builds.
CASMCMS-9610 CFS: Bulk patch operation causes Exception and fails
CASMCMS-9605 cfs race condition test fails if using the default cfs session name
CASMCMS-9599 Update cfs-operator Redis version to match CFS
CASMCMS-9598 Fix bug in how CFS bulk patch handles no-op patches
CASMCMS-9596 Python module 'testtools' has released a new version that breaks our unit tests.
CASMCMS-9595 TESTS: cmsdev: Put existing logs and artifacts in separate timestamped directories
CASMCMS-9594 TESTS: cmsdev should not run cfs and bos tenant tests by default
CASMCMS-9593 BOS: session error field not updated for fatal HSM error
CASMCMS-9592 Dev Tests - 12 new bos session templates are created with each test run
CASMCMS-9575 TESTS: cmsdev: Put logs and artifacts in separate timestamped directories
CASMCMS-9574 Update Kata version to get security updates.
CASMCMS-9571 CFS server does not properly update log level when changed
CASMCMS-9567 cfs-operator starts Kubernetes jobs for deleted CFS sessions
CASMCMS-9565 Increase timeout in BOS automated test
CASMCMS-9560 IMS remote build - port not released when job is complete
CASMCMS-9544 TESTS: CFS: Sessions: Create race condition tests
CASMCMS-9542 Update IMS related config to support SLES 15 SP7
CASMCMS-9539 TESTS: cmsdev: Dont run CLI command bydefault, Add --include-cli flag to inlcude them
CASMCMS-9538 CFS: Race condition causes requests to fail or return invalid data
CASMCMS-9537 TESTS: cmsdev: Misleading error message in BOS and CFS tests
CASMCMS-9534 TESTS: cmsdev: Correctly format kernel parameters for BOS tests
CASMCMS-9532 TESTS: cmsdev: Avoid skipped CFS tests due to product catalog failure
CASMCMS-9531 TESTS: cmsdev: Avoid repeated product catalog lookup
CASMCMS-9530 TESTS: cmsdev: BOS test failure did not capture usual artifacts
CASMCMS-9529 TESTS: cmsdev: TFTP test can report false error
CASMCMS-9523 Tests: Log a warning instead of failure if a pod is in `Succeeded` state
CASMCMS-9518 TESTS: cmsdev: Retry 503s limited number of times
CASMCMS-9515 cfs session for image customization running on remote node is stuck in "running" status if ims job container is killed
CASMCMS-9512 csm.ssh_keys role problems when no root credentials in Vault
CASMCMS-9510 ims-python-helper: Change logging level configuration as part of ims configuration
CASMCMS-9508 Use updated product catalog Python library
CASMCMS-9472 TESTS: Add multitenancy BOS CRUD tests to cmsdev
CASMCMS-9471 TESTS: Add multitenancy CFS CRUD tests to cmsdev
CASMCMS-9470 TESTS: Add read-only multitenancy CFS tests to cmsdev
CASMCMS-9446 Victoria Metrics agent can't gather metrics from the istio-proxy sidecar
CASMCMS-9281 Investigate cray-console-node trying to ssh to NCNs on vShasta
CASMCMS-8904 OPTIMIZATION: use less space on remote node and teardown a little faster
CASMCMS-8777 TESTS: cmsdev reports pods as Running that are in CLBO
CASMCMS-8550 TESTS: cmsdev: Add timeouts for commands and API calls
```

### CASMDIAG

```text
CASMDIAG-1745 HTT: Add Key Info to triage_output.json
CASMDIAG-1744 diags 1.7.10 build is looking for SP6 zypper repos instead of SP7
CASMDIAG-1743 diags install failing during deliver-product stage due to slurm related issues
CASMDIAG-1739 The cwhpcc diagnostic is failing on Loki system's Windom and Antero nodes
CASMDIAG-1738 Add new supported arguments for linpack
CASMDIAG-1737 Filter the supported stages for triaging
CASMDIAG-1736 CVT container failing with dependencies
CASMDIAG-1735 Showing msg "No non-tenant nodes are authenticated or No non-tenant nodes are passed" even though non-tenant nodes are authenticated
CASMDIAG-1731 Reorder to check if h/w type is supported first
CASMDIAG-1728 HTT: EarlyPowerGoodFailure for EX425 throws an error that it cannot find powerrail_EX425.yml
CASMDIAG-1717 Windom- linpack failing with one hsn connection
CASMDIAG-1716 create the release branch for csm diags, for csm-1.7.1
CASMDIAG-1713 Update base containers in csm diags (badger,cvt,fox)
```

### CASMHMS

```text
CASMHMS-6622 Resolve raised HMCOLLECTOR dependabot PR
CASMHMS-6614 BSS: Update go.mod to point to latest SMD
CASMHMS-6612 Update hms-redfish-translation-layer to use Alpine v3.22
CASMHMS-6611 Update hms-meds to use Alpine v3.22
CASMHMS-6610 Update hms-hmcollector to use Alpine v3.22
CASMHMS-6609 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-sls-pprof:2.12.0
CASMHMS-6605 HMS CT tests fail to start after a rebuild (part 4)
CASMHMS-6603 CAST-38912: ARCHER2 TDS unexpected Subtype key for m001 in HSM
CASMHMS-6602 HMS CT tests fail to start after a rebuild (part 3)
CASMHMS-6600 ZDU request for new HSM role/subrole
CASMHMS-6599 HMS CT tests fail to start after a rebuild (part 2)
CASMHMS-6596 HMS SMD CT tests fail to start after a rebuild (part 1)
CASMHMS-6586 CAST-38630: Test - /opt/cray/csm/scripts/hms_verification/run_hms_ct_tests.sh -t hsm - FAILS
CASMHMS-6572 Investigate duplicates docker.io/library/redis: HMS-RTS / BOS
CASMHMS-6570 CAST-38372: CAPMC request to PCS is too large
CASMHMS-6551 Update HMS services to use Alpine v3.22 base image in CSM 1.7.1
CASMHMS-6423 MEDS: Buggy implementation of watching for HSM changes
CASMHMS-6374 BSS: Convert from go-yaml/yaml to goccy/go-yaml
CASMHMS-6323 hms-msgbus: Nonblocking writes to kafka bus must drain events
CASMHMS-6316 PCS: Reuse status TRS client for transition and power cap operations
CASMHMS-6315 TRS: Move response body processing into TRS
CASMHMS-6290 PCS: Shard component status requests to BMCs across all PCS pods
CASMHMS-6138 verify_hsm_discover.py issues
```

### CASMINST

```text
CASMINST-7460 Precaching of cray-dns-unbound fails during 1.6.3 > 1.7 upgrade
CASMINST-7459 SP7: cray-sls-init-load job fails during fresh install
CASMINST-7458 SP7: secrets-seed-customizations.sh fails at platform_ca
CASMINST-7445 Include IPv6 neighbor table in ARP cache tuning guidance
CASMINST-7433 CMN ip6 entry present in every ipam entry in cloud-init
CASMINST-6937 identify low-hanging fruit from P0's in Automation Scope for CSM
CASMINST-6462 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/metacontrollerio/metacontroller:v4.10.3
CASMINST-6253 Suggestion to include remediation step for libcsm
CASMINST-5980 Create/update tool to customize NCN timezones
CASMINST-3863 bios-baseline.sh script passes BMC passwords on the command line
```

### CASMMON

```text
CASMMON-562 SwitchPortDown alert for sw-spine-001 with NA for EventType and Text description
CASMMON-560 wasp: cray-sysmgmt-health-redfish-exporter pod in CLBO
CASMMON-557 node-exporter pod trigger alert NodeTextFileCollectorScrapeErr
CASMMON-556 Logging Enhancement for Redfish Exporter
CASMMON-555 Validate csm cray-sysmgmt-health in SLES15SP7
CASMMON-554 Kafka and Namespaces dashboard bug fix
CASMMON-550 metallb-speaker alert should not be firing for master nodes
```

### CASMNET

```text
CASMNET-2366 cray-dns-unbound-manager should not remove records if Kea response is empty
CASMNET-2315 csi config init generates invalid EX2500 configuration if vlans are not set
CASMNET-2313 Tenant - need documentation for Compute-to-NCN connectivity
CASMNET-2295 Filter CSM DNS traffic from customer DNS
CASMNET-2256 Replace pyinstaller with a virtualenv
CASMNET-2255 Migrate Ansible into virtualenv
CASMNET-2252 Support pcie-slot1+
CASMNET-2247 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/cilium/json-mock:v1.3.8
CASMNET-2183 CANU: Support Storage nodes for LANL mgmt network.
CASMNET-2120 Fix CVE's in artifactory.algol60.net/csm-docker/stable/ghcr.io/k8snetworkplumbingwg/multus-cni:v3.9.3
CASMNET-2118 FEATURE: Evaluate PowerDNS LMDB + Lightning Stream
CASMNET-2075 FEATURE: cray-dns-powerdns is a single point of failure
CASMNET-1998 Unbound forwarding queries to site DNS unnecessarily
CASMNET-1891 BREAK/FIX: Deleting a record from SLS does not delete it from PowerDNS
```

### CASMPET

```text
CASMPET-7711 Need to update crds for cray-postgres-operator
CASMPET-7694 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-bss-ipxe:1.16.1
CASMPET-7692 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/external-dns:0.17.0
CASMPET-7690 Victoria Metrics agent can't gather metrics from the istio-proxy sidecar in bitnami-etcd pods
CASMPET-7673 cray-vault: Do not create PSP rolebindings if capability does not exist
CASMPET-7672 tpm-intermediate: Do not create PSP rolebindings if capability does not exist
CASMPET-7671 cray-spire: Do not create PSP rolebindings if capability does not exist
CASMPET-7670 tpm-provisioner: Do not create PSP rolebindings if capability does not exist
CASMPET-7669 cray-postgres-operator: Do not create PSP rolebindings if capability does not exist
CASMPET-7668 node-discovery: Do not create PSP rolebindings if capability does not exist
CASMPET-7667 console-operator: Do not create PSP rolebindings if capability does not exist
CASMPET-7666 cray-drydock: Do not create PSP rolebindings if capability does not exist
CASMPET-7660 csm-config: Make sbps_dns_srv_records.sh more verbose
CASMPET-7637 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/istio/kubectl:1.5.4
CASMPET-7636 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/strimzi/kafka-bridge:0.28.0
CASMPET-7634 Fix CVEs in artifactory.algol60.net/csm-docker/stable/product-deletion-utility:1.0.1
CASMPET-7600 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/cephcsi/cephcsi:v3.14.0
CASMPET-7576 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/strimzi/kafka:0.45.0-kafka-3.9.0
CASMPET-7575 Cleanup leftover PSP RoleBindings
CASMPET-7548 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/etcd:3.5.21-debian-12-r1
CASMPET-7547 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/library/bitnami/kubectl:1.32
CASMPET-7534 Document procedure to add/remove worker nodes from iscsi projection
CASMPET-7485 Create a script that will generate the <manifest>-v1.24.yaml files
CASMPET-7480 Fix CVE's in artifactory.algol60.net/csm-docker/stable/registry.opensource.zalan.do/acid/logical-backup:v1.10.1
CASMPET-7478 Fix CVE's in artifactory.algol60.net/csm-docker/stable/ghcr.io/zalando/spilo-15:3.0-p1
CASMPET-7477 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/external-dns:0.15.0
CASMPET-7417 Race condition in kubernetes-cloudinit.sh:add_kata_configuration
CASMPET-7404 Investigate duplicates quay.io/prometheus/prometheus
CASMPET-7402 Investigate duplicates docker.io/library/alpine
CASMPET-7401 Investigate duplicates docker.io/curlimages/curl
CASMPET-7216 Fix CVEs in artifactory.algol60.net/csm-docker/stable/registry.opensource.zalan.do/acid/logical-backup:v1.8.2
CASMPET-7215 Fix CVEs in artifactory.algol60.net/csm-docker/stable/registry.k8s.io/kube-proxy:v1.24.17
CASMPET-7151 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/strimzi/operator:0.45.0
CASMPET-7150 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/strimzi/kafka-bridge:0.31.1
CASMPET-7149 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/strimzi/kafka:0.41.0-noJSM-chainsaw-kafka-3.7.0
CASMPET-7100 Fix CVE's in artifactory.algol60.net/csm-docker/stable/registry.opensource.zalan.do/acid/spilo-14:2.1-p7
CASMPET-7030 Investigate duplicates docker.io/demisto/boto3py3
CASMPET-6895 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/os-shell:11-debian-11-r90
CASMPET-6894 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/etcd:3.5.9-debian-11-r148
CASMPET-6674 Tenancy: Tenant CR status will not show updated public keys
CASMPET-6108 tapms: yaml file having duplicate xname succeeded
```

### CASMSEC

```text
CASMSEC-600 Change cray-kyverno version in platform-1.24.yaml to be in sync with platform.yaml
CASMSEC-599 Webhook timeout during cray-kyverno deployment
CASMSEC-596 Fix Known Exploited Vulnerabilities (KEVs) in cray-sts:0.8.3
CASMSEC-595 Fix Known Exploited Vulnerabilities (KEVs) in cray-ims-kiwi-ng-opensuse-x86_64-builder:1.11.1
CASMSEC-593 Fix Known Exploited Vulnerabilities (KEVs) in cray-cfs-operator:1.34.1
CASMSEC-591 Fix Known Exploited Vulnerabilities (KEVs) in argoexec:v3.3.6
CASMSEC-586 IUF automation test cases failed due to kyverno baseline policy violation
CASMSEC-570 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/kubectl:1.33.1
```

### CASMSMF

```text
CASMSMF-8679 Investigate CVE for SMA MLflow
```

### CASMTRIAGE

```text
CASMTRIAGE-8953 Prepare images error
CASMTRIAGE-8932 starlord: cray-kyverno helm chart/manifest mismatch
CASMTRIAGE-8900 CANU validate shcd cabling and paddle cabling are failing
CASMTRIAGE-8892 ncn-s001 rollout error
CASMTRIAGE-8890 tyr: SMD giving inappropriate 400 bad request response
CASMTRIAGE-8859 Image customization error
CASMTRIAGE-8815 starlord: ssh access test over can network, should not succeed, but is.
CASMTRIAGE-8696 autotriage: 16 failures in CSM-1.7.0, CSM-1.7.0-rc.7 detected on: tyr
CASMTRIAGE-8684 cray-nexus deployment fails on nexus-set-admin-password post-install hook
CASMTRIAGE-8678 uas etcd endpoints not getting cleared as part of upgrade
CASMTRIAGE-8675 autotriage: 1 failures in CSM-1.7.0-rc.7 detected on: vinland
CASMTRIAGE-8670 cray-nexus deployment fails on nexus-setup post-install hook - default admin credential not changed (again)
CASMTRIAGE-8638 RR k8s zone prefix is not getting applied correctly
CASMTRIAGE-8622 cray-nexus deployment fails on nexus-setup post-install hook - default admin credential not changed
CASMTRIAGE-8592 pre-install-check stuck waiting for keycloak pod to come up
CASMTRIAGE-8568 Cleanup of remote resource does not work on irregular exit during customization of the image
CASMTRIAGE-8389 Docs:SBPS provision_iscsi_server.sh breaks when hsn0 has more than one IP address
CASMTRIAGE-8324 autotriage: 1 failures in CSM-1.6.2 detected on: vidar
CASMTRIAGE-8311 canu report network firmware has stale data after HFP update
CASMTRIAGE-8305 autotriage: 2 failures in CSM-1.6.1-rc.7 detected on: vinland
CASMTRIAGE-7979 CSM 1.6 documentation has "servers" instead of "nodes" in many topics
CASMTRIAGE-7598 Docs:  provide instructions on how to have iSCSI scan for new images
```

### CRAYSAT

```text
CRAYSAT-2044 Update SAT functional tests for "sat bootprep" to gracefully handle None configurations from CFS
CRAYSAT-2043 sat bootprep image customization functional tests time out on vshasta upgrade test (vex)
CRAYSAT-2040 Improve resiliency of "sat firmware" functional tests
CRAYSAT-2039 Invalid logic in TestNid2Xname.test_xname2nid_format_range
CRAYSAT-2038 SAT automated tests should clean up IMS jobs
CRAYSAT-2037 Extend timeout for vshasta tests
CRAYSAT-2035 Clean up deleted IMS images overwritten by bootprep tests
CRAYSAT-2034 SAT automated test failure:  test_if_exists_images fails on wasp/fanta
CRAYSAT-2032 'NoneType' object has no attribute 'hostnames' from get_ssh_client
CRAYSAT-2029 Fix nid2xname functional test failure happening on tyr
CRAYSAT-2027 Add "sat bootprep" tests for resolve-branches behavior
CRAYSAT-2026 sat hwinv summaries display values in non-deterministic order
CRAYSAT-2024 Improve resiliency of sat_functional.version.test_version test
CRAYSAT-2022 Automatically generate Goss tests from SAT functional tests in Python classes
CRAYSAT-2013 Create functional tests for "sat hwinv" in csm-testing (summarize options)
CRAYSAT-2009 Add more "sat bootprep" tests to exercise "--cfs-version v2"
CRAYSAT-2008 Speed up "sat bootprep" tests by creating resources with cray CLI
CRAYSAT-2007 Improve VCS repo setup and cleanup code in "sat bootprep" tests
CRAYSAT-2006 Add testing of "image_ref" and "ref_name" fields in "sat bootprep" functional tests
CRAYSAT-2001 Remove branch resolution from "sat bootprep" for CFS v3
CRAYSAT-1989 Create more functional tests for source in "sat bootprep"
CRAYSAT-1968 Create functional tests for "sat status --format" in csm-testing
CRAYSAT-1963 Ensure SAT functional tests are run automatically in DST Install Upgrade Test Pipeline
CRAYSAT-1962 Ensure SAT functional tests are run automatically on vShasta
```

### DOCS

```text
MTL-2606 DOCS: Update grep PCRE1 regexes that are no longer compliant
MTL-2592 DOCS: Document CSM 1.7.1 kernel version
CRAYSAT-2042 DOCS: Update "System Power On Procedure" to show master and worker nodes booted simultaneously
CASMTRIAGE-8940 DOCS: state tracking for m001 backup conflicts with Argo retry strategy
CASMTRIAGE-8935 DOCS: cray-vault-operator upgrade failing due to crd vaults.vault.banzaicloud.com
CASMTRIAGE-8931 DOCS: Add Note in management nodes rollout check whether /etc/cray/upgrade/csm/myenv file is present before starting management rollout for worker nodes
CASMTRIAGE-8912 DOCS: CA for CAST-39136 for cleanup of unused Luns
CASMTRIAGE-8856 DOCS: CSM 1.7.0 cray-upload-recovery-images fails for ChassisBMC and NodeBMC .itb files
CASMTRIAGE-8853 DOCS: Add TFTP Conntrack helper debugging steps to PXE runbook
CASMTRIAGE-8829 DOCS: nexus-export.sh missing path to nexus-helper.sh
CASMTRIAGE-8826 DOCS: CSM upgrade process fails to warn about checking and cleaning Nexus space usage

CASMTRIAGE-8706 DOCS: LOKI> Orange Phase upgrade> cilium_migration.sh shows Errors
CASMTRIAGE-8646 DOCS: baldar-cfs-ara-postgres member is stopped and fails to renit with error code 503
CASMTRIAGE-8627 DOCS: vShasta: control plane upgrade logs are written onto filesystem instead of kubernetes logging
CASMTRIAGE-8614 DOCS: Vidar : Purple testing : Error releasing chart cray-nexus v0.14.2
CASMTRIAGE-8509 DOCS:Rack Resiliency: Criticalservices pods are not spread properly over zones on odin
CASMTRIAGE-7386 DOCS: Seeing error in the compute node after removal of the tag "sbps-project" from the metadata section
CASMSEC-415 DOCS: CIS: Ensure that the --audit-log-maxsize argument is set to 100 or as appropriate
CASMSEC-413 DOCS: CIS: Ensure that the --audit-log-maxage argument is set to 30 or as appropriate
CASMPET-7696 DOCS: create a known issue to restart oauth2-proxy pod
CASMPET-7676 DOCS: Remove or update outdated Nexus corruption recovery procedure
CASMPET-7674 DOCS: upgrade_control_plane.sh clobbers kube-apiserver options without warning
CASMPET-7665 DOCS: Run remove_psp.sh script after manifests deployed at k8s 1.32
CASMPET-7657 DOCS: provide instructions for moving unmanaged OSDs
CASMPET-7540 DOCS: add master node promotion instructions to ncn reboot procedure
CASMPET-7461 DOCS: add instructions to clean up s3fs cache manually
CASMPET-6523 DOCS: Multia-Tenancy: Document key rotation
CASMNET-2368 DOCS: Procedures to replace an NCN NIC and boot an NCN using its secondary NIC
CASMNET-2365 DOCS: Update CANU guide in docs-csm repo
CASMNET-2336 DOCS: Update network content to reflect removal of UAS/UAI
CASMNET-2308 DOCS: Adjust unbound and kea resource requests for small systems
CASMNET-1796 DOCS: Configure Unbound -> PowerDNS link when non-default management networks are used
CASMMON-561 DOCS: Fix redfish-exporter docs
CASMINST-7461 DOCS: kafka secret update issue for LDAP replacement
CASMINST-7454 DOCS: Fix broken links
CASMINST-7451 DOCS: BACKUP_BSS_DATA needs to happen before BSS is updated
CASMINST-7441 DOCS: Install documentation needs to be update from username to USERNAME in a few places
CASMINST-6227 DOCS: Script info to check the metal.no-wipe settings for all NCNs
CASMHMS-6625 DOCS: Update CSM 1.7.1 release notes for HMS
CASMHMS-6597 DOCS: Lint and refactor HSM groups/partitions docs
CASMCMS-9611 DOCS: Updated release notes with bug fixes, doc enhancement etc for CSM 1.7.1
CASMCMS-9604 DOCS: Add Change logging level configuration as part of ims create/build image debug
CASMCMS-9597 DOCS: TESTS: Update documentation to add CFS Sessions Race Condition Test
CASMCMS-9579 DOCS: TESTS: Update documentation to reflect new cmsdev log location
CASMCMS-9536 DOCS: Update deprecations/removals page for CFS v1
CASMCMS-9522 DOCS: Improve CFS options documentation
CASMCMS-9521 DOCS: Console cli for MT will display password on screen if logging into node
CASMCMS-9520 DOCS: Improve documentation around increasing Ansible verbosity
CASMCMS-9517 DOCS: Update CSM 1.7.0 release notes for bug fix of CASMCMS-9512
CASMCMS-9516 DOCS: Known issue cfs session for image customization running on remote node is stuck in "running" status if ims job container is killed
CASM-5718 DOCS: Evaluate RR support for CSM features/operations
```

### MTL

```text
MTL-2610 Pending NCN Security update in CSM V1.7.1-beta.10
MTL-2605 metal-ipmitool: resolve CVE-2020-5208 by bumping version/release
MTL-2604 Locate/install/test mft and kernel-mft-mlnx-kmp-default RPMs
MTL-2603 Package update sweep / mitigate CVEs
MTL-2602 Upgrade ansible version in NCNs
MTL-2600 VTN Reports Known Exploited Vulnerabilities (KEVs) detected in storage-ceph-7.1.38-x86_64.squashfs image
MTL-2598 iptables rules for tftp fail to get applied
MTL-2596 VTN STROSS scan reported deny module is used in storage-ceph-7.1.38-x86_64.squashfs
MTL-2595 ceph kernel module not provided by kernel-default RPM in SP7
MTL-2594 Update PAM / fix blank password issue
MTL-2559 rbd kernel module not provided by kernel-default RPM in SP7 Beta
MTL-2549 EFI BootTrim fails on Broadcom
MTL-2543 Update csm-docker-sle-go Build Environment
MTL-2539 Move node-image builds to 15-SP7 (GM)
MTL-2538 Move node-image builds to 15-SP7 (BETA)
```
