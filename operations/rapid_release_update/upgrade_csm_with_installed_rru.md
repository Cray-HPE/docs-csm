# Upgrading CSM on a system installed with Rapid Release Updates

This procedure describes how to upgrade CSM to a newer version on a system where a Rapid Release Update (RRU)
has already been installed.

* [Overview](#overview)
* [Determine the kernel versions](#determine-the-kernel-versions)

## Overview

A Rapid Release Update (RRU) delivers SUSE kernel security (CVE) fixes for a specific CSM base release by adding the `csm-security` CFS layer, rebuilding the NCN images, and rebooting the NCNs with the new image.

A subsequent CSM upgrade delivers new NCN images, which may contain kernel versions that are either higher or lower than the kernel version currently installed on the system.

Depending on the CSM version installed on the system, refer to [Considerations when upgrading CSM after installing RRU](README.md#considerations-for-upgrading-csm-after-installing-rru) before proceeding with the upgrade.

## Determine the kernel versions

1. (`ncn-m001#`) Determine the kernel version currently running on the NCNs.

  ```bash
  CURR_KERNEL_VERSION=$(uname -r)
  echo $CURR_KERNEL_VERSION
  ```

1. Determine the kernel version of the target CSM version, as listed in [CSM Release Notes](../../upgrade/README.md#release-notes)

  ```bash
  TARGET_KERNEL_VERSION=<KERNEL_VERSION_FROM_RN_DOC>
  echo $TARGET_KERNEL_VERSION
  ```

  **Note:** Replace `KERNEL_VERSION_FROM_RN_DOC` with the target kernel version specified in the Release Notes document.

1. Compare the current and new kernel version

  ```bash
  if [[ "$CURR_KERNEL_VERSION" != "$TARGET_KERNEL_VERSION" ]] && [[ "$(printf '%s\n' "$CURR_KERNEL_VERSION" "$TARGET_KERNEL_VERSION" | sort -V | tail -n 1)" == "$CURR_KERNEL_VERSION" ]]; then
    echo "Bootprep file has to be updated with the csm-security layer."
  fi
  ```

1. If the above command prints the message, then during the `update-cfs-config` stage of the CSM upgrade, [update the bootprep file](configure_cfs.md) to include the `csm-security` layer before proceeding with the `update-vcs-config` stage.
