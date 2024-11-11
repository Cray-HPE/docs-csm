# Upgrade only CSM through IUF

This option describes how to upgrade Cray Systems Management (CSM) software on a CSM-only system
using IUF.

![Upgrade only CSM through IUF](../img/operations/diagram_upgrade_csm_with_IUF_101524.png)

## Description

The upgrade from CSM 1.5 to CSM 1.6 uses the IUF framework. The CSM upgrade steps are run automatically, either directly through IUF stages or by running a hook at the beginning or end of an IUF stage.
The hooks that are run for the CSM upgrade are described in the [description of CSM upgrade hooks](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md#description-of-csm-upgrade-hooks)
section of the [Upgrade CSM and additional products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) page.

## Upgrade Procedure

1. CSM preparation

   Read the _Important Notes_ section of the
   [CSM 1.5.0 or later to 1.6.0 Upgrade Process](Upgrade_Management_Nodes_and_CSM_Services.md)
   documentation and then follow only these CSM instructions in order:

   1. [Prepare for Upgrade](prepare_for_upgrade.md)

1. Prepare for the upgrade procedure and download product media

   1. Follow the IUF [Prepare for the install or upgrade](../operations/iuf/workflows/preparation.md) instructions to set
      environment variables used during the upgrade process.

   1. Download the desired HPE product media defined by the HPC CSM Software Recipe to `${MEDIA_DIR}`, which was defined in the previous step.

1. Product delivery

   > **NOTE** The CSM upgrade prerequisites are automatically executed in a hook run before `pre-install-check`.

   Follow the IUF [Product delivery](../operations/iuf/workflows/product_delivery.md) instructions.

1. Image preparation

   Follow the IUF [Image preparation](../operations/iuf/workflows/image_preparation.md) instructions.

1. Management rollout

   > **NOTE** The upgrade of CSM services and validation of CSM health occur automatically in a hook executed before the first management node is rolled out.

   Follow the IUF [Management rollout](../operations/iuf/workflows/management_rollout.md) instructions.

1. Deploy product

   > **NOTE** The application of networking changes and CoreDNS anti-affinity changes along with the upgrade of the Kubernetes control plane is performed in a hook automatically executed after `deploy-product`.

   Follow these IUF instructions in order:

   1. [Deploy product](../operations/iuf/workflows/deploy_product.md)
   1. [Validate deployment](../operations/iuf/workflows/validate_deployment.md)

The IUF upgrade workflow is now complete. Exit any typescript sessions created during the upgrade
procedure and remove any installation artifacts, if desired.
