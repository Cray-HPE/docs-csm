# Table of contents

## Introduction:

   1. [Introduction](#intro)
   1. [Notice](#notice)
   1. [Index](#index)
   1. [Introduction to Canu](#introduction_to_canu)

### Quick start guide to Canu

   1. [Quick start guide to Canu](#quick_start_guide_to_canu)

### Canu:
   1. [Installation](#canu_installation)
   1. [Initializing canu](#initializing_canu)
   1. [Use Canu to verify, generate or compare switch configuration](#canu_verify_generate_compare_switch_connfiguration)
   1. [Using Canu to generate full network configuration](#using_canu_to_generate_full_network_config)
   1. [Uninstall Canu](#uninstall_canu)

### Examples of Network topologies:

   1. [Very Large](#very_large)
   1. [Large](#large)
   1. [Medium](#medium)
   1. [Small](#small)

### Network design explained
   1. [What is Spine-Leaf Architecture?](#spine_leaf_architecture)
   1. [How does a spine-leaf architecture differ from traditional network designs?](#spine_leaf_architecture2)
   1. [Why are spine-leaf architectures becoming more popular?](#spine_leaf_architecture3)
   1. [What is MLAG?](#mlag_architecture)

### Management network overview
   1. [Network Types – Naming and segment Function](#network_naming_function)
   1. [Network traffic pattern inside of the system](#network_traffic_pattern)
   1. [System management network functions in more detail](#manegement_network_function_in_detail)

### Key features used in the management network configuration
   1. [Key Feature list](#key_features)
   1. [Typical configuration of mlag switch configuration](#typical_mlag_switch_configuration)
   1. [Typical MCLAG port configuration connecting to dual homed devices](#typical_mlag_port_configuration)

### How to connect management network to your campus network
   1. [Requirements and optional configuration](#requirements_and_optional_configuration)
   1. [Scenario A: network connection via management network](#scenario-a)
   1. [Scenario B: network connection via high speed network](#scenario-b)
   1. [Example of how to configure Scenario A or B](#management_network_configuration_example)

### Managing switches from CLI

###Device management
  1. [Management Interface](#management_interface)
  1. [Network Time Protocol (NTP) Client](#ntp)
  1. [Domain Name System (DNS) Client](#dns-client)
  1. [Exec Banners](#exec_banner)
  1. [Hostname](#hostname)
  1. [Domain Name](#domain_name)
  1. [Secure Shell (SSH)](#ssh)
  1. [Remote Logging](#remote_logging)
  1. [Web User Interface (WebUI)](#web-ui)
  1. [SNMPv2c Community](#snmp_community)
  1. [SNMP Traps](#snmp_trap)
  1. [SNMPv3 Users](#snmpv3_users)
  1. [System images](#system_images)

### Layer one features
  1. [Physical Interfaces](#physical_interfaces)
  1. [Cable Diagnostics](#cable_diagnostics)

### Layer two features
  1. [Link Layer Discovery Protocol (LLDP)](#lldp)
  1. [Virtual Local Access Networks (VLANs)](#vlan)
  1. [Native VLAN](#native_vlan)
  1. [VLAN Trunking 802.1Q](#vlan_trunking_8021q)
  1. [Link Aggregation Group (LAG)](#lag)
  1. [MLAG switch configuration](#mlag_switch)
  1. [Multi-Chassis Link Aggregation Group (MCLAG)](#mlag)
  1. [Multiple Spanning Tree Protocol (MSTP)](#mstp)

### Layer three features
  1. [Routed Interfaces](#routed_interface)
  1. [VLAN Interface](#vlan_interface)
  1. [Address Resolution Protocol (ARP)](#arp)
  1. [Static MAC] (#static_mac)
  1. [Static Routing](#static_routing)
  1. [Loopback Interface](#loopback)
  1. [Open Shortest Path First (OSPF) v2](#ospfv2)
  1. [BGP Basics](#bgp_basic)

### Multicast
  1. [IGMP](#igmp)
  1. [PIM-SM Bootstrap Router (BSR) and Rendezvous-Point (RP)](#pim)

### Security
  1. [Access Control Lists (ACLs)](#acl)
  1. [IP filter] (#ip_filter)

### Performing upgrade on Mellanox
  1. [Switch upgrade](#upgrade)

### Backing up switch configuration
  1. [Backing up switch configuration](#backup)
 
### Troubleshooting

### DHCP
  1. [Confirm the status of the cray-dhcp-kea pods/services](#status_of_cray-dhcp-kea_pods.md)
  1. [Check current DHCP leases](#check_current_dhcp_leases)
  1. [Check HSM](#check_hsm)
  1. [Check Kea DHPC logs](#check_kea_dhcp_logs)
  1. [TCPDUMP](#ncn_tcpdump)
  1. [Check BGP and MetalLB](#check_bgp_and_metallb)
  1. [You are getting IP, but not the correct one. Duplicate IP check](#duplicate_ip)
  1. [Large number of DHCP declines during a node boot](#dhcp_decline)

### DNS

### PXE boot

  1. [NCNs on install](#ncns_on_install)
  1. [Rebooting NCN and PXE fails](#reboot_pxe_fail)
  1. [Verify BGP](#verify_bgp)
  1. [Verify route to TFTP](#verify_route_to_tftp)
  1. [Test TFTP traffic (Aruba Only)](#test_tftp_traffic)
  1. [Check DHCP lease is getting allocated](#check_dhcp_lease_is_getting_allocated)
  1. [Verify DHCP traffic on workers](#verify_dhcp_traffic_on_workers)
  1. [Verify switches are forwarding DHCP traffic](#verify-switches_are_forwarding_dhcp_traffic)
  1. [Computes/UANs/Application Nodes](#compute_uan_application_nodes)