# Cray System Management Installation Guide

### Scope and Audience

The documentation included here describes how to install or upgrade the Cray System Management (CSM)
software and related supporting operational procedures.  CSM software is the foundation upon which
other software product streams for the HPE Cray EX system depend.

The CSM installation prepares and deploys a distributed system across a group of management
nodes organized into a Kubernetes cluster which uses Ceph for utility storage.  These nodes
perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage
nodes with the Ceph storage.

System services on these nodes are provided as containerized microservices packaged for deployment
as helm charts.  These services are orchestrated by Kubernetes to be scheduled on Kubernetes worker
nodes with horizontal scaling to increase or decrease the number of instances of some services as 
demand for them varies, such as when booting many compute nodes or application nodes.

This information is intended for system installers, system administrators, and network administrators
of the system.  It assumes some familiarity with standard Linux and open source tools, such as shell
scripts, Ansible, YAML, JSON, and TOML file formats, etc.

### Trademarks

© Copyright 2021 Hewlett Packard Enterprise Development LP. All trademarks used in this document are the property of their respective owners.

## Table of Contents

The chapters with topics which need to be done as part of an ordered procedure are shown here with numbered topics.

1. [Introduction to CSM Installation](introduction/index.md)

   Topics:
   * [CSM Overview](introduction/index.md#csm_overview)
   * [Scenarios for Shasta v1.5](introduction/index.md#scenarios)
   * [CSM Product Stream Updates](introduction/index.md#product-stream-updates)
   * [CSM Operational Activities](introduction/index.md#operations)
   * [Differences from Previous Release](introduction/index.md#differences)
   * [Documentation Conventions](introduction/index.md#documentation_conventions)

1. [Update CSM Product Stream](update_product_stream/index.md)

   Topics:
   1. [Download and Extract CSM Product Release](update_product_stream/index.md#download-and-extract)
   1. [Apply Patch to CSM Release](update_product_stream/index.md#patch)
   1. [Check for Latest Workarounds and Documentation Updates](update_product_stream/index.md#workarounds)
   1. [Check for Field Notices about Hotfixes](update_product_stream/index.md#hotfixes)


1. [Install CSM](install/index.md)

   Topics:
   1. [Validate Management Network Cabling](#validate_management_network_cabling)
   1. [Prepare Configuration Payload](install/prepare_configuration_payload.md)
   1. [Prepare Management Nodes](#prepare_management_nodes)
   1. [Bootstrap PIT Node](install/index.md#bootstrap_pit_node)
   1. [Configure Management Network Switches](install/configure_management_network.md)
   1. [Deploy Management Nodes](install/deploy_management_nodes.md)
   1. [Install CSM Services](install/install_csm_services.md)
   1. [Validate CSM Health Before PIT Node Redeploy](install/index.md#validate_csm_health_before_pit_redeploy)
   1. [Redeploy PIT Node](install/redeploy_pit_node.md)
   1. [Configure Administrative Access](install/configure_administrative_access.md)
   1. [Validate CSM Health](operations/validate_csm_health.md)
   1. [Update Firmware with FAS](operations/firmware/Update_Firmware_with_FAS.md)
   1. [Prepare Compute Nodes](install/index.md#prepare_compute_nodes)
   1. [Next Topic](install/index.md#next_topic)
   1. [Troubleshooting Installation Problems](install/troubleshooting_installation.md)

1. [Upgrade CSM](upgrade/index.md)

   Topics:
   1. [Prepare for Upgrade](upgrade/prepare_for_upgrade.md)
   1. [Update Management Network Configuration](upgrade/update_management_network.md)
   1. [Upgrade Management Nodes](upgrade/upgrade_management_nodes.md)
   1. [Upgrade CSM Services](upgrade/upgrade_csm_services.md)
   1. [Restore from Backup](upgrade/restore_from_backup.md)
   1. [Validate CSM Health](operations/validate_csm_health.md)
   1. [Update Firmware with FAS](operations/firmware/Update_Firmware_with_FAS.md)
   1. [Next Topic](upgrade/index.md#next_topic)
   1. [Troubleshooting Upgrade Problems](upgrade/troubleshooting_upgrade.md)

1. [CSM Operational Activities](operations/index.md)

   Topics:
   * [Lock and Unlock Nodes](operations/lock_and_unlock_nodes.md)
   * [Validate CSM Health](operations/validate_csm_health.md)
   * [Configure Keycloak Account](operations/configure_keycloak_account.md)
   * [Configure the Cray Command Line Interface (cray CLI)](operations/configure_cray_cli.md)
   * [Configure BMC and Controller Parameters with SCSD](operations/configure_with_scsd.md)
   * [Update BGP Neighbors](operations/update_bgp_neighbors.md)
   * [Update Firmware with FAS](operations/firmware/Update_Firmware_with_FAS.md)
   * [Manage Node Consoles](operations/manage_node_consoles.md)
   * [Changing Passwords and Credentials](operations/changing_passwords_and_credentials.md)
   * [Managing Configuration with CFS](operations/managing_configuration_with_CFS.md)
   * [UAS/UAI Admin and User Guide](operations/500-UAS-UAI-ADMIN-AND-USER-GUIDE.md)
   * [Accessing LiveCD USB Device After Reboot](operations/accessing_livecd_usb_device_after_reboot.md)
   * [Update SLS with UAN Aliases](operations/update_sls_with_uan_aliases.md)
   * [Configure NTP on NCNs](operations/configure_ntp_on_ncns.md)
   * [Change NCN Image Root Password and SSH Keys](operations/change_ncn_image_root_password_and_ssh_keys.md)

1. [CSM Troubleshooting Information](troubleshooting/index.md)

   Topics:
   * [Known Issues](troubleshooting/index.md#known-issues)

1. [CSM Background Information](background/index.md)

   Topics:
   * [Cray Site Init Files](background/cray_site_init_files.md)
   * [Certificate Authority](background/certificate_authority.md)
   * [NCN Images](background/ncn_images.md)
   * [NCN Boot Workflow](background/ncn_boot_workflow.md)
   * [NCN Networking](background/ncn_networking.md)
   * [NCN Mounts and File Systems](background/ncn_mounts_and_file_systems.md)
   * [NCN Packages](background/ncn_packages.md)
   * [NCN Operating System Releases](background/ncn_operating_system_releases.md)
   * [cloud-init Basecamp Configuration](background/cloud-init_basecamp_configuration.md)

1. [Glossary](glossary.md)
