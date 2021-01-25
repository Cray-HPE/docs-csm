# Overview
1. [New for Shasta v1.4 Networking](#new-for-v1.4)
1. [Dell and Mellanox Changes for Shasta v1.3 to v1.4 Upgrades](412-MGMT-NET-DELL-MELLANOX-UPGRADES.md)
1. HPE Aruba Installation and Configuration
    1. Early Installation
        1. Access Master Node 1 (m001) and it's iLO should already be completed (003-LIVECD-USB-BOOT.md)
        1. Install [Baseline Switch Configuration](402-MGMT-NET-BASE-CONFIG.md)
        1. Update [Firmware](409-MGMT-NET-FIRMWARE-UPDATE.md)
    1. Configure all switches via IPv6 connection from m001
        1. Layer 2 configuration:
            1. [VLAN](403-MGMT-NET-VLAN-CONFIG.md).
            1. [MLAG](404-MGMT-NET-MLAG-CONFIG.md) and VSX pairs.
            1. iLO/BMC, CMM and Gateway Node [port configuration](405-MGMT-NET-PORT-CONFIG.md).
            1. Switch uplink ports - [ISL](410-MGMT-NET-UPLINK-CONFIG.md)
        1. Layer 3 configuration:
            1. L3 interfaces.
            1. [ACL](406-MGMT-NET-ACL-CONFIG.md).
            1. [Dynamic Routing](411-MGMT-NET-LAYER3-CONFIG.md): OSPFv2 and BGP.
            1. [SNMP](407-MGMT-NET-SNMP-CONFIG.md)
        1. Create the [CAN](408-MGMT-NET-CAN-CONFIG.md).

----------------------------------------

# New for v1.4
The network architecture and configuration changes from v1.3 to v1.4 are fairly small. The biggest change is the introduction of HPE/Aruba switches, as well as Cray Site Init (CSI) generating switch IPs. HPE Aruba switch configuration is contained in separate documents as described in the index [above](#overview).  Dell and Mellanox changes to upgrade from v1.3 to v.14 Shasta releases are describe in [separate document](412-MGMT-NET-DELL-MELLANOX-UPGRADES.md).

*   New Aruba/HPE switches.
*   ACL configuration.
*   Moving Site connection from ncn-w001 to ncn-m001.
*   The IP-Helper will reside on the switches where the default gateway for the servers, such as bmcs and computes, is configured.
*   IP-Helper applied on vlan 1 and vlan 7, this will point to 10.92.100.222.
*   Make sure 1.3.2 changes are applied, this includes flow-control and MAGP changes.
*   Remove BPDUfilter on the Dell access ports.
*   Add BPDUguard to the Dell access ports.

