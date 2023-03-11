# Prepare for the install or upgrade

This section defines environment variables and directory content that is used throughout the workflow.

**`NOTE`** The following step uses the `iuf activity` command to demonstrate how to record operations within an IUF activity. While `iuf` automatically records all `iuf run` operations within an IUF activity, any other
administrative operation can also be recorded within an IUF activity by using `iuf activity` in this manner. The remainder of the workflow will not use `iuf activity`, deferring to the administrator to use it as they desire.
`iuf activity` does not **need** to be used in this step, but the rest of the operations in the step are required.

- [1. Prepare for the install or upgrade](#1-prepare-for-the-install-or-upgrade)
- [2. Next steps](#2-next-steps)

## 1. Prepare for the install or upgrade

1. Create timestamped media, activity, and administrator directories on `ncn-m001`. Copy all distribution files from the HPC CSM Software Recipe to the media directory, utilizing `iuf activity` to record the time spent downloading
media and associate it with activity `${ACTIVITY_NAME}`.

    The following environment variables are used throughout the workflow:

    | Name               | Path                                           | Description                                                                               |
    | ------------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------------- |
    | `${ACTIVITY_NAME}` | n/a                                            | String identifier for the IUF activity and the `iuf -a` argument for all `iuf` commands   |
    | `${MEDIA_DIR}`     | `/etc/cray/upgrade/csm/"${ACTIVITY_NAME}"`     | Directory containing product distribution files                                           |
    | `${ACTIVITY_DIR}`  | `/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"` | Directory containing IUF activity logs and state                                          |
    | `${ADMIN_DIR}`     | `/etc/cray/upgrade/csm/admin`                  | Directory containing files that define site preferences for IUF, e.g. `product_vars.yaml` |

    (`ncn-m001#`) Create a typescript, set environment variables for the workflow, and populate the media directory with product content.

    ```bash
    script -af iuf-install.$(date +%Y%m%d_%H%M%S).txt
    ACTIVITY_NAME=update-products
    MEDIA_DIR=/etc/cray/upgrade/csm/media/"${ACTIVITY_NAME}"
    ACTIVITY_DIR=/etc/cray/upgrade/csm/iuf/"${ACTIVITY_NAME}"
    ADMIN_DIR=/etc/cray/upgrade/csm/admin
    mkdir -p "${ACTIVITY_DIR}" "${MEDIA_DIR}" "${ADMIN_DIR}"
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "downloading product media" in_progress
    <copy HPC CSM Software Recipe content to "${MEDIA_DIR}">
    iuf -a "${ACTIVITY_NAME}" activity --create --comment "download complete" waiting_admin
    ```

Once this step has completed:

- Product content has been uploaded to `${MEDIA_DIR}`

## 2. Next steps

- If performing an initial install, return to [Initial install](initial_install.md) to continue the install.

- If performing an upgrade, return to [Upgrade](upgrade.md) to continue the upgrade.
