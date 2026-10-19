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

1. [Further Reading](#further-reading)

## Further Reading

For comprehensive IUF documentation including advanced workflows, stage details,
and troubleshooting, refer to the official CSM documentation for your installed
CSM version:

- **Online:** <https://cray-hpe.github.io/docs-csm/en-17/operations/iuf/iuf/>
- **On-system:** If the `docs-csm` RPM matching your CSM version is installed,
  IUF documentation is available locally at `/usr/share/doc/csm/operations/iuf/`

Install or update the docs RPM:

```bash
zypper install -y docs-csm
```

> **Note:** IUF behavior and available stages may differ between CSM versions.
> Always reference the documentation that matches your installed CSM release.