# Cray System Management (CSM) 1.7.1-patch.2 Release Notes

This document guides an administrator through the patch update to Cray Systems Management 1.7.1-patch.2
from CSM 1.7.1 onwards only -- do not apply this patch directly to CSM 1.7.0.

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.7 release notes page, including links to other patch release notes,
see [CSM 1.7 release notes](RELEASE_NOTES.md).

* [Patch releases](#patch-releases)
* [Bug fixes, additions, and improvements](#bug-fixes-additions-and-improvements)
* [Upgrade steps](#upgrade-steps)

## Patch releases

This is the release notes page for CSM 1.7.1-patch.2;
each patch for CSM 1.7.1 has its own release notes, detailing what changes it includes.
For a full list of CSM 1.7.1 patch releases, see
[CSM 1.7.1 patch releases](RELEASE_NOTES_1.7.1.md#patch-releases).

## Bug fixes, additions, and improvements

### Configuration Framework Service (CFS)

This patch includes many fixes and improvements for [CFS](glossary.md#configuration-framework-service-cfs).

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
* Several CVEs patched in CFS Batcher and CFS Operator.

## Upgrade steps

See [Upgrade CSM](upgrade/README.md).
