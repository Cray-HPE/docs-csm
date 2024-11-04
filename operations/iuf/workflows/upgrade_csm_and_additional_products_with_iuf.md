# Upgrade CSM and additional products with IUF

**Note: The CSM upgrade to CSM 1.6 is done with IUF.**

This procedure is used when performing an upgrade of Cray System Management (CSM) along with
additional HPE Cray EX software products at the same time. This procedure would be used when
upgrading from one HPC CSM Software Recipe release to another.

This procedure is _not_ used to perform an initial install or upgrade of HPE Cray EX software products
when CSM itself is not being upgraded. See
[Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md) for that procedure.

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
For more detail about about the CSM upgrade hooks, see the section [description of CSM upgrade hooks](#description-of-csm-upgrade-hooks).

![Upgrade CSM and additional products with IUF](../../../img/operations/diagram_upgrade_csm_stack_with_IUF_101624.png)

1. CSM preparation

   Read the _Important Notes_ section of the
   [CSM 1.5.0 or later to 1.6.0 Upgrade Process](../../../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md)
   documentation and then follow only these CSM instructions in order:

   1. [Prepare for Upgrade](../../../upgrade/prepare_for_upgrade.md)

1. Prepare for the upgrade procedure and download product media

   1. Follow the IUF [Prepare for the install or upgrade](preparation.md) instructions to set
      environment variables used during the upgrade process.

   1. Download the desired HPE product media defined by the HPC CSM Software Recipe to `${MEDIA_DIR}`, which was defined in the previous step.

1. Product delivery

   > **NOTE** The CSM upgrade prerequisites are automatically executed in a hook run before `pre-install-check`.

   Follow the IUF [Product delivery](product_delivery.md) instructions.

1. Configuration

   Follow the IUF [Configuration](configuration.md) instructions.

1. Image preparation

   Follow the IUF [Image preparation](image_preparation.md) instructions.

1. Backup

   Follow the IUF [Backup](backup.md) instructions.

1. Management rollout

   > **NOTE** The upgrade of CSM services and validation of CSM health occur automatically in a hook executed before the first management node is rolled out.

   Follow the IUF [Management rollout](management_rollout.md) instructions.

1. Deploy product

   > **NOTE** The application of networking changes and CoreDNS anti-affinity changes along with the upgrade of the Kubernetes control plane is performed in a hook automatically executed after `deploy-product`.

   Follow these IUF instructions in order:

   1. [Deploy product](deploy_product.md)
   1. [Validate deployment](validate_deployment.md)

1. Managed rollout

   Follow the IUF [Managed rollout](managed_rollout.md) instructions.

The IUF upgrade workflow is now complete. Exit any typescript sessions created during the upgrade
procedure and remove any installation artifacts, if desired.

## Description of CSM upgrade hooks

The hooks below are automatically executed when CSM is being upgraded with IUF.

- CSM upgrade prerequisites

   CSM upgrade prerequisites are executed in a hook run before `pre-install-check`. This executes steps that are dependencies for later CSM upgrade steps.
   This includes some service chart upgrades, uploading base NCN images to be used later in `prepare-images`, and other setup steps.
   The specific script that is being executed is `/usr/share/doc/csm/upgrade/scripts/upgrade/prerequisites.sh`.

- Upgrade of CSM services and validation of CSM health

   The upgrade of CSM services and validation of CSM health are performed in a hook executed before `management-nodes-rollout`. This hook is only executed before the first NCN is upgraded.
   The specific script that executes the CSM services upgrade is `/usr/share/doc/csm/upgrade/scripts/upgrade/csm-upgrade.sh`.

- Application of networking changes, CoreDNS anti-affinity, upgrade of the Kubernetes control plane

   The application of networking changes and CoreDNS anti-affinity changes along with the upgrade of the Kubernetes control plane is performed in a hook executed after `deploy-product`.
   The specific scripts executed as part of this hook are `/srv/cray/scripts/common/apply-networking-manifests.sh`, `/usr/share/doc/csm/upgrade/scripts/k8s/apply-coredns-pod-affinity.sh`, and `/usr/share/doc/csm/upgrade/scripts/k8s/upgrade_control_plane.sh`.
