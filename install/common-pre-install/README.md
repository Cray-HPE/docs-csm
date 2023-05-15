# Install CSM with Common Pre-installer (Tech Preview)

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

[Prerequisites](#prerequisites)

1. [Pre-installation](#pre-installation)  
    1. [Boot Pre-Install Live ISO and Seed Files Generation](#1-boot-pre-install-live-iso-and-seed-files-generation)
    1. [Preparing for a re-installation](#2-preparing-for-a-re-installation)
    1. [Boot installation environment](#3-boot-installation-environment)
    1. [Import CSM tarball](#4-import-csm-tarball)
    1. [Create system configuration](#5-create-system-configuration)
    1. [Configure management network switches](#6-configure-management-network-switches)
        1. [Ensure SNMP is configured on the management network switches](#ensure-snmp-is-configured-on-the-management-network-switches)
        1. [Configure the management network with CANU](#configure-the-management-network-with-canu)
1. [Installation](#installation)
    1. [Deploy management nodes](#1-deploy-management-nodes)
    1. [Install CSM services](#2-install-csm-services)
    1. [Validate CSM health before final NCN deployment](#3-validate-csm-health-before-final-ncn-deployment)
    1. [Deploy final NCN](#4-deploy-final-ncn)
    1. [Configure administrative access](#5-configure-administrative-access)
    1. [Validate CSM health](#6-validate-csm-health)
    1. [Configure Prometheus alert notifications](#7-configure-prometheus-alert-notifications)
    1. [Update firmware with FAS](#8-update-firmware-with-fas)
    1. [Prepare compute nodes](#9-prepare-compute-nodes)
    1. [Troubleshooting installation problems](#10-troubleshooting-installation-problems)
1. [Post-installation](#post-installation)
    1. [Kubernetes Encryption](#1-kubernetes-encryption)
    1. [Export Nexus Data](#2-export-nexus-data)
1. [Installation of additional HPE Cray EX software products](#installation-of-additional-hpe-cray-ex-software-products)

> **`NOTE:`** If problems are encountered during the installation,
> [Troubleshooting installation problems](#10-troubleshooting-installation-problems) and
> [Cray System Management (CSM) Administration Guide](../../operations/README.md) will offer assistance.

## Prerequisites

The following must be verified before starting the Pre-installation procedure:

- Ensure all the River Node BMCs are reachable and is set to DHCP mode. Refer to [Set node BMCs to DHCP](../re-installation.md#set-node-bmcs-to-dhcp).

  >**Note:** For bare-metal installation these settings will be default.

- Ensure that list of Management Switch IP address configured on `vlan1` is available, this need to be shared or will require serial console to the switches.

- Verify if the SHCD document is available with the component names (xnames) of server.

- Collect IP address of admin node, site DNS, gateway IP, and proxy details, and ensure all these IPs are reachable from admin node.

- Verify and ensure you have access to admin node and BMC.

- Verify and ensure you are able to download the `SLE-15-SP4-Full-x86_64` and `cm-admin-install-1.8-sles15sp4-x86_64.iso` ISO files and CSM tarball.

- Verify and ensure a minimum of 64GB memory is available for the admin node.

## Pre-installation

This section will guide the administrator through creating and setting up the Cray Pre-Install Toolkit (PIT).

Fresh-installations may start at the [Boot installation environment](#3-boot-installation-environment) section. Re-installations will have other steps to complete in the [Preparing for a re-installation](#2-preparing-for-a-re-installation) section.

### 1. Boot Pre-Install Live ISO and Seed Files Generation

This section will guide the administrator through installing HPCM to generate seed files. The seed files will be used later in the step of the CSM installation.

See [Boot Pre-Install Live ISO and Seed Files Generation](hpcm_installation-cpi.md).

### 2. Preparing for a re-installation

If one is reinstalling a system, the existing cluster needs to be wiped and powered down.

See [Prepare Management Nodes](../re-installation.md), and then come back and proceed to the [Pre-Installation](#pre-installation) guide.

These steps walk the user through properly setting up a Cray supercomputer for an installation.

See [Pre-installation](pre-installation-cpi.md).

### 3. Boot installation environment

See [Boot installation environment](pre-installation-cpi.md#1-boot-installation-environment).

### 4. Import CSM tarball

See [Import CSM tarball](pre-installation-cpi.md#2-import-csm-tarball).

### 5. Create system configuration

See [Create system configuration](pre-installation-cpi.md#3-create-system-configuration).

### 6. Configure management network switches

#### Ensure SNMP is configured on the management network switches
<!-- snmp-authentication-tag -->
<!-- When updating this information, search the docs for the snmp-authentication-tag to find related content -->
<!-- These comments can be removed once we adopt HTTP/lw-dita/Generated docs with re-usable snippets -->

<!-- markdownlint-disable-next-line MD036 MD026 -->
**IMPORTANT**

The REDS hardware discovery process, PCS/RTS management switch availability monitoring, and the
Prometheus SNMP Exporter depend on SNMP. To ensure that these services function correctly, validate
the SNMP settings in the system to ensure that the management network switches have SNMP enabled
and that the SNMP credentials configured on the switches match the credentials stored in Vault and
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

#### Configure the management network with CANU

At this point external connectivity has been established, and either bare-metal configurations can
be installed or new/updated configurations can be applied.

Most installations will require the following three tasks, although this may vary depending on
site-specific settings and procedures.

1. Create custom CANU configurations and store them in version control.
   At a minimum, create an SNMP configuration; see the SNMP section earlier on this page.
1. Apply the CANU-generated network configuration to the management switches.
   CANU can also be used to generate a new network configuration and report on the differences between it
   and the running switch configuration (useful when reinstalling CSM).

See [Management Network User Guide](../../operations/network/management_network/README.md) for information on next steps
for a variety of network configuration scenarios.

Note that the configuration of the management network is an advanced task that may require the help of a networking
subject matter expert.

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

Now that all CSM services have been installed and the CSM health checks completed, with the possible exception of Booting the CSM Barebones Image and the UAS/UAI tests,
the PIT has served its purpose and the final NCN can be deployed. The node used for the PIT will be rebooted, this node will be the final NCN to deploy in the CSM install.

See [Deploy Final NCN](../deploy_final_non-compute_node.md).

### 5. Configure administrative access

Now that all of the CSM services have been installed and the final NCN has been deployed, administrative access can be prepared.
This may include configuring Keycloak with a local Keycloak account or confirming that Keycloak is properly federating LDAP or another Identity Provider (IdP),
initializing the `cray` CLI for administrative commands, locking the management nodes from accidental actions such as firmware updates by FAS or power actions by
CAPMC, configuring the CSM layer of configuration by CFS in NCN personalization, and configuring the node BMCs (node controllers) for nodes in liquid-cooled cabinets.

See [Configure Administrative Access](../configure_administrative_access.md).

### 6. Validate CSM health

Now that all management nodes have joined the Kubernetes cluster, CSM services have been installed, and administrative access has been enabled,
the health of the management nodes and all CSM services should be validated. There are no exceptions to running the `tests--all` can be run now.

This CSM health validation can also be run at other points during the system lifecycle, such as when replacing a management node,
checking the health after a management node has rebooted because of a crash, as part of doing a full system power down or power up, or after other types of system maintenance.

See [Validate CSM Health](../../operations/validate_csm_health.md).

### 7. Configure Prometheus alert notifications

Now that CSM has been installed and health has been validated, if the system management health monitoring tools (specifically Prometheus) are found to be useful,
then email notifications can be configured for specific alerts defined in Prometheus.
Prometheus upstream documentation can be leveraged for an [Alert Notification Template Reference](https://prometheus.io/docs/alerting/latest/notifications/) as well as
[Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/).
Currently supported notification types include Slack, Pager Duty, email, or a custom integration via a generic webhook interface.

See [Configure Prometheus Email Alert Notifications](../../operations/system_management_health/Configure_Prometheus_Email_Alert_Notifications.md)
for an example configuration of an email alert notification for the Postgres replication alerts that are defined on the system.

### 8. Update firmware with FAS

Now that all management nodes and CSM services have been validated as healthy, the firmware on other components in the system can be checked and updated. The Firmware Action Service (FAS) communicates with many devices on the system.
FAS can be used to update the firmware for all of the devices it communicates with at once, or specific devices can be targeted for a firmware update.

See [Update Firmware with FAS](../../operations/firmware/Update_Firmware_with_FAS.md)

### 9. Prepare compute nodes

After completion of the firmware update with FAS, compute nodes can be prepared. Some compute node types have special preparation steps, but most compute nodes are ready to be used now.

These compute node types require preparation:

- HPE Apollo 6500 XL645d Gen10 Plus
- Gigabyte

See [Prepare Compute Nodes](../prepare_compute_nodes.md).

### 10. Troubleshooting installation problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and switches for the HPE Cray EX system.
The procedures in this section should be referenced during the CSM install for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

See [Troubleshooting Installation Problems](../troubleshooting_installation.md).

## Post-installation

### 1. Kubernetes encryption

As an optional post installation task, encryption of Kubernetes secrets may be enabled. This enables
at rest encryption of data in the `etcd` database used by Kubernetes.

See [Kubernetes Encryption](../../operations/kubernetes/encryption/README.md).

### 2. Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but highly recommend to protect the data in Nexus.
If there is no maintenance period available then this step should be skipped until after the upgrade process.

See [Nexus Export and Restore Procedure](../../operations/package_repository_management/Nexus_Export_and_Restore.md) for details.

## Installation of additional HPE Cray EX software products

Once installation of CSM has been completed, additional HPE Cray EX software products can be installed
via the Install and Upgrade Framework (IUF).

See the [Install or upgrade additional products with IUF](../../operations/iuf/workflows/install_or_upgrade_additional_products_with_iuf.md)
procedure to continue with the installation of additional HPE Cray EX software products.

For additional information on the IUF, see [Install and Upgrade Framework](../../operations/iuf/IUF.md).
