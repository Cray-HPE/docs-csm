# Cray System Management (CSM) 1.7.1-patch.2 Release Notes

This document guides an administrator through the patch update to Cray Systems Management 1.7.1-patch.2
from CSM 1.7.1 onwards only -- do not apply this patch directly to CSM 1.7.0.

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.7 release notes page, including links to other patch release notes,
see [CSM 1.7 release notes](RELEASE_NOTES.md).

* [Patch releases](#patch-releases)
* [Bug fixes, additions, and improvements](#bug-fixes-additions-and-improvements)
  * [General](#general)
  * [Security](#security)
  * [Metal](#metal-mtl)
  * [Configuration Management Service](#configuration-management-service)
  * [Hardware Management Services](#hardware-management-services-hms)
  * [Base platform components](#base-platform-components-pet)
  * [Rack Resiliency](#rack-resiliency-rr)
  * [iscsi SBPS](#iscsi-sbps)
  * [Other Major Documentation Updates](#other-major-documentation-updates)
* [Troubleshooting Guides](#troubleshooting)
* [Upgrade steps](#upgrade-steps)


## Patch releases

This is the release notes page for CSM 1.7.1-patch.2;
each patch for CSM 1.7.1 has its own release notes, detailing what changes it includes.
For a full list of CSM 1.7.1 patch releases, see
[CSM 1.7.1 patch releases](RELEASE_NOTES_1.7.1.md#patch-releases).

## Bug fixes, additions, and improvements

### General

* Updated SLES base OS to `6.4.0-150700.53.84-default` version of SLES 15 SP7.
* New signing key for HPE delivered RPMs. See [here](#upgrade-steps) for installation instructions before starting upgrade.

### Security

* Updated several HMS services to point to latest upstream image and Go module dependencies.
* Many SLES security vulnerabilities remediated.
* Remediated KEVs and CVEs across CSM components.

### Metal (MTL)

This patch includes document improvements for METAL.

* Important Document Updates
   * Corrected procedure to validate Signed rpms 

### Configuration Management Service (CMS)

This patch includes many fixes and improvements for CMS.

* Improvements
    * Improved Kafka reliability in the CFS API server and [CFS Operator](operations/configuration_management/CFS_Operator.md).
    * Significantly faster [CFS session](operations/configuration_management/CFS_Sessions.md) creation.
    * Improved debug logging by the Kafka operations, CFS API server, CFS Operator, and [CFS Batcher](operations/configuration_management/CFS_Batcher.md).
    * Minor performance improvements to session filtering (used when performing bulk list, patch, or delete operations on sessions).
    * Improve CFS Batcher reliability with regards to system clock changes.
    * Make Kafka ProducerWrapper thread safe.

* Known issues fixed
    * [CFS Batcher Can Be Slow To See Updated CFS Options](troubleshooting/known_issues/CFS_Batcher_Can_Be_Slow_To_See_Updated_CFS_Options.md)
    * [CFS Batcher Creating Multiple Sessions For Same Batch](troubleshooting/known_issues/CFS_Batcher_Creating_Multiple_Sessions_For_Same_Batch.md)
    * [CFS Operator Creating Multiple Jobs For Same Session](troubleshooting/known_issues/CFS_Operator_Creating_Multiple_Jobs_For_Same_Session.md)
    * [CFS Component State Updates Allow Invalid Values](troubleshooting/known_issues/CFS_Component_State_Updates_Allow_Invalid_Values.md)
    * [CFS Component State Update Does Not Preserve Layer Timestamps](troubleshooting/known_issues/CFS_Component_State_Update_Does_Not_Preserve_Layer_Timestamps.md)
    * CFS API spec to enforce required fields in V2 and V3 component configuration state layers, preventing invalid patches that could cause CFS Batcher failures.

* Bugs Fixed
    * Fixed frequent ConMon restarts triggered by changes detected in River passwords, which resulted in missing ConMon logs.
    * Preserved the Ansible profiling setting across upgrades by backing up and restoring its value before upgrading the CFS Operator Helm chart.
 
* Security fixes
    * Remediated CVEs across CMS servcies: CFS Batcher, CFS hwsync agent, CFS Operator, Cray AEE(ansible-execution-environment),
      Console node and CSM Configuration and CFS ara.
    * Document the race condition vulnerabilities in BOS and CFS.

* Important Document Updates
    * Added documentation describing the IMS image creation job's missing extended attributes (xattr) support, its impact on image builds,
      and the workaround to resolve the issue.
    * [Common issues with staging sessions](../operations/boot_orchestration/Stage_Changes_with_BOS.md#common-issues-with-staging).

### Hardware Management Services (HMS)

This patch includes many fixes and documentation improvements for HMS.

* Bugs Fixed
   * Fixed telemetry collection and display issue with River Sensors dashboard

* Major Documentation Updates

   * Procedure to update SNMP credentials for existing switches.
   * Updates to various operational procedures in HMS including system power-down, SDU diagnostics, non-compute-node dumps, compute-blade replacement, et.al.
 
### Base platform components (PET)

This patch includes many fixes and documentation improvements for base platform components.

* Bugs Fixed
   * Corrected etcd health check failures when a cluster has no ready pods
   * Corrected the cluster role `cray-k8s-encryption` to move resources to appropriate `apiGroups`

* Major Documentation Updates
   * Added a procedure to diagnose and resolve a Kubernetes encryption status mismatch


### Rack Resiliency (RR)

This patch includes fixes for Rack Resiliency.

* Bugs Fixed
    * Fixed Ceph configuration updates during storage canary rollouts when Rack Resiliency is enabled.
    * Ceph monitor and service placement changes are now consistently propagated.
      
* Major Documentation Updates
    * Document method to reset worker node `topology` labels after a adhoc rebuild.

### iSCSI SBPS 

This patch includes many fixes and documentation updates for iscsi SBPS.

* Bugs Fixed
    * Optimized iSCSI SBPS Kubernetes label and HSN/NMN DNS record configuration to process only the current CFS batch, reducing rollout time, preventing CFS failures, and avoiding DNS records reconfigurations.
      
* Major Documentation Updates
    * Updated the worker node upgrade rollout procedure to avoid issues with
      timing dependencies and prevent LUN remapping issues.
    * Document methods for safe deletion of unused PE image.
    
### Other Major Documentation Updates

* Procedure to upgrade NCN kernel to higher version between Rapid Release Update and CSM base version during a CSM upgrade
* Procedure to perform management host Slingshot NIC firmware update before deploying a new image to worker nodes, avoiding an additional rolling reboot.

### Troubleshooting Guides

* [Race Condition Creating Gitea Repository During IUF deliver-product](troubleshooting/known_issues/iuf_gitea_repo_creation_race_deliver_product.md)

## Upgrade steps

When upgrading from CSM 1.7.1 directly to CSM 1.7.1-patch.2, install the new HPE RPM signing
key on all master and worker and storage nodes before proceeding with the upgrade:

1. Download the new HPE signing key from **My HPE Software Center:**.

    Download the signing key.

    ```bash
    curl LINK_TO_KEY_IN_My_HPE_Software_Center
    ```

2. Install the signing key on all master,worker and storage nodes.

    ```bash
    pdcp -w "$(grep -oP 'ncn-[mws]\w+' /etc/hosts | sort -u | paste -sd,)" PATH-TO-KEY/hpe-signing-key-dst-2026.asc /tmp/hpe-signing-key-dst-2026.asc
    ```

    ```bash
    pdsh -w "$(grep -oP 'ncn-[mws]\w+' /etc/hosts | sort -u | paste -sd,)" 'rpm --import /tmp/hpe-signing-key-dst-2026.asc'
    ```

3. After the signing key is installed, verify the new key has installed:

    1. (`ncn-mw#`) Get the 8 character key ID (version) from the signing key.

        ```bash
        KEYID=$(gpg --show-keys --with-colons hpe-signing-key-dst-2026.asc | awk -F: '$1=="pub" {print substr($5, 9, 8); exit}')
        echo "$KEYID"
        ```

        Example output:

        ```text
        19CFB373
        ```

    2. (`ncn-mw#`) Check all master, worker, and storage nodes to ensure the signing key associated with the 8 character key ID (version) is installed.

        ```bash
        pdsh -w "$(grep -oP 'ncn-[mws]\w+' /etc/hosts | sort -u | paste -sd,)" "rpm -q gpg-pubkey-$(echo $KEYID | tr 'A-Z' 'a-z')"
        ```

        Example output:

        ```text
        ncn-s001: gpg-pubkey-19cfb373-68b86a53
        ncn-s003: gpg-pubkey-19cfb373-68b86a53
        ncn-m001: gpg-pubkey-19cfb373-68b86a53
        ncn-s002: gpg-pubkey-19cfb373-68b86a53
        ncn-m002: gpg-pubkey-19cfb373-68b86a53
        ncn-s006: gpg-pubkey-19cfb373-68b86a53
        ncn-s004: gpg-pubkey-19cfb373-68b86a53
        ncn-s005: gpg-pubkey-19cfb373-68b86a53
        ncn-m003: gpg-pubkey-19cfb373-68b86a53
        ncn-w001: gpg-pubkey-19cfb373-68b86a53
        ncn-w005: gpg-pubkey-19cfb373-68b86a53
        ncn-w003: gpg-pubkey-19cfb373-68b86a53
        ncn-w004: gpg-pubkey-19cfb373-68b86a53
        ncn-w002: gpg-pubkey-19cfb373-68b86a53
        ```

Continue with the upgrade procedure.

See [Upgrade CSM](upgrade/README.md).
