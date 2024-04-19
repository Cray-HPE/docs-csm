# Upgrade CSM

There are several alternative procedures to perform an upgrade of Cray Systems Management (CSM)
software. Choose the appropriate procedure from the sections below.

* [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
    * [Option 1: Upgrade CSM with additional HPE Cray EX software products](#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
    * [Option 2: Upgrade only additional HPE Cray EX software products](#option-2-upgrade-only-additional-hpe-cray-ex-software-products)
    * [Option 3: Upgrade only CSM](#option-3-upgrade-only-csm)
* [CSM patch version upgrade](#csm-patch-version-upgrade)

## CSM major/minor version upgrade

Follow one of these procedures when upgrading from CSM 1.5 to CSM 1.6 (regardless of patch version).
(Additionally, in the unusual situation of upgrading from a pre-release version of CSM 1.6.0, then one of these
procedure should be followed.)

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

To perform an upgrade of only CSM, see the [Upgrade Only CSM](Upgrade_Only_CSM.md) procedure.

This option applies to CSM-only systems and systems which have additional HPE Cray EX software
products installed, as long as those additional products are not also being upgraded. This is an
uncommon upgrade scenario.

## CSM patch version upgrade

Follow one of these procedures when upgrading from CSM 1.6 to a newer patch version of CSM 1.6.
(The one exception is in the unusual situation of upgrading from a pre-release version of CSM 1.6.0;
in that case, follow the [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
procedures).

If there are multiple patch versions available, note that there is no need to perform intermediate
CSM 1.6 patch upgrades. Instead, consider upgrading to the latest CSM 1.6 patch release.

There are no CSM 1.6 patch versions currently available. When any become available, they will
be listed here.
