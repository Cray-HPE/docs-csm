# Upgrade CSM and Additional Products with IUF

**Note: The CSM upgrade to CSM 1.7 is done with IUF.**

This procedure is used when performing an upgrade of Cray System Management (CSM) along with
additional HPE Cray EX software products at the same time. This procedure would be used when
upgrading from one HPC CSM Software Recipe release to another.

This procedure is _not_ used to perform an initial install or upgrade of HPE Cray EX software products
when CSM itself is not being upgraded. See
[Install or Upgrade Additional Products with IUF](install_or_upgrade_additional_products_with_iuf.md) for that procedure.

This procedure streamlines the rollout of new images to management nodes. These images are based
on the new images provided by the CSM product and customized by the additional HPE Cray EX software
products, including the [User Services Software (USS)](../../../glossary.md#user-services-software-uss)
and [Slingshot Host Software (SHS)](../../../glossary.md#slingshot-host-software-shs).

All stages of `iuf` are executed in this option. All of the new product software provided in the
recipe release is deployed and all [management NCNs](../../../glossary.md#management-nodes) and managed
[compute nodes](../../../glossary.md#compute-node-cn) and [application nodes](../../../glossary.md#application-node-an) are
rebooted to new images and [Configuration Framework Service (CFS)](../../../glossary.md#configuration-framework-service-cfs)
configurations. Manual operations are documented for procedures that are not currently managed by IUF.

The upgrade workflow comprises the following procedures. The diagram shows the workflow and
the steps below it provide detailed instructions which must be executed in the order shown.

The CSM upgrade steps are run automatically, either directly through IUF stages or by a hook automatically executed at the beginning or end of an IUF stage.

![Upgrade CSM and additional products with IUF](../../../img/operations/diagram_upgrade_csm_and_addl_products_with_iuf_07082025.png)

1. Read the _Important Notes_ section of the
   [CSM 1.6.0 or later to 1.7 Upgrade Process](../../../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md)
   documentation.

1. [Prepare for Upgrade to Next CSM Major Version](https://cray-hpe.github.io/docs-csm/en-16/upgrade/prepare_for_upgrade_to_next_csm_major_version/)
   in the CSM 1.6 documentation.

1. Prepare for the upgrade procedure and download product media

   1. Follow the IUF [Prepare for the Install or Upgrade](preparation.md) instructions to set
      environment variables used during the upgrade process.

   1. Download the desired HPE product media defined by the HPC CSM Software Recipe to `${MEDIA_DIR}`, which was defined in the previous step.

1. Product delivery

   Follow the IUF [Product Delivery](product_delivery.md) instructions.

1. Configuration

   Follow the IUF [Configuration](configuration.md) instructions.

1. Image preparation

   Follow the IUF [Image Preparation](image_preparation.md) instructions.

1. Backup

   Follow the IUF [Backup](backup.md) instructions.

1. Management rollout

   Follow the IUF [Management Rollout](management_rollout.md) instructions.

1. Deploy product

   Follow these IUF instructions in order:

   1. [Deploy Product](deploy_product.md)
   1. [Cilium Migration](cilium_migration.md)
   1. [Validate Deployment](validate_deployment.md)
   1. [Perform HPE Slingshot Switch and Management Network Switch Firmware Updates](slingshot_management_network_switch_updates.md)

   **`NOTE`** After completing this step, run the [Validate CSM Health](../../validate_csm_health.md) checks, as well as any product-specific health checks for items installed or upgraded during this activity.

1. Managed rollout

   Follow the IUF [Managed Rollout](managed_rollout.md) instructions.

The IUF upgrade workflow is now complete. Exit any typescript sessions created during the upgrade
procedure and remove any installation artifacts, if desired.
