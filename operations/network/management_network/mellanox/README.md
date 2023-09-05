# Mellanox Installation and Configuration Guide

This documentation helps network administrators and support personnel install install and manage Mellanox network devices in a CSM install.

The HPE Cray recommended way of configuring the network is by using the CANU tool. Therefore this guide will not go into detail on how to configure
each switch manually using the CLI. Instead, it will give helpful examples of how to configure/use features generated by CANU, in order to provide
administrators easy ways to customize their installation.

Also included in this guide are the current documented and supported network scenarios.

**`NOTE`** Not every configuration option is covered here; for any configuration outside of the scope of this document, refer to the official
Mellanox user manual. See [Mellanox](https://docs.mellanox.com/).

This document is intended for network administrators and support personnel.

**`NOTE`** The display and command lines illustrated in this document are examples and might not exactly match any particular environment. The switch
and accessory drawings in this document are for illustration only, and may not exactly match installed products.

## CANU

See [CSM Automatic Network Utility (CANU)](../canu/README.md)

## Examples of Network topologies

* [Very Large](very_large.md)
* [Large](large.md)
* [Medium](medium.md)
* [Small](small.md)

## Network Design Explained

* [What is Spine-Leaf Architecture?](spine_leaf_architecture.md)
* [How does a spine-leaf architecture differ from traditional network designs?](spine_leaf_architecture2.md)
* [Why are spine-leaf architectures becoming more popular?](spine_leaf_architecture3.md)
* [What is MLAG?](mlag_architecture.md)

## Management Network Overview

* [Network Types – Naming and Segment Function](network_naming_function.md)
* [Network Traffic Pattern](network_traffic_pattern.md)
* [System Management Network Functions](management_network_function_in_detail.md)

## Key Features Used in the Management Network Configuration

* [Key Feature List](key_features.md)
* [Typical Configuration of MLAG Between Switches](typical_mlag_switch_configuration.md)
* [Typical Configuration of MLAG Link Connecting to NCN](typical_mlag_port_configuration.md)

## How to Connect Management Network to a Campus Network

* [Connect the Management Network to a Campus Network](requirements_and_optional_configuration.md)
* [Scenario A: Network Connection via Management Network](scenario-a.md)
* [Scenario B: Network Connection via High-Speed Network](scenario-b.md)
* [Example of How to Configure Scenario A or B](management_network_configuration_example.md)

## Managing Switches from the CLI

### Device Management

* [Management Interface](management_interface.md)
* [Network Time Protocol (NTP) Client](ntp.md)
* [Domain Name System (DNS) Client](dns-client.md)
* [Exec Banners](exec_banner.md)
* [Hostname](hostname.md)
* [Domain Name](domain_name.md)
* [Secure Shell (SSH)](ssh.md)
* [Remote Logging](remote_logging.md)
* [Web User Interface (Web UI)](web-ui.md)
* [SNMPv2c Community](snmp_community.md)
* [SNMPv3 Users](snmpv3_users.md)
* [System Images](system_images.md)

### Layer One Features

* [Physical Interfaces](physical_interfaces.md)
* [Cable Diagnostics](cable_diagnostics.md)

### Layer Two Features

* [Link Layer Discovery Protocol (LLDP)](lldp.md)
* [Virtual Local Access Networks (VLANs)](vlan.md)
* [Native VLAN](native_vlan.md)
* [VLAN Trunking 802.1Q](vlan_trunking_8021q.md)
* [Link Aggregation Group (LAG)](lag.md)
* [MLAG Switch Configuration](mlag_switch.md)
* [Multi-Chassis Link Aggregation Group (MCLAG)](mlag.md)
* [Multiple Spanning Tree Protocol (MSTP)](mstp.md)

### Layer Three Features

* [Routed Interfaces](routed_interface.md)
* [VLAN Interface](vlan_interface.md)
* [Address Resolution Protocol (ARP)](arp.md)
* [Static MAC](static_mac.md)
* [Static Routing](static_routing.md)
* [Loopback Interface](loopback.md)
* [Open Shortest Path First (OSPF) v2](ospfv2.md)
* [BGP Basics](bgp_basic.md)

### Multicast

* [IGMP](igmp.md)
* [PIM-SM Bootstrap Router (BSR) and Rendezvous-Point (RP)](pim.md)

### Security

* [Access Control Lists (ACLs)](acl.md)
* [IP filter](ip_filter.md)

### Performing Upgrade on Mellanox

* [Switch upgrade](upgrade.md)

### Backing Up Switch Configuration

* [Backing up switch configuration](backup.md)

## Troubleshooting

### DHCP

* [Confirm the status of the `cray-dhcp-kea` pods/services](status_of_cray-dhcp-kea_pods.md)
* [Check current DHCP leases](check_current_dhcp_leases.md)
* [Check HSM](check_hsm.md)
* [Check Kea DHPC logs](check_kea_dhcp_logs.md)
* [TCPDUMP](ncn_tcpdump.md)
* [Check BGP and MetalLB](check_bgp_and_metallb.md)
* [Getting incorrect IP address. Duplicate IP address check](duplicate_ip.md)
* [Large number of DHCP declines during a node boot](dhcp_decline.md)

### DNS

### PXE Boot

* [NCNs on install](ncns_on_install.md)
* [Rebooting NCN and PXE fails](reboot_pxe_fail.md)
* [Verify BGP](verify_bgp.md)
* [Verify route to TFTP](verify_route_to_tftp.md)
* [Check DHCP lease is getting allocated](check_dhcp_lease_is_getting_allocated.md)
* [Verify DHCP traffic on workers](verify_dhcp_traffic_on_workers.md)
* [Verify switches are forwarding DHCP traffic](verify-switches_are_forwarding_dhcp_traffic.md)
* [Computes/UANs/Application Nodes](compute_uan_application_nodes.md)