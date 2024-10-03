# Upgrade CSM

There are several alternative procedures to perform an upgrade of Cray Systems Management (CSM)
software. Choose the appropriate procedure from the sections below.

* [Release Notes](#release-notes)
* [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
    * [Option 1: Upgrade CSM with additional HPE Cray EX software products](#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
    * [Option 2: Upgrade only additional HPE Cray EX software products](#option-2-upgrade-only-additional-hpe-cray-ex-software-products)
    * [Option 3: Upgrade only CSM](#option-3-upgrade-only-csm)
* [CSM patch version upgrade](#csm-patch-version-upgrade)

## Release Notes

Before upgrading, review the [Release Notes](../RELEASE_NOTES.md)

### NVIDIA CPU and GPU notice

Servers with NVIDIA CPUs and GPUs are **not** supported by CSM 1.6.0. Systems with these servers should
**not** be upgraded to CSM 1.6.0.

The January 2025 HPE HPC continuous software stack releases (CSM 1.6.0) are for HPE Cray EX systems without NVIDIA CPUs and GPUs.
For HPE Cray EX systems with NVIDIA CPUs and GPUs, please use the August 2024 (CSM 1.5.x) HPE HPC continuous software stack.
These software stacks were validated with NVIDIA HPC SDK 24.3.

The March 2025 HPE HPC continuous and extended software stack releases will be validated with NVIDIA HPC SDK 24.11.
The March 2025 (CSM 1.6.1) software stacks will support all HPE Cray EX systems.

## CSM major/minor version upgrade

Follow one of these procedures when upgrading from CSM 1.5 to CSM 1.6 (regardless of patch version).
(Additionally, in the unusual situation of upgrading from a pre-release version of CSM 1.6.0, then one of these
procedure should be followed.)

There is no need to upgrade from CSM 1.5 to CSM 1.6.0, and then separately upgrade from CSM 1.6.0 to the
latest patch release. The procedures in this section can be used to upgrade from CSM 1.5 directly to the
latest patch release of CSM 1.6.

### Option 1: Upgrade CSM with additional HPE Cray EX software products

To perform an upgrade of CSM along with additional HPE Cray EX software products, see the
[Upgrade CSM and additional products](../operations/iuf/workflows/upgrade_csm_and_additional_products.md)
procedure.

This is the most common procedure to follow, and it should be used when performing an upgrade from
one HPC CSM software recipe to another.

### Option 2: Upgrade only additional HPE Cray EX software products

To perform an upgrade of only the additional HPE Cray EX software products without
simultaneously upgrading CSM itself, see the
[Install or upgrade additional products with IUF](../operations/iuf/workflows/install_or_upgrade_additional_products_with_iuf.md)
procedure.

### Option 3: Upgrade only CSM

There are two options to perform an upgrade of only CSM:

1. [Upgrade Only CSM without IUF](Upgrade_Only_CSM_without_iuf.md) procedure.

1. [Upgrade Only CSM with IUF](Upgrade_Only_CSM_with_iuf.md) procedure.

This option applies to CSM-only systems and systems which have additional HPE Cray EX software
products installed, as long as those additional products are not also being upgraded. This is an
uncommon upgrade scenario.

**Note: Beyond CSM 1.6 IUF will be the only option to upgrade CSM with or without additional HPE Cray EX software products.**

## CSM patch version upgrade

Follow one of these procedures when upgrading from CSM 1.6 to a newer patch version of CSM 1.6.
(The one exception is in the unusual situation of upgrading from a pre-release version of CSM 1.6.0;
in that case, follow the [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
procedures).

If there are multiple patch versions available, note that there is no need to perform intermediate
CSM 1.6 patch upgrades. Instead, consider upgrading to the latest CSM 1.6 patch release.

There are no CSM 1.6 patch versions currently available. When any become available, they will
be listed here.
