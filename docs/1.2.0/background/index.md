# CSM Background Information

This document provides background information about the NCNs (non-compute nodes) which function as
management nodes for the HPE Cray EX system. This information is not normally needed to install
software, but provides background which might be helpful for troubleshooting an installation.

### Topics:
   * [Cray Site Init Files](#cray_site_init_files)
   * [Certificate Authority](#certificate_authority)
   * [NCN Images](#ncn_images)
   * [NCN Boot Workflow](#ncn_boot_workflow)
   * [NCN Networking](#ncn_networking)
   * [NCN Mounts and File Systems](#ncn_mounts_and_file_systems)
   * [NCN Packages](#ncn_packages)
   * [NCN Operating System Releases](#ncn_operating_system_releases)
   * [cloud-init Basecamp Configuration](#cloud-init_basecamp_configuration)

## Details

<a name="cray_site_init_files"></a>
### Cray Site Init Files

   The Cray Site Init (`csi`) command has several files which describe pre-configuration data needed during
   the installation process:

   * [`application_node_config.yaml`](../install/prepare_configuration_payload.md#application_node_config_yaml)
   * [`cabinets.yaml`](../install/prepare_configuration_payload.md#cabinets_yaml)
   * [`hmn_connections.json`](../install/prepare_configuration_payload.md#hmn_connections_json)
   * [`ncn_metadata.csv`](../install/prepare_configuration_payload.md#ncn_metadata_csv)
   * [`switch_metadata.csv`](../install/prepare_configuration_payload.md#switch_metadata_csv)

   In addition, after running `csi` with those pre-config files, `csi` creates an output `system_config.yaml`
   file which can be passed to `csi` when reinstalling this software release.

<a name="certificate_authority"></a>
### Certificate Authority

   While a system is being installed for the first time, a certificate authority (CA) is needed. This can be
   generated for a system, or one can be supplied from a customer intermediate CA. Outside of a new
   installation, there is no supported method to rotate or change the platform CA in this release.

   For more information about these topics, see [Certificate Authority](certificate_authority.md)

   * "Overview"
   * "Use Default Platform Generated CA"
   * "Customize Platform Generated CA"
   * "Use an External CA"

<a name="ncn_images"></a>
### NCN Images

   The management nodes boot from NCN images which are created as layers on top of a common base image.
   The common image is customized with a Kubernetes layer for the master nodes and worker nodes.
   The common image is also customized with a storage-ceph layer for the utility storage nodes.
   Three artifacts are needed to boot the management nodes.

   See [NCN Images](ncn_images.md)

<a name="ncn_boot_workflow"></a>
### NCN Boot Workflow

   The boot workflow for management nodes (NCNs) is different from compute nodes or application nodes.
   They can PXE boot over the network or from local storage.

   See [NCN Boot Workflow](ncn_boot_workflow.md) for these topics

   * How can I tell if I booted via disk or PXE?
   * Set BMCs to DHCP
   * Set Boot Order
      * Setting Order
      * Trimming Boot Order
      * Examples
      * Reverting Changes
      * Locating USB Device

<a name="ncn_networking"></a>
### NCN Networking

   Non-compute nodes and compute nodes have different network interfaces used for booting.
   The NCN network interfaces, device naming, and vendor and bus identification are described in this topic.

   * [NCN Networking](ncn_networking.md)

<a name="ncn_mounts_and_file_systems"></a>
### NCN Mounts and File Systems

   The management nodes have specific file systems and mounts and use overlayfs.

   See [NCN Mounts and File Systems](ncn_mounts_and_file_systems.md)

<a name="ncn_packages"></a>
### NCN Packages

   The management nodes boot from images which have many (RPM) packages installed. The packages
   installed differ between the Kubernetes master and worker nodes versus the utility storage nodes.

   * [NCN Packages](ncn_packages.md)

<a name="ncn_operating_system_releases"></a>
### NCN Operating System Releases

   All management nodes have an operating system based on SLE_HPC (SuSE High Performance Computing).

   * [NCN Operating System Releases](ncn_operating_system_releases.md)

<a name="cloud-init_basecamp_configuration"></a>
### cloud-init Basecamp Configuration

Metal Basecamp is a cloud-init DataSource available on the LiveCD. Basecamp's configuration file offers many inputs for various cloud-init scripts embedded within the NCN images.
