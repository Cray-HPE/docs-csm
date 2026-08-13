# Cray System Management (CSM) 1.7.1-patch.1 Release Notes

This document guides an administrator through the patch update to Cray Systems Management 1.7.1-patch.1
from CSM 1.7.1 onwards only -- do not apply this patch directly to CSM 1.7.0.

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.7 release notes page, including links to other patch release notes,
see [CSM 1.7 release notes](RELEASE_NOTES.md).

* [Patch releases](#patch-releases)
* [Bug fixes, additions, and improvements](#bug-fixes-additions-and-improvements)
* [Upgrade steps](#upgrade-steps)

## Patch releases

This is the release notes page for CSM 1.7.1-patch.1;
each patch for CSM 1.7.1 has its own release notes, detailing what changes it includes.
For a full list of CSM 1.7.1 patch releases, see
[CSM 1.7.1 patch releases](RELEASE_NOTES_1.7.1.md#patch-releases).

## Bug fixes, additions, and improvements

* Fixed a `USS 1.5.1-1's` `blancapeak` boot failure on Grace-Hopper based compute nodes where the root file system mounted read-only after a USS update.  
  The `csm-sbps-dracut` package has been updated so these bind mounts are no longer mounted read-only, resolving the issue.
* `CVE-2026-31431` - Fixed CVE Linux kernel vulnerability in the `algif_aead` cryptographic API that could cause a copy operation to fail.
* `CVE-2026-46333` - Fixed CVE Linux kernel `ptrace` vulnerability.  
  New NCN node images have been built with the patched kernel, and vulnerability scan results confirm the issue is resolved.

## Upgrade steps

See [Upgrade CSM](upgrade/README.md).
