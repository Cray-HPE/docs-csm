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
* [Known Issues](#known-issues)
* [Upgrade steps](#upgrade-steps)


## Patch releases

This is the release notes page for CSM 1.7.1-patch.2;
each patch for CSM 1.7.1 has its own release notes, detailing what changes it includes.
For a full list of CSM 1.7.1 patch releases, see
[CSM 1.7.1 patch releases](RELEASE_NOTES_1.7.1.md#patch-releases).

## Bug fixes, additions, and improvements

### General

* Updated SLES base OS to '6.4.0-150700.53.84-default' version of SLES 15 SP7.
* New signing key for HPE delivered RPMs. See [here](#upgrade-steps) for installation instructions before starting upgrade.

### Security

* Updated several HMS services to point to latest upstream image and Go module dependencies.
* Many SLES security vulnerabilities remediated.
* Remediated KEVs and CVEs across CSM components.

### Metal (MTL)

This patch includes many fixes and improvements for METAL.

* Important Document Updates
```text
   Corrected procedure to validate Signed rpms
```    

### Configuration Management Service (CMS)

This patch includes many fixes and improvements for CMS.

* Improvements
    * Improved Kafka reliability in the CFS
      API server and [CFS Operator](operations/configuration_management/CFS_Operator.md).
    * Significantly faster [CFS session](operations/configuration_management/CFS_Sessions.md) creation.
    * Improved debug logging by the CFS API server, CFS Operator, and
      [CFS Batcher](operations/configuration_management/CFS_Batcher.md).
    * Minor performance improvements to session filtering (used when performing bulk list, patch,
      or delete operations on sessions).
    * Improve CFS Batcher reliability with regards to system clock changes.
* Known issues fixed
    * [CFS Batcher Can Be Slow To See Updated CFS Options](troubleshooting/known_issues/CFS_Batcher_Can_Be_Slow_To_See_Updated_CFS_Options.md)
    * [CFS Batcher Creating Multiple Sessions For Same Batch](troubleshooting/known_issues/CFS_Batcher_Creating_Multiple_Sessions_For_Same_Batch.md)
    * [CFS Operator Creating Multiple Jobs For Same Session](troubleshooting/known_issues/CFS_Operator_Creating_Multiple_Jobs_For_Same_Session.md)
    * [CFS Component State Updates Allow Invalid Values](troubleshooting/known_issues/CFS_Component_State_Updates_Allow_Invalid_Values.md)
    * [CFS Component State Update Does Not Preserve Layer Timestamps](troubleshooting/known_issues/CFS_Component_State_Update_Does_Not_Preserve_Layer_Timestamps.md)
* Bugs Fixed
```text
  CASMTRIAGE-9260 CAST-40271 Conman restarting frequently
```    
* Important Document Updates
```text
```    

### Hardware Management Services (HMS)

This patch includes many fixes and documentation improvements for HMS.

* Bugs Fixed
```text
   Fixed telemetry collection and display issue with River Sensors dashboard
```    
* Major Documentation Updates
```text
   Procedure to update SNMP credentials for existing switches.
   Updates to various operational procedures in HMS including system power-down,
   SDU diagnostics, non-compute-node dumps, compute-blade replacement, et.al.
```    

### Base platform components (PET)

This patch includes many fixes and documentation improvements for base platform components.

* Bugs Fixed
```text
   Corrected etcd health check failures when a cluster has no ready pods
   Corrected the cluster role `cray-k8s-encryption` to move resources to appropriate `apiGroups`
```    

* Major Documentation Updates
```text
   Added a procedure to diagnose and resolve a Kubernetes encryption status mismatch
```    

### Rack Resiliency (RR)

This patch includes fixes for Rack Resiliency.

* Bugs Fixed
```text
   Fixed Ceph configuration updates during storage canary rollouts when Rack Resiliency is enabled. 
   Ceph monitor and service placement changes are now consistently propagated.
```    

### iscsi SBPS

This patch includes many fixes and improvements for base platform components.

* Improvements
* Known issues fixed
* Bugs Fixed
```text
```    
* Major Documentation Updates
```text
```    


### Other Major Documentation Updates

```text
   Procedure to upgrade NCN kernel to higher version between Rapid Release Update and CSM base version during a CSM upgrade
```

## Known Issues

## Upgrade steps

See [Upgrade CSM](upgrade/README.md).
