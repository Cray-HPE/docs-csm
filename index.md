# Cray System Management Installation Guide

### Scope and Audience

The documentation included here describes how to install or upgrade the Cray System Management (CSM) software and related supporting operational procedures.  CSM software is the foundation upon which other software product streams for the HPE Cray EX system depend.

The information is intended for system installers, system administrators, and network administrators of the system.  It assumes some familiarity with standard Linux and open source tools, such as shell scripts, Ansible, YAML, JSON, and TOML file formats, etc.

### Trademarks

© Copyright 2021 Hewlett Packard Enterprise Development LP. All trademarks used in this document are the property of their respective owners.

## Table of Contents

The chapters with topics which need to be done as part of an ordered procedure are shown here with numbered topics.

1. [Introduction to CSM Installation](introduction/index.md)

   Topics:
   * [Scenarios for Shasta v1.5](introduction/scenarios.md)
   * [CSM Product Stream Updates](introduction/index.md#product-stream-updates)
   * [CSM Operational Activities](introduction/index.md#operations)
   * [Differences from Previous Release](introduction/differences.md)
   * [Documentation Conventions](introduction/documentationconventions.md)

1. [Update CSM Product Stream](update_product_stream/index.md)

   Topics:
   1. [Download and Extract CSM Product Release](update_product_stream/index.md#download-and-extract)
   * [Apply Patch to CSM Release](update_product_stream/index.md#patch)
   * [Check for Latest Workarounds and Documentation Updates](update_product_stream/index.md#workarounds)
   * [Check for Field Notices about Hotfixes](update_product_stream/index.md#hotfixes)


1. [Install CSM](install/index.md)

   Topics:
   1. [Prepare Configuration Payload](install/prepare_configuration_payload.md)
   * [Configure LiveCD](install/configure_livecd.md)
   * [Bootstrap PIT Node](install/bootstrap_pit_node.md)
   * [Configure Management Network Switches](install/configure_management_network.md)
   * [Deploy Management Nodes](install/deploy_management_nodes.md)
   * [Install CSM Services](install/install_csm_services.md)
   * [Redeploy PIT Node](install/redploy_pit_node.md)
   * [Configure Administrative Access](configure_administrative_access.md)
   * [Validate CSM Health](operations/validate_csm_health.md)
   * [Update Firmware with FAS](operations/update_firmware_with_fas.md)
   * [Troubleshooting Installation Problems](install/troubleshooting_installation.md)

1. [Upgrade CSM](upgrade/index.md)

   Topics:
   1. [Prepare for Upgrade](upgrade/prepare_for_upgrade.md)
   * [Update Management Network Configuration](upgrade/update_management_network.md)
   * [Upgrade Management Nodes](upgrade/upgrade_management_nodes.md)
   * [Upgrade CSM Services](upgrade/upgrade_csm_services.md)
   * [Restore from Backup](upgrade/restore_from_backup.md)
   * [Validate CSM Health](operations/validate_csm_health.md)
   * [Update Firmware with FAS](operations/update_firmware_with_fas.md)
   * [Troubleshooting Upgrade Problems](upgrade/troubleshooting_upgrade.md))

1. [CSM Operational Activities](operations/index.md)

   Topics:
   * [Validate CSM Health](operations/validate_csm_health.md)
   * [Configure Keycloak Account](operations/configure_keycloak_account.md)
   * [Configure the Cray Command Line Interface (cray CLI)](operations/configure_cray_cli.md)
   * [Conifgure BMC and Controller Parameters with SCSD](operations/configure_with_scsd.md)
   * [Update Firmware with FAS](operations/update_firmware_with_fas.md)
   * [Manage Node Consoles](operations/manage_node_consoles.md))
   * [Changing Passwords and Credentials](operations/changing_passwords_and_credentials.md)
   * [Managing Configuration with CFS](operations/managing_configuration_with_CFS.md)

1. [CSM Background Information](background/index.md)

   Topics:
   * [Certficate Authority](background/certificate_authority.md)
   * [NCN Images](background/ncn_images.md)
   * [NCN Boot Workflow](background/ncn_boot_workflow.md)
   * [NCN Networking](background/ncn_networking.md)
   * [NCN Mounts and File Systems](background/ncn_mounts_and_file_systems.md)
   * [NCN Packages](background/ncn_packages.md)
   * [NCN Operating System Releases](background/ncn_operating_system_releases.md)
   * [NTP on NCNs](background/ntp_on_ncn.md)
   * [NCN Image Customization](background/ncn_image_customization.md)
   * [Glossary](background/glossary.md)

