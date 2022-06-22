# Install CSM

## Abstract

Installation of the CSM product stream has many steps in multiple procedures which should be done in a
specific order. Information about the HPE Cray EX system and the site is used to prepare the configuration
payload. The initial node used to bootstrap the installation process is called the PIT node because the
Pre-Install Toolkit (PIT) is installed there.

Once the management network switches have been configured, the other
management nodes can be deployed with an operating system and the software to create a Kubernetes cluster
utilizing Ceph storage. The CSM services provide essential software infrastructure including the API gateway
and many micro-services with REST APIs for managing the system. Once administrative access has been configured,
the installation of CSM software can be validated with health checks before doing operational tasks
like the checking and updating of firmware on system components or the preparation of compute nodes.

Once the CSM installation has completed, other product streams for the HPE Cray EX system can be installed.

## Topics

1. [Preparing for a Re-installation](#preparing-for-a-re-installation)
1. [Pre-Installation](#pre-installation)
   1. [Boot Installation Environment](#1-boot-installation-environment)
   1. [Import CSM Tarball](#2-import-csm-tarball)
   1. [Create System Configuration](#3-create-system-configuration)
   1. [Configure Management Network Switches](#4-configure-management-network-switches)
   1. [Identify Inventory](#5-identify-inventory)
1. [Installation](#installation)
    1. [Deploy Management Nodes](#1-deploy-management-nodes)
    1. [Install CSM Services](#2-install-csm-services)
    1. [Validate CSM Health Before Final NCN Deployment](#3-validate-csm-health-before-final-ncn-deployment)
    1. [Deploy Final NCN](#4-deploy-final-ncn)
    1. [Configure Administrative Access](#5-configure-administrative-access)
    1. [Validate CSM Health](#6-validate-csm-health)
    1. [Configure Prometheus Alert Notifications](#7-configure-prometheus-alert-notifications)
    1. [Update Firmware with FAS](#8-update-firmware-with-fas)
    1. [Prepare Compute Nodes](#9-prepare-compute-nodes)
1. [Next Topic](#next-topic)
1. [Troubleshooting Installation Problems](#troubleshooting-installation-problems)

The topics in this chapter need to be done as part of an ordered procedure so are shown here with numbered topics.

> **`NOTE`** If problems are encountered during the installation, some topics have their own [troubleshooting sections found in the operations index](../operations/README.md)
sections, but there is also a general troubleshooting topic.

# Preparing for a Re-installation

If one is reinstalling a system, the existing cluster needs to be wiped and powered down.

See [Prepare Management Nodes](re-installation.md), and then come back and proceed
to the [Pre-Installation](#pre-installation) guide.

# Pre-Installation

These steps walk the user through properly setting up a CRAY supercomputer for an installation.

See [pre-installation](./pre-installation.md).

## 1. Boot Installation Environment

See [boot installation environment](./pre-installation.md#1-boot-installation-environment).

## 2. Import CSM Tarball

See [import CSM tarball](./pre-installation.md#2-import-csm-tarball).

## 3. Create System Configuration

See [create system configuration](./pre-installation.md#3-create-system-configuration).

## 4. Configure Management Network Switches

At this point external connectivity has been established, and either bare-metal configs can be installed or new configs can be applied.

See [Management Network User Guide](../operations/network/management_network/README.md).

## 5. Identify Inventory

At this point inventory can be identified. This is important for validating the SHCD. Specifically 
BMCs will be located, interrogated, and their node types identified.

**This section is not yet complete and exists as a placeholder, pleaes move onto [Installation](#installation).**

**`TODO: Add page for identification.`**
See []().

### Find Expected BMCs

**`TODO: Add page for detailing identification.`** 
See []().

### Boot Identified BMCs

**`TODO: Add page for detailing boot directions with the ephemeral discovery ROM.`** 
See []().

# Installation

## 1. Deploy Management Nodes

The first nodes to deploy are the NCNs. These will host CSM services that are required for deploying the rest of the supercomputer.

See [Deploy Management Nodes](deploy_non-compute_nodes.md).

> **`NOTE`** The PIT node will join Kubernetes after it is rebooted later in
[Deploy Final NCN](#4-deploy-final-ncn).

## 2. Install CSM Services

Now that deployment of management nodes is complete with initialized Ceph storage and a running Kubernetes
cluster on all worker and master nodes, except the PIT node, the CSM services can be installed. The Nexus
repository will be populated with artifacts; containerized CSM services will be installed; and a few other configuration steps taken.

See [Install CSM Services](install_csm_services.md).

## 3. Validate CSM Health Before Final NCN Deployment

After installing all of the CSM services, now validate the health of the management nodes and all CSM services.
The reason to do it now is that if there are any problems detected with the core infrastructure or the nodes, it is
easy to rewind the installation to [Deploy Management Nodes](#1-deploy-management-nodes) because the PIT node has not
yet been redeployed. In addition, redeploying the PIT node successfully requires several CSM services to be working
properly, so validating this is important.

See [Validate CSM Health](../operations/validate_csm_health.md).

## 4. Deploy Final NCN

Now that all CSM services have been installed and the CSM health checks completed, with the possible exception
of Booting the CSM Barebones Image and the UAS/UAI tests, the PIT node can be rebooted to leave the LiveCD
environment and assume its intended role as one the Kubernetes master nodes.

See [Deploy Final NCN](deploy_final_non-compute_node.md).

## 5. Configure Administrative Access

Now that all of the CSM services have been installed and the PIT node has been redeployed, administrative access
can be prepared. This may include configuring Keycloak with a local Keycloak account or confirming Keycloak
is properly federating LDAP or other Identity Provider (IdP), initializing the 'cray' CLI for administrative
commands, locking the management nodes from accidental actions such as firmware updates by FAS or power actions by
CAPMC, configuring the CSM layer of configuration by CFS in NCN personalization,and configuring the node BMCs (node
controllers) for nodes in liquid cooled cabinets.

See [Configure Administrative Access](configure_administrative_access.md).

## 6. Validate CSM Health

Now that all management nodes have joined the Kubernetes cluster, CSM services have been installed,
and administrative access has been enabled, the health of the management nodes and all CSM services
should be validated. There are no exceptions to running the tests--all can be run now.

This CSM health validation can also be run at other points during the system lifecycle, such as when replacing
a management node, checking the health after a management node has rebooted because of a crash, as part of doing
a full system power down or power up, or after other types of system maintenance.

See [Validate CSM Health](../operations/validate_csm_health.md).

## 7. Configure Prometheus Alert Notifications

Now that CSM has been installed and health has been validated, if the system management health monitoring tools and specifically,
Prometheus, are found to be useful, email notifications can be configured for specific alerts defined in Prometheus.
Prometheus upstream documentation can be leveraged for an [Alert Notification Template Reference](https://prometheus.io/docs/alerting/latest/notifications/)
as well as [Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/). Currently supported notification
types include Slack, Pager Duty, email, or a custom integration via a generic webhook interface.

See [Configure Prometheus Email Alert Notifications](../operations/system_management_health/Configure_Prometheus_Email_Alert_Notifications.md) for example
configuration of an email alert notification for Postgres replication alerts that are defined on the system.

## 8. Update Firmware with FAS

Now that all management nodes and CSM services have been validated as healthy, the firmware on other
components in the system can be checked and updated. The Firmware Action Service (FAS) communicates
with many devices on the system. FAS can be used to update the firmware for all of the devices it
communicates with at once, or specific devices can be targeted for a firmware update.

> **IMPORTANT:**
>  Before FAS can be used to update firmware, refer to the 1.5 _HPE Cray EX System Software Getting Started Guide S-8000_
>  on the HPE Customer Support Center at https://www.hpe.com/support/ex-gsg for more information about how to install
>  the HPE Cray EX HPC Firmware Pack (HFP) product. The installation of HFP will inform FAS of the newest firmware
>  available. Once FAS is aware that new firmware is available, then see
>  [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md).

## 9. Prepare Compute Nodes

After completion of the firmware update with FAS, compute nodes can be prepared. Some compute node
types have special preparation steps, but most compute nodes are ready to be used now.

These compute node types require preparation.
   * HPE Apollo 6500 XL645d Gen10 Plus
   * Gigabyte

See [Prepare Compute Nodes](prepare_compute_nodes.md).

# Next Topic

After completion of the firmware update with FAS and the preparation of compute nodes, the CSM product stream has
been fully installed and configured. Refer to the _HPE Cray EX System Software Getting Started Guide S-8000_
on the HPE Customer Support Center at https://www.hpe.com/support/ex-gsg for more information on other product streams to be installed and configured after CSM.

# Troubleshooting Installation Problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM install
for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

See [Troubleshooting Installation Problems](troubleshooting_installation.md).
