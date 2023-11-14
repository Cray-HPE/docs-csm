# Install CSM

Note: If installing CSM 1.2.0, then in order to avoid performing a patch update later, instead install the latest released CSM 1.2.x version.

## Abstract

Installation of the CSM product stream has many steps in multiple procedures which should be done in a
specific order. Information about the HPE Cray EX system and the site is used to prepare the configuration
payload. The initial node used to bootstrap the installation process is called the PIT node because the
[Pre-Install Toolkit (PIT)](../glossary.md#pre-install-toolkit-pit) is installed there.

Once the management network switches have been configured, the other
management nodes can be deployed with an operating system and the software to create a Kubernetes cluster
utilizing Ceph storage. The CSM services provide essential software infrastructure including the API gateway
and many micro-services with REST APIs for managing the system. Once administrative access has been configured,
the installation of CSM software can be validated with health checks before doing operational tasks
like the checking and updating of firmware on system components or the preparation of compute nodes.

Once the CSM installation has completed, other product streams for the HPE Cray EX system can be installed.

A major feature of CSM 1.2 is the [Bifurcated CAN (BICAN)](../glossary.md#bifurcated-can-bican).
The BICAN is designed to separate administrative network traffic from user network traffic.
More information can be found on the [BICAN Technical Summary](../operations/network/management_network/bican_technical_summary.md).
Review the BICAN summary before continuing with the CSM install.
For detailed BICAN documentation, see [BICAN Technical Details](../operations/network/management_network/bican_technical_details.md).

<a name="troubleshooting_installation"></a>

## Troubleshooting installation problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system.

For additional installation-specific troubleshooting information, see
[Troubleshooting Installation Problems](troubleshooting_installation.md).
Some topics also have supplementary troubleshooting sections listed in the CSM [Operations index](../operations/index.md).

## Overview

The topics in this chapter need to be done as part of an ordered procedure so are shown here with numbered topics.

1. [Validate SHCD](#validate_shcd)
1. [Prepare configuration payload](#prepare_configuration_payload)
1. [Prepare management nodes](#prepare_management_nodes)
1. [Bootstrap PIT node](#bootstrap_pit_node)
1. [Configure management network switches](#configure_management_network)
1. [Collect MAC addresses for NCNs](#collect_mac_addresses_for_ncns)
1. [Deploy management nodes](#deploy_management_nodes)
1. [Install CSM services](#install_csm_services)
1. [Validate CSM health](#validate_csm_health_before_final_ncn_deploy)
1. [Deploy final NCN](#deploy_final_ncn)
1. [Configure administrative access](#configure_administrative_access)
1. [Validate CSM health](#validate_csm_health)
1. [Configure Prometheus alert notifications](#configure_prometheus_alert_notifications)
1. [Update firmware with FAS](#update_firmware_with_fas)
1. [Prepare compute nodes](#prepare_compute_nodes)
1. [Apply security hardening](#apply_security_hardening)
1. [Next topic](#next_topic)

## Procedure

<a name="validate_shcd"></a>

1. Validate SHCD

   The cabling should be validated between the nodes and the management network switches. The information in the
   [Shasta Cabling Diagram (SHCD)](../glossary.md#shasta-cabling-diagram) can be used to confirm the cables which physically connect components of the system.
   Having the data in the SHCD which matches the physical cabling will be needed later in both
   [Prepare configuration payload](#prepare_configuration_payload) and [Configure management network switches](#configure_management_network).

   See [Validate SHCD](../operations/network/management_network/validate_shcd.md).

   **Note**: If a reinstall or fresh install of this software release is being done on this system and the management
   network cabling has already been validated, then skip this step and move to
   [Prepare configuration payload](#prepare_configuration_payload).
   <a name="prepare_configuration_payload"></a>

1. Prepare configuration payload

   Information gathered from a site survey is needed to feed into the CSM installation process, such as system name,
   system size, site network information for the [Customer Access Network (CAN)](../glossary.md#customer-access-network-can),
   site DNS configuration, site NTP configuration, network
   information for the node used to bootstrap the installation. Much of the information about the system hardware
   is encapsulated in the SHCD (Shasta Cabling Diagram), which is a spreadsheet prepared by HPE Cray Manufacturing
   to assemble the components of the system and connect appropriately labeled cables.

   See [Prepare Configuration Payload](prepare_configuration_payload.md)
   <a name="prepare_management_nodes"></a>

1. Prepare management nodes

   Some preparation of the management nodes might be needed before starting an install or reinstall.
   The preparation includes checking and updating the firmware on the PIT node, quiescing the compute nodes
   and application nodes, scaling back DHCP on the management nodes, wiping the storage on the management nodes,
   powering off the management nodes, and possibly powering off the PIT node.

   See [Prepare Management Nodes](prepare_management_nodes.md).
   <a name="bootstrap_pit_node"></a>

1. Bootstrap PIT node

   The Pre-Install Toolkit (PIT) node needs to be bootstrapped from the LiveCD. There are two media available
   to bootstrap the PIT node -- the RemoteISO or a bootable USB device. The recommended media is the RemoteISO,
   because it does not require any physical media to prepare. However, remotely mounting an ISO on a
   [BMC](../glossary.md#baseboard-management-controller-bmc) does not work smoothly for nodes from all vendors.
   It is recommended to try the RemoteISO first.

   Use one of these procedures to bootstrap the PIT node from the LiveCD:

   * [Bootstrap PIT Node from LiveCD Remote ISO](bootstrap_livecd_remote_iso.md) (recommended)
     * **Gigabyte BMCs** should not use the RemoteISO method.
     * **Intel BMCs** should not use the RemoteISO method.
   * [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md) (fallback)

   Using the LiveCD USB method requires a USB 3.0 device with at least 1TB of space to create a bootable LiveCD.
   <a name="configure_management_network"></a>

1. Configure management network switches

   Now that the PIT node has been booted with the LiveCD environment and [Cray Site Init (CSI)](../glossary.md#cray-site-init-csi)
   has generated the switch IP addresses, the management network switches can be configured.

   See [Management Network User Guide](../operations/network/management_network/index.md).

   **Note**: If a reinstall of this software release is being done on this system and the management network switches
   have already been configured, then skip this step and move to
   [Collect MAC addresses for NCNs](#collect_mac_addresses_for_ncns).
   <a name="collect_mac_addresses_for_ncns"></a>

1. Collect MAC addresses for NCNs

   Now that the PIT node has been booted with the LiveCD and the management network switches have been configured,
   the actual MAC address for the management nodes can be collected. This process will include repetition of some
   of the steps done up to this point because `csi config init` will need to be run with the proper
   MAC addresses.

   See [Collect MAC Addresses for NCNs](collect_mac_addresses_for_ncns.md).

   **Note**: If a reinstall of this software release is being done on this system and the `ncn_metadata.csv`
   file already had valid MAC addresses for both BMC and node interfaces before `csi config init` was run, then
   this topic could be skipped and instead move to [Deploy management nodes](#deploy_management_nodes).

   **Note**: If a first time install of this software release is being done on this system and the `ncn_metadata.csv`
   file already had valid MAC addresses for both BMC and node interfaces before `csi config init` was run, then
   this topic could be skipped and instead move to [Deploy management nodes](#deploy_management_nodes).
   <a name="deploy_management_nodes"></a>

1. Deploy management nodes

   Now that the PIT node has been booted with the LiveCD and the management network switches have been configured,
   the other management nodes can be deployed. This procedure will boot all of the management nodes, initialize
   Ceph storage on the storage nodes and start the Kubernetes cluster on all of the worker nodes and the master nodes,
   except for the PIT node. The PIT node will join Kubernetes after it is rebooted later in
   [Deploy final NCN](#deploy_final_ncn).

   See [Deploy Management Nodes](deploy_management_nodes.md).
   <a name="install_csm_services"></a>

1. Install CSM services

   Deployment of management nodes is complete with initialized Ceph storage and a running Kubernetes
   cluster on all worker and master nodes, except the PIT node. The Nexus
   repository will be populated with artifacts, containerized CSM services will be installed, and a few other configuration steps will be taken.

   See [Install CSM Services](install_csm_services.md).
   <a name="validate_csm_health_before_final_ncn_deploy"></a>

1. Validate CSM health

   Validate the health of the management nodes and all CSM services.
   The reason to do it now is that if there are any problems detected with the core infrastructure or the nodes, it is
   easy to rewind the installation to [Deploy management nodes](#deploy_management_nodes), because the PIT node has not
   yet been rebooted. In addition, rebooting the PIT node and deploying the final NCN successfully requires several CSM
   services to be working properly, so validating this is important.

   See [Validate CSM Health](../operations/validate_csm_health.md).
   <a name="deploy_final_ncn"></a>

1. Deploy final NCN

   Now that all CSM services have been installed and the CSM health checks completed, with the possible exception of the
   [User Access Service (UAS)](../glossary.md#user-access-service-uas)/[User Access Instance (UAI)](../glossary.md#user-access-instance-uai) tests,
   the PIT node can be rebooted to leave the LiveCD environment and assume its intended role as one the Kubernetes master nodes.

   See [Deploy Final NCN](deploy_final_ncn.md).
   <a name="configure_administrative_access"></a>

1. Configure administrative access

   Now that all of the CSM services have been installed and the final NCN has been deployed, administrative access can be prepared.
   This may include:

   * Configuring Keycloak with a local Keycloak account or confirming that Keycloak is properly federating LDAP or another Identity Provider (IdP)
   * Initializing the [Cray CLI (`cray`)](../glossary.md#cray-cli-cray) for administrative commands
   * Locking the management nodes from accidental actions such as firmware updates by [Firmware Action Service (FAS)](../glossary.md#firmware-action-service-fas)
     or power actions by [Cray Advanced Platform Monitoring and Control (CAPMC)](../glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
   * Configuring the CSM layer of configuration by [Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs) in NCN personalization
   * Configuring the node [BMCs](../glossary.md#baseboard-management-controller-bmc) ([node controllers](../glossary.md#node-controller-nc))
     for nodes in liquid-cooled cabinets

   See [Configure Administrative Access](configure_administrative_access.md).
   <a name="validate_csm_health"></a>

1. Validate CSM health

   Now that all management nodes have joined the Kubernetes cluster, CSM services have been installed,
   and administrative access has been enabled, the health of the management nodes and all CSM services
   should be validated. There are no exceptions to running the tests -- all tests should be run now.

   This CSM health validation can also be run at other points during the system lifecycle, such as when replacing
   a management node, checking the health after a management node has rebooted because of a crash, as part of doing
   a full system power down or power up, or after other types of system maintenance.

   See [Validate CSM Health](../operations/validate_csm_health.md).
   <a name="configure_prometheus_alert_notifications"></a>

1. Configure Prometheus alert notifications

   Now that CSM has been installed and health has been validated, if the system management health monitoring tools and specifically,
   Prometheus, are found to be useful, email notifications can be configured for specific alerts defined in Prometheus.
   Prometheus upstream documentation can be leveraged for an [Alert Notification Template Reference](https://prometheus.io/docs/alerting/latest/notifications/)
   as well as [Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/). Currently supported notification
   types include Slack, Pager Duty, email, or a custom integration via a generic webhook interface.

   See [Configure Prometheus Email Alert Notifications](../operations/system_management_health/Configure_Prometheus_Email_Alert_Notifications.md) for an example
   configuration of an email alert notification for the Postgres replication alerts that are defined on the system.
   <a name="update_firmware_with_fas"></a>

1. Update firmware with FAS

   Now that all management nodes and CSM services have been validated as healthy, the firmware on other
   components in the system can be checked and updated. The Firmware Action Service (FAS) communicates
   with many devices on the system. FAS can be used to update the firmware for all of the devices it
   communicates with at once, or specific devices can be targeted for a firmware update.

   **IMPORTANT:** Before FAS can be used to update firmware, refer to the
   [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.07`](http://www.hpe.com/support/ex-gsg-042120221040) for more information about how to install
   the HPE Cray EX HPC Firmware Pack (HFP) product. The installation of HFP will inform FAS of the newest firmware
   available. Once FAS is aware that new firmware is available, then see
   [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).
   <a name="prepare_compute_nodes"></a>

1. Prepare compute nodes

   After completion of the firmware update with FAS, compute nodes can be prepared. Some compute node
   types have special preparation steps, but most compute nodes are ready to be used now.

   These compute node types require preparation:

   * HPE Apollo 6500 XL645D Gen10 Plus
   * Gigabyte

   See [Prepare Compute Nodes](prepare_compute_nodes.md)
   <a name="apply_security_hardening"></a>

1. Apply security hardening

   After preparing compute nodes, and prior to the installation of other product streams, review the security hardening guide.

   See [Security Hardening](../operations/CSM_product_management/Apply_Security_Hardening.md)
   <a name="next_topic"></a>

1. Next topic

   After completion of the firmware update with FAS and the preparation of compute nodes, the CSM product stream has
   been fully installed and configured.
   Refer to the [`HPE Cray EX System Software Getting Started Guide (S-8000) 22.07`](http://www.hpe.com/support/ex-gsg-042120221040) on the HPE Customer Support Center
   for more information on other product streams to be installed and configured after CSM.
