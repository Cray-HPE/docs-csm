# Cray System Management (CSM) 1.7.1-patch.1 Release Notes

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Upgrade Steps](#upgrade-steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `1.7.1-patch.1`
from CSM `1.7.1` onwards only.

## Bug fixes and improvements

* Fixed a `USS 1.5.1-1's` `blancapeak` boot failure on Grace-Hopper based compute nodes where the root file system mounted read-only after a USS update.

The `csm-sbps-dracut` package has been updated so these bind mounts are no longer mounted read-only, resolving the issue.

* `CVE-2026-31431` - Fixed CVE Linux kernel vulnerability in the `algif_aead` cryptographic API that could cause a copy operation to fail.

* `CVE-2026-46333` - Fixed CVE Linux kernel `ptrace` vulnerability.

  New NCN node images have been built with the patched kernel, and vulnerability scan results confirm the issue is resolved.

## Upgrade Steps

Follow the procedures described in [CSM major/minor version upgrade](upgrade/README.md#csm-majorminor-version-upgrade#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
