# Upgrade CSM

There are several alternative procedures to perform an upgrade of Cray Systems Management (CSM)
software. Choose the appropriate procedure from the sections below.

* [Release Notes](#release-notes)
    * [NVIDIA CPU and GPU notice](#nvidia-cpu-and-gpu-notice)
    * [BOS data notice](#bos-data-notice)
* [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
    * [Option 1: Upgrade CSM with additional HPE Cray EX software products](#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
    * [Option 2: Upgrade only additional HPE Cray EX software products](#option-2-upgrade-only-additional-hpe-cray-ex-software-products)
    * [Option 3: Upgrade only CSM](#option-3-upgrade-only-csm)
* [CSM patch version upgrade](#csm-patch-version-upgrade)

## Release Notes

Before upgrading, review the [Release Notes](../RELEASE_NOTES.md)

## NVIDIA CPU and GPU notice

Servers with NVIDIA CPUs and GPUs are supported by CSM 1.6.1 and later versions.
These servers are **not supported by CSM 1.6.0**.

### BOS data notice

In CSM 1.6, BOS v1 is removed and the BOS API is enforcing various limits that previously had only been recommended.
Most of these limits are unlikely to be violated in practice (for example, the `description` field of session templates
is limited to 1023 characters in length).

When first upgrading to CSM 1.6, all BOS v1 session data is deleted, and all other BOS data is checked for
compliance with the API specification. It will attempt to automatically convert data to be in compliance with the
specification (for example, by truncating `description` fields that are longer than 1023 characters), but in rare
cases it may delete data. In general, if the migration deletes a session template, then it likely contains a fatal problem that
would have prevented it from working.

Regardless of the upgrade path that is used, a backup of the current BOS data is made before the BOS service is upgraded,
and a snapshot of the BOS data is also taken after the data migration completes. Both of these are uploaded to S3,
in either the `config-data` or `vbis` buckets. In addition, the `cray-bos-migration-` Kubernetes pod log contains a record
of any changes that were made during the migration. This pod log is also collected as part of the post-migration snapshot.

## CSM major/minor version upgrade

Follow one of these procedures when upgrading from CSM 1.5 to CSM 1.6 (regardless of patch version) or when upgrading from CSM 1.6.0
to a newer patch version.
(Additionally, in the unusual situation of upgrading from a pre-release version of CSM 1.6.0, then one of these procedure should be followed.)
If the starting CSM version of the upgrade is 1.6.1 or later, then see [CSM patch version upgrade](#csm-patch-version-upgrade).

There is no need to upgrade from CSM 1.5 to CSM 1.6.0, and then separately upgrade from CSM 1.6.0 to the
latest patch release. The procedures in this section can be used to upgrade from CSM 1.5 directly to the
latest patch release of CSM 1.6.

### Option 1: Upgrade CSM with additional HPE Cray EX software products

To perform an upgrade of CSM along with additional HPE Cray EX software products, see the
[Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)
procedure.

This is the most common procedure to follow, and it should be used when performing an upgrade from
one HPC CSM software recipe to another.

### Option 2: Upgrade only additional HPE Cray EX software products

To perform an upgrade of only the additional HPE Cray EX software products without
simultaneously upgrading CSM itself, see the
[Install or upgrade additional products with IUF](../operations/iuf/workflows/install_or_upgrade_additional_products_with_iuf.md)
procedure.

### Option 3: Upgrade only CSM

To upgrade only CSM, see the [Upgrade Only CSM with IUF](Upgrade_Only_CSM_with_iuf.md) procedure.

This option applies to CSM-only systems and systems which have additional HPE Cray EX software
products installed, as long as those additional products are not also being upgraded. This is an
uncommon upgrade scenario.

## CSM patch version upgrade

If the starting version of the upgrade is CSM 1.6.0, then follow the [CSM major/minor version upgrade](#csm-majorminor-version-upgrade) instructions.
CSM upgrades starting from 1.6.0 are expected to be done along with the upgrade of other products and should be done through IUF.

If the starting version of the upgrade is CSM 1.6.1 or later, then perform the upgrade using one of the following procedures. These procedures only upgrade
CSM itself, and not any other products.

If there are multiple patch versions available, note that there is no need to perform intermediate CSM 1.6 patch upgrades (provided that the starting
version is at least 1.6.1). Instead, consider upgrading to the latest CSM 1.6 patch release.

| *CSM Version* | *Release Notes*                            | *Patch Installation Instructions*                  |
|---------------|--------------------------------------------|----------------------------------------------------|
| 1.6.2         | [Release Notes](../RELEASE_NOTES_1.6.2.md) | [Patch Installation Instructions](1.6.2/README.md) |
