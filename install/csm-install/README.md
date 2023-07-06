# CSM Installation

## High-level overview of CSM install

In the [Pre-installation](#pre-installation) section of the install, information about the HPE Cray
EX system and the site is used to prepare the configuration payload. An initial node called the PIT
node is then set up to bootstrap the installation process. It is called the PIT node because the
Pre-Install Toolkit is installed there. The management network switches are also configured in this
section.

In the [Installation](#installation) section of the install, the other management nodes are deployed
with an operating system and the software required to create a Kubernetes cluster utilizing Ceph
storage. The CSM services are then deployed in the Kubernetes cluster to provide essential software
infrastructure including the API gateway and many micro-services with REST APIs for managing the
system. Administrative access is then configured, and the health of the system is validated before
proceeding with operational tasks like checking and updating firmware on system components and
preparing compute nodes.

The [Post-installation](#post-installation) section covers tasks which are performed after the
main install procedure is completed.

The final section, [Installation of additional HPE Cray EX software products](#installation-of-additional-hpe-cray-ex-software-products)
describes how to install additional HPE Cray EX software products using the Install and Upgrade
Framework (IUF).

## Topics

The topics in this chapter need to be done as part of an ordered procedure so are
shown here with numbered topics.

1. [Pre-installation](#pre-installation)
    1. [Preparing for a re-installation](#1-preparing-for-a-re-installation)
    1. [Boot installation environment](#2-boot-installation-environment)
    1. [Import CSM tarball](#3-import-csm-tarball)
    1. [Create system configuration](#4-create-system-configuration)
    1. [Configure management network switches](#5-configure-management-network-switches)
        1. [Management network](#management-network)
        1. [Ensure SNMP is configured on the management network switches](#ensure-snmp-is-configured-on-the-management-network-switches)
1. [Installation](#installation)
    1. [Deploy management nodes](#1-deploy-management-nodes)
    1. [Install CSM services](#2-install-csm-services)
    1. [Validate CSM health before final NCN deployment](#3-validate-csm-health-before-final-ncn-deployment)
    1. [Deploy final NCN](#4-deploy-final-ncn)
    1. [Configure administrative access](#5-configure-administrative-access)
    1. [Validate CSM health](#6-validate-csm-health)
    1. [Configure Prometheus alert notifications](#7-configure-prometheus-alert-notifications)
    1. [Upload Olympus BMC recovery firmware into TFTP server](#8-upload-olympus-bmc-recovery-firmware-into-tftp-server)
    1. [Update firmware with FAS](#9-update-firmware-with-fas)
    1. [Prepare compute nodes](#10-prepare-compute-nodes)
    1. [Troubleshooting installation problems](#11-troubleshooting-installation-problems)
1. [Post-Installation](#post-installation)
    1. [Kubernetes encryption](#1-kubernetes-encryption)
    1. [Export Nexus data](#2-export-nexus-data)
1. [Installation of additional HPE Cray EX software products](#installation-of-additional-hpe-cray-ex-software-products)

> **`NOTE`** If problems are encountered during the installation,
> [Troubleshooting installation problems](#11-troubleshooting-installation-problems) and
> [Cray System Management (CSM) Administration Guide](../../operations/README.md) will offer assistance.

## Pre-installation

This section will guide the administrator through creating and setting up the Cray Pre-Install Toolkit (PIT).

Fresh-installations may start at the [Boot installation environment](#2-boot-installation-environment) section. Re-installations will have other steps to complete in the [Preparing for a re-installation](#1-preparing-for-a-re-installation) section.

### 1. Preparing for a re-installation

If one is reinstalling a system, the existing cluster needs to be wiped and powered down.

See [Prepare Management Nodes](../re-installation.md), and then come back and proceed
to the [Pre-Installation](#pre-installation) guide.

These steps walk the user through properly setting up an HPE Cray supercomputer for an installation.

See [Pre-installation](../pre-installation.md).

### 2. Boot installation environment

See [Boot installation environment](../pre-installation.md#1-boot-installation-environment).

### 3. Import CSM tarball

See [Import CSM tarball](../pre-installation.md#2-import-csm-tarball).

### 4. Create system configuration

See [Create system configuration](../pre-installation.md#3-create-system-configuration).

### 5. Configure management network switches

#### Management network

***Prerequisites***

1. External connectivity has been established, and either bare-metal configurations can be installed or new/updated configurations can be applied.
1. Validate SHCD and cabling
1. Create custom CANU configurations and store them in version control. ***At a minimum:***
    1. Create an [SNMP](#when-the-management-network-has-not-been-configured) configuration; see the detailed SNMP section below.
    1. Add configuration for site uplinks [CANU custom configuration](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/custom_config.md)

If you have already validated SHCD, cabling and have created the required custom configurations and are comfortable with all steps of the network installation you can use the [Quick Management Network Install Guide](../../operations/network/management_network/quick_management_network_install_guide.md).

> ***IMPORTANT*** Otherwise, please refer to the ***Management Network User Guide***; i.e. if you have ***not***
> validated your SHCD and cabling in prior or have a more complex installation that requires special configuration before
> proceeding with the network installation. Topic "install scenarios" contains more in depth instructions.

***Additional documentation:***

* [Management Network User Guide](../../operations/network/management_network/README.md)
* [CANU documentation](../../operations/network/management_network/canu/README.md)

#### Ensure SNMP is configured on the management network switches
<!-- snmp-authentication-tag -->
<!-- When updating this information, search the docs for the snmp-authentication-tag to find related content -->
<!-- These comments can be removed once we adopt HTTP/lw-dita/Generated docs with re-usable snippets -->

<!-- markdownlint-disable-next-line MD036 MD026 -->
**IMPORTANT**

The REDS hardware discovery process, PCS/RTS management switch availability monitoring, and the
Prometheus SNMP Exporter depend on SNMP. To ensure that these services function correctly, validate
the SNMP settings in the system to ensure that the management network switches have SNMP enabled and
that the SNMP credentials configured on the switches match the credentials stored in Vault and
`customizations.yaml`.

If SNMP is misconfigured, then REDS hardware discovery, PCS/RTS management switch availability monitoring,
and the Prometheus SNMP Exporter may fail to operate correctly. For more information, see
[Configure SNMP](../../operations/network/management_network/configure_snmp.md).

##### When the management network is already configured

If CSM is being installed to an environment that already has a working management network (such as during a
reinstall), then validate that the SNMP credentials seeded into `customizations.yaml` in the previous
[Create Baseline System Customization](../prepare_site_init.md#3-create-baseline-system-customizations) step
of the install matches the SNMP password configured on the management network switches.

If the passwords do not match, then either update `customizations.yaml` to match the switches, or change the
switches to match `customizations.yaml`. For procedures for either option, see
[Configure SNMP](../../operations/network/management_network/configure_snmp.md).

Note: While the [Cray Automated Networking Utility (CANU)](../../operations/network/management_network/canu/README.md)
will typically not overwrite SNMP settings that are manually applied to the management switches, there are certain
cases where SNMP configuration can be over-written or lost (such as when resetting and reconfiguring a switch from
factory defaults). To persist the SNMP settings, see
[CANU Custom Configuration](../../operations/network/management_network/canu/custom_config.md).
CANU custom configuration files are used to persist site management network configurations that are
intended to take precedence over configurations generated by CANU.

##### When the management network has not been configured

Create a [CANU custom configuration](../../operations/network/management_network/canu/custom_config.md) that
configures SNMP on the management network switches, using the same credentials that were previously used in
the [Create Baseline System Customization](../prepare_site_init.md#3-create-baseline-system-customizations)
page of the installation. Use this custom configuration with CANU in the next step of the install.

Store the custom configuration in a version control repository along with other configuration assets from
the CSM install.

See [Configure SNMP](../../operations/network/management_network/configure_snmp.md) for more information about
configuring SNMP in CSM.

## Installation

## 1. Deploy management nodes

The first nodes to deploy are the NCNs. These will host CSM services that are required for deploying the rest of the supercomputer.

See [Deploy Management Nodes](../deploy_non-compute_nodes.md).

> **`NOTE`** The PIT node will join Kubernetes after it is rebooted later in [Deploy final NCN](#4-deploy-final-ncn).

### 2. Install CSM services

Now that deployment of management nodes is complete with initialized Ceph storage and a running Kubernetes cluster on all worker and master nodes, except the PIT node,
the CSM services can be installed. The Nexus repository will be populated with artifacts; containerized CSM services will be installed; and a few other configuration steps will be taken.

See [Install CSM Services](../install_csm_services.md).

### 3. Validate CSM health before final NCN deployment

After installing all of the CSM services, now validate the health of the management nodes and all CSM services. The reason to do it now is that if there are any
problems detected with the core infrastructure or the nodes, it is easy to rewind the installation to [Deploy management nodes](#1-deploy-management-nodes), because
the final NCN has not yet been deployed. In addition, deploying the final NCN successfully requires several CSM services to be working properly.

See [Validate CSM Health](../../operations/validate_csm_health.md).

### 4. Deploy final NCN

Now that all CSM services have been installed and the CSM health checks completed, with the possible exception of Booting the CSM Barebones Image and the UAS/UAI tests, the PIT has served its purpose and the final NCN can be deployed.
The node used for the PIT will be rebooted, this node will be the final NCN to deploy in the CSM install.

See [Deploy Final NCN](../deploy_final_non-compute_node.md).

### 5. Configure administrative access

Now that all of the CSM services have been installed and the final NCN has been deployed, administrative access can be prepared. This may include configuring Keycloak
with a local Keycloak account or confirming that Keycloak is properly federating LDAP or another Identity Provider (IdP), initializing the `cray` CLI for
administrative commands, locking the management nodes from accidental actions such as firmware updates by FAS or power actions by PCS/CAPMC, configuring the CSM layer
of configuration by CFS in NCN personalization, and configuring the node BMCs (node controllers) for nodes in liquid-cooled cabinets.

See [Configure Administrative Access](../configure_administrative_access.md).

### 6. Validate CSM health

Now that all management nodes have joined the Kubernetes cluster, CSM services have been installed, and administrative access has been enabled, the health of the
management nodes and all CSM services should be validated. There are no exceptions to running the tests--all can be run now.

This CSM health validation can also be run at other points during the system lifecycle, such as when replacing a management node, checking the health after a
management node has rebooted because of a crash, as part of doing a full system power down or power up, or after other types of system maintenance.

See [Validate CSM Health](../../operations/validate_csm_health.md).

### 7. Configure Prometheus alert notifications

Now that CSM has been installed and health has been validated, if the system management health monitoring tools (specifically Prometheus) are found to be useful, then
email notifications can be configured for specific alerts defined in Prometheus.
Prometheus upstream documentation can be leveraged for an [Alert Notification Template Reference](https://prometheus.io/docs/alerting/latest/notifications/) as well as
[Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/). Currently supported notification types include Slack, Pager Duty, email, or a custom integration via a generic webhook interface.

See [Configure Prometheus Email Alert Notifications](../../operations/system_management_health/Configure_Prometheus_Email_Alert_Notifications.md)
for an example configuration of an email alert notification for the Postgres replication alerts that are defined on the system.

### 8. Upload Olympus BMC recovery firmware into TFTP server

> **IMPORTANT:** Before Firmware can be updated the HPC Firmware Pack (HFP) must be installed  refer to the [HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
>on the HPE Customer Support Center for more information about how to install the HPE Cray EX HPC Firmware Pack (HFP) product.

The Olympus hardware needs to have recovery firmware loaded to the `cray-tftp` server in case the BMC loses its firmware. The BMCs are configured to load a recovery firmware from a TFTP server.
This procedure does not modify any BMC firmware, but only stages the firmware on the TFTP server for download in the event it is needed.

See [Load Olympus BMC Recovery Firmware into TFTP server](../../operations/firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md).

## 9. Update firmware with FAS

Now that all management nodes and CSM services have been validated as healthy, the firmware on other components in the system can be checked and updated. The Firmware Action Service (FAS) communicates with many devices on the system.
FAS can be used to update the firmware for all of the devices it communicates with at once, or specific devices can be targeted for a firmware update.

See [Update Firmware with FAS](../../operations/firmware/Update_Firmware_with_FAS.md).

### 10. Prepare compute nodes

After completion of the firmware update with FAS, compute nodes can be prepared. Some compute node types have special preparation steps, but most compute nodes are ready to be used now.

These compute node types require preparation:

* HPE Apollo 6500 XL645d Gen10 Plus
* Gigabyte

See [Prepare Compute Nodes](../prepare_compute_nodes.md).

### 11. Troubleshooting installation problems

The installation of the CSM product requires knowledge of the various nodes and switches for the HPE Cray EX system.
The procedures in this section should be referenced during the CSM install for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

See [Troubleshooting Installation Problems](../troubleshooting_installation.md).

## Post-Installation

### 1. Kubernetes encryption

As an optional post installation task, encryption of Kubernetes secrets may be enabled. This enables at rest encryption of data in the `etcd` database used by Kubernetes.

See [Kubernetes Encryption](../../operations/kubernetes/encryption/README.md).

### 2. Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable.

After the install, it is recommended that a Nexus export is taken. This is not a required step but highly recommend to protect the data in Nexus.

See [Nexus Export and Restore Procedure](../../operations/package_repository_management/Nexus_Export_and_Restore.md) for details.

## Installation of additional HPE Cray EX software products

Once installation of CSM has been completed, additional HPE Cray EX software products can be installed
via the Install and Upgrade Framework (IUF).

See the [Install or upgrade additional products with IUF](../../operations/iuf/workflows/install_or_upgrade_additional_products_with_iuf.md)
procedure to continue with the installation of additional HPE Cray EX software products.

For additional information on the IUF, see [Install and Upgrade Framework](../../operations/iuf/IUF.md).
