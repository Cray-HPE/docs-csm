# Upgrade CSM

There are several alternative procedures to perform an upgrade of Cray Systems Management (CSM)
software. Choose the appropriate procedure from the sections below.

> **NOTE** After CSM 1.7.1, the patch release versions follow a new naming convention
> (`1.7.1-patch.<patch-number>`), starting with 1.7.1-patch.1

* [Release notes](#release-notes)
* [Fabric Manager on baremetal](#fabric-manager-on-baremetal)
* [Valid upgrade paths](#valid-upgrade-paths)
* [CSM upgrade procedures](#csm-upgrade-procedures)
    * [Option 1: Upgrade CSM with additional HPE Cray EX software products](#option-1-upgrade-csm-with-additional-hpe-cray-ex-software-products)
    * [Option 2: Upgrade only additional HPE Cray EX software products](#option-2-upgrade-only-additional-hpe-cray-ex-software-products)
    * [Option 3: Upgrade only CSM](#option-3-upgrade-only-csm)

## Release notes

* [CSM 1.7.0 Release Notes](../RELEASE_NOTES.md)

* [CSM 1.7.1 Release Notes](../RELEASE_NOTES_1.7.1.md)

* [CSM 1.7.1-patch.1 Release Notes](../RELEASE_NOTES_1.7.1-patch.1.md)

* [CSM 1.7.1-patch.2 Release Notes](../RELEASE_NOTES_1.7.1-patch.2.md)

## Fabric Manager on baremetal

After CSM is upgraded from 1.7.0 to CSM 1.7.1, if desiring to enable Fabric Manager on baremetal,
then see [Slingshot Fabric Manager on baremetal](../operations/fm_on_baremetal/README.md).

## Valid upgrade paths

These [CSM upgrade procedures](#csm-upgrade-procedures) can be used to perform the following upgrades:

| *Starting CSM version* | *Target CSM version*        |
| ---------------------- | --------------------------- |
| 1.6.x                  | 1.7.0                       |
| 1.6.x                  | 1.7.1                       |
| 1.7.0                  | 1.7.1                       |
| 1.7.1                  | `1.7.1-patch.x`             |
| `1.7.1-patch.x`        | `1.7.1-patch.y` (`y` > `x`) |

> **NOTE** Upgrading to CSM `1.7.1-patch.x` can only be done only from CSM 1.7.1 or higher.

## CSM upgrade procedures

Before upgrading, review the corresponding [release notes](#release-notes).

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
