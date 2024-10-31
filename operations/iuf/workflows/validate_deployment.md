# Validate deployment

- [1. Execute the IUF `post-install-service-check` stage](#1-execute-the-iuf-post-install-service-check-stage)
- [2. Next steps](#2-next-steps)

## 1. Execute the IUF `post-install-service-check` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `post-install-service-check` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with `-r` to execute the [`post-install-service-check`](../stages/post_install_service_check.md) stage.

    (`ncn-m001#`) Execute the `post-install-service-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r post-install-service-check
    ```

Once this step has completed:

- Validation scripts have executed to verify the health of the product microservices
- Per-stage product hooks have executed for the `post-install-service-check` stage

## 2. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.
