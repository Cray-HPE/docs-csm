

# Configure Aruba Management Network Base

This page provides instructions on how to setup the base network configuration of the Shasta Management network.

After applying the base configuration, all management switches will be accessible to apply the remaining configuration.

## Prerequisites

- Console access to all of the switches
- SHCD available

## Configuration

The base configuration can be applied once console access to the switches has been established.
The purpose of this configuration is to have an IPv6 underlay that provides access to the management switches.
The base configuration is running OSPFv3 over IPv6 on VLAN 1, so the switches can dynamically form neighborship, which enables remote access.

1. Apply the admin username and password.

   ```bash
   switch# conf terminal
   switch(config)# user admin group administrators password plaintext xxxxxxxx
   ```

2. Set the hostname of the switch.

   Use the name defined in the SHCD to set the hostname.
   
   ```bash
   switch(config)# hostname sw-25g04
   ```

3. Enable and configure every uplink or switch to switch link.
   
   Use SHCD to determine the uplink ports.

   ```bash
   sw-25g04(config)# int 1/1/1
   sw-25g04(config-if)# no routing
   sw-25g04(config-if)# vlan trunk native 1
   sw-25g04(config-if)# no shut
   ```

4. Add an IPv6 interface to VLAN 1 and start the OSPv3 process.

   In addition to this, a unique router-id is required. This is an IPv4 address that will only be used for
   identifying the router; this is not a routable address. Increment this by 1 for each switch. Other IP addresses may be used for router-IDs if desired.

   ```bash
   sw-25g04(config)# router ospfv3 1
   sw-25g04(config-ospfv3-1)# area 0
   sw-25g04(config-ospfv3-1)# router-id 172.16.0.1
   sw-25g04(config-ospfv3-1)# exit
   ```

5. Add VLAN 1 interface to OSPF area 0.

   ```bash
   sw-25g04(config)# int vlan 1
   sw-25g04(config-if-vlan)# ipv6 address autoconfig
   sw-25g04(config-if-vlan)# ipv6 ospfv3 1 area 0
   sw-25g04(config-if-vlan)# exit
   ```

6. Add a unique IPv6 Loopback address, which is the address that we will be remotely connecting to.
   
   Increment this address by 1 for every switch.

   ```bash
   sw-25g04(config)# interface loopback 0
   sw-25g04(config-loopback-if)# ipv6 address fd01::0/64
   sw-25g04(config-loopback-if)# ipv6 ospfv3 1 area 0
   ```

7. Enable remote access via SSH/HTTPS/API.

   ```bash
   sw-25g04(config)# ssh server vrf default
   sw-25g04(config)# ssh server vrf mgmt
   sw-25g04(config)# https-server vrf default
   sw-25g04(config)# https-server vrf mgmt
   sw-25g04(config)# https-server rest access-mode read-write
   ```

8. View the running configuration.

   The configuration should look similar to the following:

   ```bash
   sw-25g04(config)# show running
   Current configuration:
   !
   !Version ArubaOS-CX Virtual.10.05.0020
   !export-password: default
   hostname sw-25g04
   user admin group administrators password ciphertext AQBapXDwaGq+GHwyLgj0Eu
   led locator on
   !
   !
   !
   !
   ssh server vrf default
   ssh server vrf mgmt
   vlan 1
   interface mgmt
       no shutdown
       ip dhcp
   interface 1/1/1
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed all
   interface loopback 0
       ipv6 address fd01::1/64
       ipv6 ospfv3 1 area 0.0.0.0
   interface loopback 1
   interface vlan 1
       ipv6 address autoconfig
       ipv6 ospfv3 1 area 0.0.0.0
   !
   !
   !
   !
   !
   router ospfv3 1
       router-id 192.168.100.1
       area 0.0.0.0
   https-server vrf default
   https-server vrf mgmt
   ```

9. Verify there are now OSPFv3 neighbors.
   
   ```bash
   sw-25g04# show ipv6 ospfv3 neighbors
   OSPFv3 Process ID 1 VRF default
   ================================

   Total Number of Neighbors: 1

   Neighbor ID      Priority  State             Interface
   -------------------------------------------------------
   192.168.100.2    1         FULL/BDR          vlan1
     Neighbor address fe80::800:901:8b4:e152
   ```

10. Connect to the neighbors via the IPv6 loopback that was set earlier.

    ```bash
    sw-25g03# ssh admin@fd01::1
    ```

