# CSM Background Information

This document provides background information about the NCNs (non-compute nodes) which function as
management nodes for the HPE Cray EX system. This information is not normally needed to install
software, but provides background which may be helpful for troubleshooting an installation.

* [Cray Site Init files](#cray-site-init-files)
* [Certificate authority](#certificate-authority)
* [NCN images](#ncn-images)
* [NCN boot workflow](#ncn-boot-workflow)
* [NCN networking](#ncn-networking)
* [NCN mounts and file systems](#ncn-mounts-and-file-systems)
* [NCN packages](#ncn-packages)
* [NCN operating system releases](#ncn-operating-system-releases)
* [`cloud-init` Basecamp configuration](#cloud-init-basecamp-configuration)

<a name="cray_site_init_files"></a>

## Cray Site Init files

The Cray Site Init (`csi`) command has several files which describe pre-configuration data needed during
the installation process:

* [`application_node_config.yaml`](../install/prepare_configuration_payload.md#application_node_config_yaml)
* [`cabinets.yaml`](../install/prepare_configuration_payload.md#cabinets_yaml)
* [`hmn_connections.json`](../install/prepare_configuration_payload.md#hmn_connections_json)
* [`ncn_metadata.csv`](../install/prepare_configuration_payload.md#ncn_metadata_csv)
* [`switch_metadata.csv`](../install/prepare_configuration_payload.md#switch_metadata_csv)

In addition, after being run with those files, `csi` creates an output `system_config.yaml`
file which can be used as an input to `csi` when reinstalling this software release.

<a name="certificate_authority"></a>

## Certificate authority

While a system is being installed for the first time, a certificate authority (CA) is needed. This can be
generated for a system, or one can be supplied from a customer intermediate CA. Outside of a new
installation, there is no supported method to rotate or change the platform CA in this release.

For more information about these topics, see [Certificate Authority](certificate_authority.md).

<a name="ncn_images"></a>

## NCN images

The management nodes boot from NCN images which are created as layers on top of a common base image.
The common image is customized with a Kubernetes layer for the master nodes and worker nodes.
The common image is also customized with a storage/Ceph layer for the utility storage nodes.
Three artifacts are needed to boot the management nodes.

For more information, see [NCN Images](ncn_images.md).

<a name="ncn_boot_workflow"></a>

## NCN boot workflow

The boot workflow for management nodes (NCNs) is different from compute nodes or application nodes.
They can PXE boot over the network or from local storage.

See [NCN Boot Workflow](ncn_boot_workflow.md) for more information.

<a name="ncn_networking"></a>

## NCN networking

Non-compute nodes and compute nodes have different network interfaces used for booting.

For more information, see [NCN Networking](ncn_networking.md).

<a name="ncn_mounts_and_file_systems"></a>

## NCN mounts and file systems

The management nodes have specific file systems and mounts and use `overlayfs`.

For information, see [NCN Mounts and File Systems](ncn_mounts_and_file_systems.md).

<a name="ncn_packages"></a>

## NCN packages

The management nodes boot from images which have many (RPM) packages installed. The packages
installed differ between the Kubernetes master and worker nodes versus the utility storage nodes.

For more information, see [NCN Packages](ncn_packages.md).

<a name="ncn_operating_system_releases"></a>

## NCN operating system releases

All management nodes have an operating system based on `SLE_HPC` (SuSE High Performance Computing).

For more information, see [NCN Operating System Releases](ncn_operating_system_releases.md).

<a name="cloud-init_basecamp_configuration"></a>

## `cloud-init` Basecamp configuration

Metal Basecamp is a `cloud-init` `DataSource` available on the LiveCD. Basecamp's configuration file offers many inputs for various `cloud-init` scripts embedded within the NCN images.
