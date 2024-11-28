# Upgrading management and managed nodes with different CSM versions using IUF

For certain use cases, there may be a need to combine different recipes of CSM to bring up the
management and managed nodes. For example, if a feature which supports a specific
CPU architecture for managed nodes is needed and that is present in a different recipe of CSM
than the version of CSM that will be run on management nodes.

## Procedure

1. Decide the recipes for management and managed nodes. For example, use recipe `a.b.c`,
which contains CSM version `1.5.x` for managed nodes and use recipe `x.y.z`, which contains
CSM version `1.6.x`, for management nodes.

1. Ensure that the CSM cluster is operational with the lowest among the selected recipes for both
management and managed nodes.

   If it is necessary to upgrade CSM to the lowest among the selected recipes, then
   use the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) procedure to upgrade CSM. In the
   above example, the upgrade would be to recipe `a.b.c`, which contains CSM version
   `1.5.x`, for both management and managed nodes.

1. Go through the `product_vars.yaml` file of both the recipes and come up with a set
of products and versions across the recipes which have to be upgraded for CSM version **`1.6.x`**.

1. Use the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) procedure to upgrade CSM until
[step 9, Managed rollout](../operations/iuf/workflows/managed_rollout.md), skip section
"2.2 Compute Nodes". That is, do not upgrade compute nodes to the recipe `x.y.z`
with CSM version `1.6.x` in order to keep the compute nodes on the `a.b.c` recipe
with CSM version `1.5.x`.

## Post install Testing

Execute the NCN health checks to validate that management nodes are executing correctly.

```bash
/opt/cray/tests/install/ncn/automated/ncn-healthcheck-master
/opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker
/opt/cray/tests/install/ncn/automated/ncn-healthcheck-storage
/opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks 
```

Execute the post install checks to validate that the managed nodes are executing correctly.
Refer to [Post Install Check](../operations/iuf/stages/post_install_check.md) on
running post install checks.
