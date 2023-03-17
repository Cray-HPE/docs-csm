# Deploy product

- [1. Execute the IUF `deploy-product` stage](#1-execute-the-iuf-deploy-product-stage)
- [2. Next steps](#2-next-steps)

## 1. Execute the IUF `deploy-product` stage

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `deploy-product` stage.

1. Invoke `iuf run` with `-r` to execute the [`deploy-product`](../stages/deploy_product.md) stage.

    (`ncn-m001#`) Execute the `deploy-product` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r deploy-product
    ```

Once this step has completed:

- New versions of product microservices have been deployed
- Per-stage product hooks have executed for the `deploy-product` stage

## 2. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the IUF [Initial install](initial_install.md) workflow to continue the install.

- If performing an upgrade that includes upgrading CSM, return to the IUF [Upgrade](upgrade.md) workflow to continue the upgrade.
