# Upgrade only CSM through IUF

This option describes how to upgrade Cray Systems Management (CSM) software on a CSM-only system
using IUF.

![Upgrade only CSM through IUF](../img/operations/diagram_upgrade_csm_with_IUF_101524.png)

## Description

The upgrade from CSM 1.5 to CSM 1.6 uses the IUF framework. The CSM upgrade steps are run automatically, either directly through IUF stages or by running a hook at the beginning or end of an IUF stage.
The hooks that are run for the CSM upgrade are described in the [Description of CSM upgrade hooks](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md#description-of-csm-upgrade-hooks)
section of the [Upgrade CSM and Additional Products with IUF](../operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) page.

## Upgrade procedure

1. Read the _Important Notes_ section of the
   [CSM 1.5.0 or later to 1.6 Upgrade Process](Upgrade_Management_Nodes_and_CSM_Services.md)
   documentation.

1. [Prepare for Upgrade to Next CSM Major Version](https://github.com/Cray-HPE/docs-csm/tree/release/1.5/upgrade/Prepare_for_Upgrade_to_Next_CSM_Major_Version.md)
   in the CSM 1.5 documentation.

1. Prepare for the upgrade procedure and download product media.

   1. Follow the IUF [Prepare for the Install or Upgrade](../operations/iuf/workflows/preparation.md) instructions to set
      environment variables used during the upgrade process.

   1. Download the desired HPE product media defined by the HPC CSM Software Recipe to `${MEDIA_DIR}`, which was defined in the previous step.

1. Perform product delivery.

   > **NOTE** The CSM upgrade prerequisites are automatically executed in a hook run before `pre-install-check`.

   Follow the IUF [Product Delivery](../operations/iuf/workflows/product_delivery.md) instructions.

1. Prepare images.

   Follow the IUF [Image Preparation](../operations/iuf/workflows/image_preparation.md) instructions.

1. Perform management node rollout.

   > **NOTE** The upgrade of CSM services and validation of CSM health occur automatically in a hook executed before the first management node is rolled out.

   Follow the IUF [Management Rollout](../operations/iuf/workflows/management_rollout.md) instructions.

1. Deploy products.

   > **NOTE** The application of networking changes and CoreDNS anti-affinity changes along with the upgrade of the
   Kubernetes control plane is performed in a hook automatically executed after `deploy-product`.
   During the Kubernetes control plane upgrade, if Kubernetes audit logging is enabled, local audit log
   configuration changes will be lost as the audit log configuration will be reset to defaults defined in [Audit Logs](../operations/security_and_authentication/Audit_Logs.md).

   Follow these IUF instructions in order:

   1. [Deploy Product](../operations/iuf/workflows/deploy_product.md)
   1. [Validate Deployment](../operations/iuf/workflows/validate_deployment.md)

The IUF upgrade workflow is now complete. Exit any typescript sessions created during the upgrade
procedure and remove any installation artifacts, if desired.
