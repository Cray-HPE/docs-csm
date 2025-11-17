# Deploy Product

1. [Execute the IUF `deploy-product` stage](#1-execute-the-iuf-deploy-product-stage)
1. [Next steps](#2-next-steps)

## 1. Execute the IUF `deploy-product` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `deploy-product` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Ensure that the latest documentation is installed for the target CSM version being installed or upgraded.

    See [Check for latest documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

1. Invoke `iuf run` with activity identifier `${ACTIVITY_NAME}` and use `-r` to execute the [`deploy-product`](../stages/deploy_product.md) stage. Perform the upgrade using product content found in `${MEDIA_DIR}`.
   Additional arguments are available to control the behavior of the `deploy-product` stage (for example, `-rv`).
   See the [`deploy-product` stage documentation](../stages/deploy_product.md) for details and adjust the following example if necessary.

    (`ncn-m001#`) Execute the `deploy-product` stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml` file found in `${ADMIN_DIR}`.

    ```bash
    iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run --site-vars \
    "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r deploy-product
    ```

Once this step has completed:

> **NOTE**  
> As part of the `deploy-product` stage during upgrades from CSM 1.6 to CSM 1.7,
> the `deploy-product-onexit` hook will launch a Kubernetes upgrade job that runs outside of IUF, in the `argo` namespace.
>
> - The job will upgrade Kubernetes from version 1.26 to 1.32 in two hops. The first hop will be to version 1.29 and the second hop to version 1.32.
> - This job must be monitored manually and must complete successfully before proceeding to the next stage.
> - The job will restart when upgrading the master nodes to 1.32 and `kubelet` restarts. When the job restarts, a new output log will be created.
>
> (`ncn-mw#`) To tail the log file and see the progress, run:
>
> ```bash
> tail -f /root/upgrade_k8s_output_2025-10-31_11-30-25.log
> ```
>
> The output from the `deploy-product` stage will look like:
>
> ```text
> INFO Job upgrade-k8s-job-zm55x has been created in the argo namespace. This is performing k8s upgrade from 1.26 to 1.32
> INFO Monitor the job and ensure it is successful before proceeding to next stage.
> ```  
>
>(`ncn-mw#`) To get the job name, run:
>
> ```bash
> kubectl get jobs -n argo | grep upgrade-k8s
> ```
>
> (`ncn-mw#`) To monitor the job, run:
>
> ```bash
> kubectl wait job -n argo upgrade-k8s-job-zm55x --for=condition=complete --timeout=120m
> ```
>
> The amount of time the `upgrade-k8s-job` runs is directly related to the number of worker nodes in a system.
> The more worker nodes the longer it takes to complete the Kubernetes upgrade.
>
> Below is a table of estimated upgrade time in minutes:
>
> | # Workers | Time (m) |
> | --------- | -------- |
> | 4         | 110      |
> | 12        | 270      |
> | 16        | 350      |
> | 20        | 430      |
> | 28        | 590      |
>
> **IMPORTANT**  
> If the following error appears in the job execution logs and `cray-fox` pods show errors like below:
>
> ```text
> error when evicting pods/"cray-fox-bitnami-etcd-1" -n "services" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
> evicting pod services/cray-fox-bitnami-etcd-1
>```
>
> ```bash
> (ncn-mw#) kubectl get pods -A | grep fox
>services             cray-fox-6678f46c85-gdmt9                                         0/2     Init:0/2           0                 3d1h
>services             cray-fox-bitnami-etcd-0                                           1/2     CrashLoopBackOff   840 (119s ago)    3d1h
>services             cray-fox-bitnami-etcd-1                                           1/2     CrashLoopBackOff   823 (22s ago)     3d1h
>services             cray-fox-bitnami-etcd-2                                           1/2     CrashLoopBackOff   835 (4m52s ago)   3d1h
> ```
>
> Resolve this issue using the CSM Diagnostics installation guide to fix the `cray-fox` problem.
> The `upgrade-k8s-job` will only succeed after resolving this issue.

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
