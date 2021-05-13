# Management Network Base Configuration

This page provides instructions on how to setup the base network configuration of the Shasta Management network.

With the base config applied you will be able to access all Management switches and apply the remaining configuration. 

# Requirements

- Console access to all of the switches
- SHCD available

# Configuration

Once you have console access to the switches you can begin by applying the base config.
The purpose of this configuration is to have an IPv6 underlay that allows us to always be able to access the management switches.
The base config is running OSPFv3 over IPv6 on VLAN 1, so the switches can dynamically form neighborship which allows us to gain remote access to them. 

The admin username and password needs to be applied.
```
switch# conf t
switch(config)# user admin group administrators password plaintext xxxxxxxx
```
Set the hostname of the switch, you can use the name defined in the SHCD for this.
```
switch(config)# hostname sw-25g04
```
Every uplink or switch to switch link will need to be enabled and require the following configuration.
You can determine the uplink ports from the SHCD.

```
sw-25g04(config)# int 1/1/1
sw-25g04(config-if)# no routing 
sw-25g04(config-if)# vlan trunk native 1
sw-25g04(config-if)# no shut
```
You will need to add an IPv6 interface to VLAN 1 and start the OSPv3 process.
In addition to this, you will need a unique router-id, this is an IPv4 address that will only be used for
identifying the router, this is not a routable address.  You can increment this by 1 for each switch.  You can use other IPs for router-IDs if desired. 
```
sw-25g04(config)# router ospfv3 1
sw-25g04(config-ospfv3-1)# area 0
sw-25g04(config-ospfv3-1)# router-id 172.16.0.1
sw-25g04(config-ospfv3-1)# exit
```
Add VLAN 1 interface to OSPF area 0
```
sw-25g04(config)# int vlan 1
sw-25g04(config-if-vlan)# ipv6 address autoconfig
sw-25g04(config-if-vlan)# ipv6 ospfv3 1 area 0
sw-25g04(config-if-vlan)# exit
```
Add a unique IPv6 Loopback address, this is the address that we will be remotely connecting to.
You can increment this address by 1 for every switch you have.
```
sw-25g04(config)# interface loopback 0
sw-25g04(config-loopback-if)# ipv6 address fd01::0/64
sw-25g04(config-loopback-if)# ipv6 ospfv3 1 area 0
```
The following commands will need to be applied to gain remote access via SSH/HTTPS/API
```
sw-25g04(config)# ssh server vrf default
sw-25g04(config)# ssh server vrf mgmt
sw-25g04(config)# https-server vrf default
sw-25g04(config)# https-server vrf mgmt
sw-25g04(config)# https-server rest access-mode read-write
```
The show run will look like the following
```
sw-25g04(config)# show run
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

At this point you should see OSPFv3 neighbors.
```
sw-25g04# show ipv6 ospfv3 neighbors 
OSPFv3 Process ID 1 VRF default
================================

Total Number of Neighbors: 1

Neighbor ID      Priority  State             Interface
-------------------------------------------------------
192.168.100.2    1         FULL/BDR          vlan1             
  Neighbor address fe80::800:901:8b4:e152
```

You can now connect to the neighbors via the IPv6 loopback that we set earlier.
```
sw-25g03# ssh admin@fd01::1
```