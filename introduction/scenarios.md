# Scenarios for Shasta v1.5

There are multiple scenarios for installing CSM software which are described in this documentation
with many supporting procedures.

- Scenarios for Shasta v1.5
  - [Installation](#installation)
  - [Upgrade](#upgrade)
  - [Migration](#migration)

## Installation

There are two ways to install the CSM software. There are some differences between a first time install
which must create the initial configuration payload and configure the management network switches,
whereas a reinstall can reuse a previous configuration payload and skip the configuration of management
network switches. The first time install will check and then may update firmware for various components
whereas the reinstall will check and indicate that no firmware update is required. There are two different
ways to use the LiveCD, either from a RemoteISO or a USB device, which are described in [Bootstrap PIT Node](../install/README.md#1-bootstrap-pit-node).
There are a few places where a comment will be made in a procedure for how one of the scenarios needs to do something differently.

   * First time Install
      1. [Bootstrap PIT Node](../install/README.md#1-bootstrap-pit-node)
      1. [Configure Management Network Switches](../install/README.md#4-configure-management-network-switches)

   * Reinstall
      1. There may be additional steps to manually wipe disks on the management nodes and do other actions to prepare
         the management node hardware for the reinstall.
      1. [Bootstrap PIT Node](../install/README.md#1-bootstrap-pit-node)
      1. Can skip the procedure to [Configure Management Network Switches](../install/README.md#4-configure-management-network-switches)

The two paths merge together after configuration of the management network switches to do later actions
the same regardless of the starting point in the workflow.

   1. [Deploy Management Nodes](../install/README.md#5-deploy-management-nodes)
   1. [Install CSM Services](../install/README.md#6-install-csm-services)
   1. [Validate CSM Health Before Final NCN Deployment](../install/README.md#3-validate-csm-health-before-final-ncn-deployment)
   1. [Deploy Final NCN](../install/README.md#4-deploy-final-ncn)
   1. [Configure Administrative Access](../install/README.md#5-configure-administrative-access)
   1. [Validate CSM Health](../install/README.md#6-validate-csm-health)
   1. [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md)
   1. [Prepare Compute Nodes](../install/README.md#9-prepare-compute-nodes)

After completion of the firmware update with FAS and the preparation of compute nodes, the CSM product stream has
been fully installed and configured. Refer to the _HPE Cray EX System Software Getting Started Guide S-8000_
on the HPE Customer Support Center at https://www.hpe.com/support/ex-gsg for more information on other product streams
to be installed and configured after CSM.

See [Install CSM](../install/README.md) for the details on the installation process for either a first time install
or a reinstall.

## Upgrade

   The upgrade from Shasta v1.4.2 (including CSM 0.9.3) to Shasta v1.5 (including CSM 1.0) is supported.
   This process will upgrade the Ceph storage software, then the storage nodes, then the Kubernetes master nodes and worker nodes,
   and finally the CSM services. The management nodes are upgraded using a rolling upgrade approach which enables
   management services to continue to function even as one or a few nodes are being upgraded.

   See [Upgrade CSM](../upgrade/README.md).

## Migration

There is no direct migration from Shasta v1.3.x releases to Shasta v1.5. However, there is a supported path.

  * Migration from v1.3.x to v1.4.0

    The migration from v1.3.x to v1.4.0 is described in the Shasta v1.4 documentation.
    Refer to "1.3 to 1.4 Install Prerequisites" and "Collect Data From Healthy Shasta 1.3 System for EX 1.4 Installation" in the _HPE Cray EX System Installation and Configuration Guide 1.4 S-8000_.

  * Upgrade v1.4.x to v1.5

    An upgrade from the previous release (Shasta v1.4.x) is supported with this release.

    See [Upgrade from 1.4.x to v1.5](../upgrade/README.md)

