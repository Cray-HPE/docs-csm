# Deploying Rapid Release Update with IUF

This procedure describes how to deploy a Rapid Release Update (RRU) to an operational CSM system using the Install and Upgrade Framework (IUF). It updates the operational CSM release with the CVE patches from `csm-security` product. The kernels of all the NCNs are updated using CFS to create new NCN images. NCNs are rebooted with the new image to complete the deployment.

This procedure is limited to the deployment of the new images to management nodes (NCNs) only.

> **Important:** This procedure must be performed with IUF. Do not install the
> security RPMs manually or treat product delivery alone as completion. A
> kernel update is active on a node only after the node boots with the newly
> prepared image.

The deployment workflow comprises the following steps. Instructions should be executed in the order  shown.

1. Prepare for the install procedure and download product media

   [Prepare for installing Rapid Release Update](prerequisites.md)

1. Configure

   Follow the [Configure SAT bootprep CFS Layers](configure_cfs.md) instructions.

1. Product Delivery and Update CFS Configuration

   Follow the [Product Delivery and Update CFS Configuration](product_delivery.md) instructions.

1. Image Preparation

   Follow the [Image Preparation](image_preparation.md) instructions.

1. Management Rollout

   Follow the [Management Nodes Rollout](management_nodes_rollout.md) instructions.

1. Post-Rollout Verification

   Follow the [Post-Rollout Verification](post_rollout_verification.md) instructions.

1. Return to the
  [Rapid Release Update (RRU) for CSM kernel CVE fixes](README.md)
 for [Further Reading](README.md#further-reading) section of Deploying Steps.
