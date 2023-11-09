# Cray System Management Install

This page will guide an administrator through installing Cray System Management (CSM) on an
HPE Cray EX system.

The CSM services provide essential software infrastructure including the API gateway
and many micro-services with REST APIs for managing the system.

Fresh-installations on bare-metal or re-installations of CSM must follow this guide in procedural
order.

After completing an installation, the CSM product's installed state will need to be validated
with various health checks before operational tasks or other product installs (such as
[Slingshot](../glossary.md#slingshot)) can commence.

Introduced in CSM 1.2, a major feature of CSM is the [Bifurcated CAN (BICAN)](../glossary.md#bifurcated-can-bican).
The BICAN is designed to separate administrative network traffic from user network traffic.
More information can be found on the [BICAN Technical Summary](../operations/network/management_network/bican_technical_summary.md).
Review the BICAN summary before continuing with the CSM install.
For detailed BICAN documentation, see [BICAN Technical Details](../operations/network/management_network/bican_technical_details.md).

## Topics

The topics in this chapter need to be done as part of an ordered procedure so are
shown here with numbered topics.

1. [Pre-installation](#pre-installation)
    1. [Preparing for a re-installation](#1-preparing-for-a-re-installation)
    1. [Boot installation environment](#2-boot-installation-environment)
    1. [Import CSM tarball](#3-import-csm-tarball)
    1. [Create system configuration](#4-create-system-configuration)
    1. [Configure management network switches](#5-configure-management-network-switches)
1. [Installation](#installation)
    1. [Deploy management nodes](#1-deploy-management-nodes)
    1. [Install CSM services](#2-install-csm-services)
    1. [Validate CSM health before final NCN deployment](#3-validate-csm-health-before-final-ncn-deployment)
    1. [Deploy final NCN](#4-deploy-final-ncn)
    1. [Configure administrative access](#5-configure-administrative-access)
    1. [Upgrade Ceph and stop local Docker registries](#6-upgrade-ceph-and-stop-local-docker-registries)
    1. [Validate CSM health](#7-validate-csm-health)
    1. [Configure Prometheus alert notifications](#8-configure-prometheus-alert-notifications)
    1. [Upload Olympus BMC recovery firmware into TFTP server](#9-upload-olympus-bmc-recovery-firmware-into-tftp-server)
    1. [Update firmware with FAS](#10-update-firmware-with-fas)
    1. [Prepare compute nodes](#11-prepare-compute-nodes)
    1. [Next topic](#12-next-topic)
    - [Troubleshooting installation problems](#troubleshooting-installation-problems)
1. [Post-installation](#post-installation)
    1. [Apply security hardening](#13-apply-security-hardening)
    1. [Export Nexus data](#14-export-nexus-data)

> **`NOTE`** If problems are encountered during the installation,
> [Troubleshooting installation problems](#troubleshooting-installation-problems) and
> [Cray System Management (CSM) Administration Guide](../operations/README.md) will offer assistance.

## Pre-installation

This section will guide the administrator through creating and setting up the
Cray Pre-Install Toolkit (PIT).

Fresh-installations may start at the
[Boot installation environment](#2-boot-installation-environment) section. Re-installations will
have other steps to complete in the
[Preparing for a re-installation](#1-preparing-for-a-re-installation) section.

### 1. Preparing for a re-installation

If one is reinstalling a system, the existing cluster needs to be wiped and powered down.

See [Prepare Management Nodes](re-installation.md), and then come back and proceed
to the [Pre-Installation](#pre-installation) guide.

These steps walk the user through properly setting up a Cray supercomputer for an installation.

See [Pre-installation](pre-installation.md).

### 2. Boot installation environment

See [Boot installation environment](pre-installation.md#1-boot-installation-environment).

### 3. Import CSM tarball

See [Import CSM tarball](pre-installation.md#2-import-csm-tarball).

### 4. Create system configuration

See [Create system configuration](pre-installation.md#3-create-system-configuration).

### 5. Configure management network switches

At this point external connectivity has been established, and either bare-metal configurations can
be installed or new/updated configurations can be applied.

See [Management Network User Guide](../operations/network/management_network/README.md).

## Installation

## 1. Deploy management nodes

The first nodes to deploy are the [management nodes](../glossary.md#management-nodes).
These [Non-Compute Nodes (NCNs)](../glossary.md#non-compute-node-ncn) will host CSM services that are required for deploying the rest of the supercomputer.

See [Deploy Management Nodes](deploy_non-compute_nodes.md).

> **`NOTE`** The PIT node will join Kubernetes after it is rebooted later in
[Deploy final NCN](#4-deploy-final-ncn).

### 2. Install CSM services

Now that deployment of management nodes is complete with initialized Ceph storage and a running Kubernetes
cluster on all worker and master nodes, except the PIT node, the CSM services can be installed. The Nexus
repository will be populated with artifacts; containerized CSM services will be installed; and a few other configuration steps will be taken.

See [Install CSM Services](install_csm_services.md).

### 3. Validate CSM health before final NCN deployment

After installing all of the CSM services, now validate the health of the management nodes and all CSM services.
The reason to do it now is that if there are any problems detected with the core infrastructure or the nodes, it is
easy to rewind the installation to [Deploy management nodes](#1-deploy-management-nodes), because the final
NCN has not yet been deployed. In addition, deploying the final NCN successfully requires several CSM services to be working
properly.

See [Validate CSM Health](../operations/validate_csm_health.md).

### 4. Deploy final NCN

Now that all CSM services have been installed and the CSM health checks completed, with the possible exception of the
[User Access Service (UAS)](../glossary.md#user-access-service-uas)/[User Access Instance (UAI)](../glossary.md#user-access-instance-uai) tests,
the PIT has served its purpose and the final NCN can be deployed. The node used for the PIT will be rebooted, this node will be the final NCN to deploy
in the CSM install.

See [Deploy Final NCN](deploy_final_non-compute_node.md).

### 5. Configure administrative access

Now that all of the CSM services have been installed and the final NCN has been deployed, administrative access can be prepared.
This may include:

- Configuring Keycloak with a local Keycloak account or confirming that Keycloak is properly federating LDAP or another Identity Provider (IdP)
- Initializing the [Cray CLI (`cray`)](../glossary.md#cray-cli-cray) for administrative commands
- Locking the management nodes from accidental actions such as firmware updates by [Firmware Action Service (FAS)](../glossary.md#firmware-action-service-fas)
  or power actions by [Cray Advanced Platform Monitoring and Control (CAPMC)](../glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
- Configuring the CSM layer of configuration by [Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs) in NCN personalization
- Configuring the node [BMCs](../glossary.md#baseboard-management-controller-bmc) ([node controllers](../glossary.md#node-controller-nc))
  for nodes in liquid-cooled cabinets

See [Configure Administrative Access](configure_administrative_access.md).

### 6. Upgrade Ceph and stop local Docker registries

> **IMPORTANT** If performing a fresh install of CSM 1.3.0, 1.3.1, 1.3.2, 1.3.3, or 1.3.4, then skip this procedure.
> This procedure should only be done during installs of CSM 1.3 patch version 1.3.5 or later.

Now that all management nodes have joined the Kubernetes cluster, Ceph should be upgraded local registries on storage nodes
should be stopped.

See [Upgrade Ceph and stop local docker registries](upgrade_ceph_stop_local_registries.md).

### 7. Validate CSM health

Now that all management nodes have joined the Kubernetes cluster, CSM services have been installed, and administrative access has been enabled, the health of the
management nodes and all CSM services should be validated. There are no exceptions to running the tests -- all tests should be run now.

This CSM health validation can also be run at other points during the system lifecycle, such as when replacing
a management node, checking the health after a management node has rebooted because of a crash, as part of doing
a full system power down or power up, or after other types of system maintenance.

See [Validate CSM Health](../operations/validate_csm_health.md).

### 8. Configure Prometheus alert notifications

Now that CSM has been installed and health has been validated, if the system management health monitoring tools (specifically Prometheus) are found to be useful, then
email notifications can be configured for specific alerts defined in Prometheus.
Prometheus upstream documentation can be leveraged for an [Alert Notification Template Reference](https://prometheus.io/docs/alerting/latest/notifications/)
as well as [Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/).
Currently supported notification types include Slack, Pager Duty, email, or a custom integration via a generic webhook interface.

See [Configure Prometheus Email Alert Notifications](../operations/system_management_health/Configure_Prometheus_Email_Alert_Notifications.md) for an example
configuration of an email alert notification for the Postgres replication alerts that are defined on the system.

### 9. Upload Olympus BMC recovery firmware into TFTP server

> **IMPORTANT:**
> Before Firmware can be updated the HPC Firmware Pack (HFP) must be installed  refer to the
> [HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
> on the HPE Customer Support Center for more information about how to install
> the HPE Cray EX HPC Firmware Pack (HFP) product.

The Olympus hardware needs to have recovery firmware loaded to the `cray-tftp` server in case the BMC loses its firmware.
The BMCs are configured to load a recovery firmware from a TFTP server.
This procedure does not modify any BMC firmware, but only stages the firmware on the TFTP server for download in the event it is needed.

See [Load Olympus BMC Recovery Firmware into TFTP server](../operations/firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md).

### 10. Update firmware with FAS

Now that all management nodes and CSM services have been validated as healthy, the firmware on other
components in the system can be checked and updated. The Firmware Action Service (FAS) communicates
with many devices on the system. FAS can be used to update the firmware for all of the devices it
communicates with at once, or specific devices can be targeted for a firmware update.

See [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md)

### 11. Prepare compute nodes

After completion of the firmware update with FAS, compute nodes can be prepared. Some compute node
types have special preparation steps, but most compute nodes are ready to be used now.

These compute node types require preparation:

- HPE Apollo 6500 XL645d Gen10 Plus
- Gigabyte

See [Prepare Compute Nodes](prepare_compute_nodes.md).

### 12. Next topic

After completion of the firmware update with FAS and the preparation of compute nodes, the CSM product stream has
been fully installed and configured.
Refer to the [HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000)
on the HPE Customer Support Center for more information on other product streams
to be installed and configured after CSM.

### Troubleshooting installation problems

The installation of the Cray System Management (CSM) product requires knowledge of the various nodes and
switches for the HPE Cray EX system. The procedures in this section should be referenced during the CSM install
for additional information on system hardware, troubleshooting, and administrative tasks related to CSM.

See [Troubleshooting Installation Problems](troubleshooting_installation.md).

## Post-installation

### 13. Apply security hardening

Review the security hardening guide, apply non-optional procedures, and review optional procedures.

See [Security Hardening](../operations/CSM_product_management/Apply_Security_Hardening.md).

### 14. Export Nexus data

**Warning:** This process can take multiple hours where Nexus is unavailable and should be done during scheduled maintenance periods.

Prior to the upgrade it is recommended that a Nexus export is taken. This is not a required step but highly recommend to protect the data in Nexus.
If there is no maintenance period available then this step should be skipped until after the upgrade process.

See [Nexus Export and Restore Procedure](../operations/package_repository_management/Nexus_Export_and_Restore.md) for details.
