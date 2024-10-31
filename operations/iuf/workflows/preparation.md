# Prepare for the install or upgrade

This section defines environment variables and directory content that is used throughout the workflow.

- [1. Prepare for the install or upgrade](#1-prepare-for-the-install-or-upgrade)
- [2. Use of `iuf activity`](#2-use-of-iuf-activity)
- [3. Save system state before upgrade](#3-save-system-state-before-upgrade)
- [4. Next steps](#4-next-steps)

## 1. Prepare for the install or upgrade

1. Create timestamped media, activity, and administrator directories on `ncn-m001`.

    The following environment variables are used throughout the workflow:

    | Name               | Recommended Value                                | Description                                                                                                                       |
    |--------------------|--------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
    | `${ACTIVITY_NAME}` | Use a short descriptor for the activity          | String identifier for the IUF activity and the `iuf -a` argument for all `iuf` commands                                           |
    | `${MEDIA_DIR}`     | `/etc/cray/upgrade/csm/media/"${ACTIVITY_NAME}"` | Directory containing product distribution files                                                                                   |
    | `${ACTIVITY_DIR}`  | `/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"`   | Directory containing IUF activity logs and state                                                                                  |
    | `${ADMIN_DIR}`     | `/etc/cray/upgrade/csm/admin`                    | Directory containing files that define default values and site preferences for IUF, e.g. `product_vars.yaml` and `site_vars.yaml` |

    (`ncn-m001#`) Create a typescript and set environment variables that will be used later in the install or upgrade workflow. The example value of `${ACTIVITY_NAME}` can be changed as needed.

    ```bash
    script -af iuf-install.$(date +%Y%m%d_%H%M%S).txt
    ACTIVITY_NAME=update-products
    MEDIA_DIR=/etc/cray/upgrade/csm/media/"${ACTIVITY_NAME}"
    ACTIVITY_DIR=/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"
    ADMIN_DIR=/etc/cray/upgrade/csm/admin
    mkdir -p "${ACTIVITY_DIR}" "${MEDIA_DIR}" "${ADMIN_DIR}"
    ```

    Once this step has completed:

    - Environment variables have been set and required IUF directories have been created

1. Ensure that the
   [latest version of `docs-csm`](https://github.com/Cray-HPE/docs-csm/blob/release/1.6/update_product_stream/README.md#check-for-latest-documentation)
    is installed for the target CSM version being installed or upgraded.

    **`NOTE`** When using IUF to upgrade CSM, please skip this subsection.

    For example: when upgrading from CSM version 1.5.0 to version 1.5.1, install `docs-csm-1.5.1.noarch`

## 2. Use of `iuf activity`

**`NOTE`** This section is informational only. There are no operations to perform.

IUF can record time spent performing operations associated with an IUF activity. While `iuf` automatically records all `iuf run` operations within an IUF activity, any other administrative operations can also be recorded within an
IUF activity by using [`iuf activity`](../IUF.md#activity). The following example shows how to record the time spent downloading HPE software and associate it with an IUF activity:

(`ncn-m001#`) Example use of `iuf activity` to record time spent downloading media

```bash
iuf -a "${ACTIVITY_NAME}" activity --create --comment "downloading product media" in_progress
<download HPE product media>
iuf -a "${ACTIVITY_NAME}" activity --create --comment "download complete" waiting_admin
```

The install and upgrade workflow instructions will not use `iuf activity` in this manner, deferring to the administrator to use it as desired.

## 3. Save system state before upgrade

(`ncn-m001#`) Before performing the install/upgrade, it is important to save specific system state information so that it can be referenced later if needed.
Run the script below to save the state information. The information gathered by this script is SAT status, SAT site information,
HSN status, Ceph status, and SDU and RDA configurations. This information will be saved in `/etc/cray/upgrade/csm/system-status/`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/util/pre-upgrade-status.sh
```

## 4. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.
