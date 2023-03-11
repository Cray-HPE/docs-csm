# Validate deployment

- [1. Execute the IUF `post-install-service-check` stage](#1-execute-the-iuf-post-install-service-check-stage)
- [2. Next steps](#2-next-steps)

## 1. Execute the IUF `post-install-service-check` stage

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `post-install-service-check` stage.

1. Invoke `iuf run` with `-r` to execute the [`post-install-service-check`](../stages/post_install_service_check.md) stage.

    (`ncn-m001#`) Execute the `post-install-service-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r post-install-service-check
    ```

Once this step has completed:

- Validation scripts have executed to verify the health of the product microservices
- Per-stage product hooks have executed for the `post-install-service-check` stage

## 2. Next steps

- If performing an initial install, return to [Initial install](initial_install.md) to continue the install.

- If performing an upgrade, return to [Upgrade](upgrade.md) to continue the upgrade.
