# Cray System Management Installation Guide

### Scope and Audience

The documentation included here describes how to install or upgrade the Cray System Management (CSM)
software and related supporting operational procedures to manage an HPE Cray EX system. CSM software
is the foundation upon which other software product streams for the HPE Cray EX system depend.

The CSM installation prepares and deploys a distributed system across a group of management
nodes organized into a Kubernetes cluster which uses Ceph for utility storage. These nodes
perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage
nodes with the Ceph storage.

System services on these nodes are provided as containerized micro-services packaged for deployment
as helm charts. These services are orchestrated by Kubernetes to be scheduled on Kubernetes worker
nodes with horizontal scaling to increase or decrease the number of instances of some services as 
demand for them varies, such as when booting many compute nodes or application nodes.

This information is intended for system installers, system administrators, and network administrators
of the system. It assumes some familiarity with standard Linux and open source tools, such as shell
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
   1. [Validate Management Network Cabling](install/index.md#validate_management_network_cabling)
   1. [Prepare Configuration Payload](install/index.md#prepare_configuration_payload)
   1. [Prepare Management Nodes](install/index.md#prepare_management_nodes)
   1. [Bootstrap PIT Node](install/index.md#bootstrap_pit_node)
   1. [Configure Management Network Switches](install/index.md#configure_management_network)
   1. [Collect MAC Addresses for NCNs](install/index.md#collect_mac_addresses_for_ncns)
   1. [Deploy Management Nodes](install/index.md#deploy_management_nodes)
   1. [Install CSM Services](install/index.md#install_csm_services)
   1. [Validate CSM Health Before PIT Node Redeploy](install/index.md#validate_csm_health_before_pit_redeploy)
   1. [Redeploy PIT Node](install/index.md#redeploy_pit_node)
   1. [Configure Administrative Access](install/index.md#configure_administrative_access)
   1. [Validate CSM Health](operations/validate_csm_health.md)
   1. [Configure Prometheus Alert Notifications](intall/index.md#configure_prometheus_alert_notifications)
   1. [Update Firmware with FAS](operations/firmware/Update_Firmware_with_FAS.md)
   1. [Prepare Compute Nodes](install/index.md#prepare_compute_nodes)
   1. [Next Topic](install/index.md#next_topic)
   1. [Troubleshooting Installation Problems](install/troubleshooting_installation.md)

1. [Upgrade CSM](upgrade/index.md)

   Topics:
   1. [Prepare for Upgrade](upgrade/index.md#prepare_for_upgrade)
   1. [Update Management Network Configuration](upgrade/index.md#update_management_network)
   1. [Upgrade Management Nodes and CSM Services](upgrade/index.md#upgrade_management_nodes_csm_services)
   1. [Validate CSM Health](upgrade/index.md#validate_csm_health)
   1. [Update Firmware with FAS](upgrade/index.md#update_firmware_with_fas)
   1. [Next Topic](upgrade/index.md#next_topic)

1. [CSM Operational Activities](operations/index.md)

   Topics:
   * [CSM Product Management](operations/index.md#csm-product-management)
   * [Image Management](operations/index.md#image-management)
   * [Boot Orchestration](operations/index.md#boot-orchestration)
   * [System Power Off Procedures](operations/index.md#system-power-off-procedures)
   * [System Power On Procedures](operations/index.md#system-power-on-procedures)
   * [Power Management](operations/index.md#power-management)
   * [Artifact Management](operations/index.md#artifact-management)
   * [Compute Rolling Upgrades](operations/index.md#compute-rolling-upgrades)
   * [Configuration Management](operations/index.md#configuration-management)
   * [Kubernetes](operations/index.md#kubernetes)
   * [Package Repository Management](operations/index.md#package-repository-management)
   * [Security and Authentication](operations/index.md#security-and-authentication)
   * [Resiliency](operations/index.md#resiliency)
   * [ConMan](operations/index.md#conman)
   * [Utility Storage](operations/index.md#utility-storage)
   * [System Management Health](operations/index.md#system-management-health)
   * [System Layout Service (SLS)](operations/index.md#system-layout-service-sls)
   * [System Configuration Service](operations/index.md#system-configuration-service)
   * [Hardware State Manager (HSM)](operations/index.md#hardware-state-manager-hsm)
   * [Node Management](operations/index.md#node-management)
   * [River Endpoint Discovery Service (REDS)](operations/index.md#river-endpoint-discovery-service-reds)
   * [Network](operations/index.md#network)
   * [Update Firmware with FAS](operations/index.md#update-firmware-with-fas)
   * [User Access Service (UAS)](operations/index.md#user-access-service-uas)

2. [CSM Troubleshooting Information](troubleshooting/index.md)

   Topics:
   * [Known Issues](troubleshooting/index.md#known-issues)

3. [CSM Background Information](background/index.md)

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

4. [Glossary](glossary.md)
