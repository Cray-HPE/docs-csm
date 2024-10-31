# Deploy product

1. [Execute the IUF `deploy-product` stage](#1-execute-the-iuf-deploy-product-stage)
1. [Next steps](#2-next-steps)

## 1. Execute the IUF `deploy-product` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `deploy-product` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-r` to execute the [`deploy-product`](../stages/deploy_product.md) stage. Perform the upgrade using product content found in `${MEDIA_DIR}`.
   Additional arguments are available to control the behavior of the `deploy-product` stage (for example, `-rv`).
   See the [`deploy-product` stage documentation](../stages/deploy_product.md) for details and adjust the following example if necessary. **`NOTE`** Ensure that the
   [latest version of `docs-csm`](https://github.com/Cray-HPE/docs-csm/blob/release/1.6/update_product_stream/README.md#check-for-latest-documentation)
   is installed for the target CSM version being installed or upgraded.

      (`ncn-m001#`) Execute the `deploy-product` stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml` file found in `${ADMIN_DIR}`.

   ```bash
   iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run --site-vars \
   "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r deploy-product
   ```

Once this step has completed:

- New versions of product microservices have been deployed
- Per-stage product hooks have executed for the `deploy-product` stage

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
