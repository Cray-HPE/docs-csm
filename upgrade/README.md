# Upgrade CSM

There are several alternative procedures to perform an upgrade of Cray Systems Management (CSM)
software. Choose the appropriate procedure from the sections below.

* [Release Notes](#release-notes)
* [CSM major/minor version upgrade](#csm-majorminor-version-upgrade)
    * [Option 1: Upgrade CSM with additional HPE Cray EX software products](#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
    * [Option 2: Upgrade only additional HPE Cray EX software products](#option-2-upgrade-only-additional-hpe-cray-ex-software-products)
    * [Option 3: Upgrade only CSM](#option-3-upgrade-only-csm)
* [CSM patch version upgrade](#csm-patch-version-upgrade)
* [FM On Baremetal](#fm-on-baremetal)

## Release Notes

Before upgrading, review the [Release Notes](../RELEASE_NOTES.md)

## CSM major/minor version upgrade

Follow one of these procedures when upgrading from CSM 1.6 to CSM 1.7.0 or CSM 1.7.1 .

There is no need to upgrade from CSM 1.6 to CSM 1.7.0, and then separately upgrade from CSM 1.7.0 to the
CSM 1.7.1 release. The procedures in this section can be used to upgrade from CSM 1.6 directly to the
 CSM 1.7.1

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

If the starting version of the upgrade is CSM 1.7.0, then follow the [CSM major/minor version upgrade](#csm-majorminor-version-upgrade) instructions for Upgrading to CSM 1.7.1 .
CSM upgrades starting from 1.7.1 are expected to be done along with the upgrade of other products and should be done through IUF.

**`NOTE`**  From CSM 1.7.1 onwards the patches follow new naming convention: `CSM 1.7.1-patch.<patch-number>`

If there are multiple patch versions available after CSM 1.7.1, note that there is no need to perform intermediate
CSM 1.7.1 patch upgrades. Instead, consider upgrading to the latest CSM 1.7.1 patch release.

* [CSM 1.7.1-patch.1 Installation Instructions](1.7.1/README.md)

## FM On Baremetal

Post CSM Upgrade from 1.7.0 to CSM 1.7.1, if an administrator wishes to enable Fabric Manager on baremetal, they must follow the [procedure](../operations/fm_on_baremetal/README.md#fm-fabric-manager-on-baremetal).
