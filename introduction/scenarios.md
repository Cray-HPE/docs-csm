# Scenarios for Shasta v1.5

There are multiple scenarios for installing CSM software which are described in this documentation
with many supporting procedures.

- Scenarios for Shasta v1.5
  - [Installation](#installation)
  - [Upgrade](#upgrade)
  - [Migration](#migration)

<a name="installation"></a>
## Installation

There are two ways to install the CSM software. There are some differences between a first time install
which must create the initial configuration payload and configure the management network switches,
whereas a reinstall can reuse a previous configuration payload and skip the configuration of management
network switches. The first time install will check and then may update firmware for various components
whereas the reinstall will check and indicate that no firmware update is required. There are two different
ways to use the LiveCD, either from a RemoteISO or a USB device, which are described in [Bootstrap PIT Node](../install/index.md#bootstrap_pit_node).
There are a few places where a comment will be made in a procedure for how one of the scenarios needs to do something differently.

   * First time Install
      1. [Prepare Configuration Payload](../install/index.md#prepare_configuration_payload) creates the initial configuration payload.
      1. [Bootstrap PIT Node](../install/index.md#bootstrap_pit_node)
      1. [Configure Management Network Switches](../install/index.md#configure_management_network)

   * Reinstall
      1. [Prepare Configuration Payload](../install/index.md#prepare_configuration_payload) can reuse a previous configuration payload.
      1. There may be additional steps to manually wipe disks on the management nodes and do other actions to prepare
         the management node hardware for the reinstall.
      1. [Bootstrap PIT Node](../install/index.md#bootstrap_pit_node)
      1. Can skip the procedure to [Configure Management Network Switches](../install/index.md#configure_management_network)

The two paths merge together after configuration of the management network switches to do later actions
the same regardless of the starting point in the workflow.

   1. [Deploy Management Nodes](../install/index.md#deploy_management_nodes)
   1. [Install CSM Services](../install/index.md#install_csm_services)
   1. [Validate CSM Health Before Final NCN Deployment](../install/index.md#validate_csm_health_before_final_ncn_deploy)
   1. [Deploy Final NCN](../install/index.md#deploy_final_ncn)
   1. [Configure Administrative Access](../install/index.md#configure_administrative_access)
   1. [Validate CSM Health](../install/index.md#validate_csm_health)
   1. [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md)
   1. [Prepare Compute Nodes](../install/index.md#prepare_compute_nodes)

After completion of the firmware update with FAS and the preparation of compute nodes, the CSM product stream has
been fully installed and configured. Refer to the [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.06`](http://www.hpe.com/support/ex-gsg-042120221040) for more information on other product streams
to be installed and configured after CSM.

See [Install CSM](../install/index.md) for the details on the installation process for either a first time install
or a reinstall.

<a name="upgrade"></a>
## Upgrade

   The upgrade from Shasta v1.4.2 (including CSM 0.9.3) to Shasta v1.5 (including CSM 1.0) is supported.
   This process will upgrade the Ceph storage software, then the storage nodes, then the Kubernetes master nodes and worker nodes,
   and finally the CSM services. The management nodes are upgraded using a rolling upgrade approach which enables
   management services to continue to function even as one or a few nodes are being upgraded.

   See [Upgrade CSM](../upgrade/index.md).

<a name="migration"></a>
## Migration

There is no direct migration from Shasta v1.3.x releases to Shasta v1.5. However, there is a supported path.

  * Migration from v1.3.x to v1.4.0

    The migration from v1.3.x to v1.4.0 is described in the Shasta v1.4 documentation.
    Refer to "1.3 to 1.4 Install Prerequisites" and "Collect Data From Healthy Shasta 1.3 System for EX 1.4 Installation" in the _HPE Cray EX System Installation and Configuration Guide 1.4 S-8000_.

  * Upgrade v1.4.x to v1.5

    An upgrade from the previous release (Shasta v1.4.x) is supported with this release.

    See [Upgrade from 1.4.x to v1.5](../upgrade/index.md)

