# Initial Install

The following workflow describes the initial install procedure. The steps documented here are to be
followed after an initial install of CSM. They can also be followed whenever new non-CSM product
content is made available for upgrade via a HPC CSM Software Recipe release and there is no need to
upgrade CSM itself.

All stages of `iuf` are executed in this workflow: all of the new product software provided in the
recipe release is deployed and all management NCNs and managed compute and application nodes are
rebooted to new images and CFS configurations. Manual operations are documented for procedures that
are not currently managed by IUF.

The initial install workflow comprises the following procedures which must be executed in the order
shown.

1. Perform an install of CSM

   **`NOTE`** This step can be skipped if CSM is already installed.

   Follow the [Cray System Management Install](../../../install/README.md) instructions

1. Download product media, etc.

   Follow the IUF [Prepare for the install or upgrade](preparation.md) instructions

1. Product Delivery

   Follow the IUF [Product delivery](product_delivery.md) instructions

1. Deploy product

   Follow the IUF [Deploy product](deploy_product.md) instructions

1. Configuration

   Follow these IUF instructions in order:

   1. [Configuration](configuration.md)
   1. [Manual configuration of the Slingshot Fabric Manager](configuration_of_SFM.md)

1. Image preparation

   Follow the IUF [Image preparation](image_preparation.md) instructions

1. Management Rollout

   Follow the IUF [Management rollout](management_rollout.md) instructions

1. Validate deployment

   Follow the IUF [Validate deployment](validate_deployment.md) instructions

1. Managed rollout

   Follow the IUF [Managed rollout](managed_rollout.md) instructions

The initial install workflow is now complete. Exit any typescript sessions created during the
install procedure and remove any installation artifacts, if desired.
