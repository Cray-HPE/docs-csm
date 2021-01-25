# Overview
1. [New for Shasta v1.4](#new-for-v1.4)
1. [Dell and Mellanox Changes for Shasta v1.3 to v1.4 Upgrades](#shasta-v1.3-to-v1.4-changes) 
1. HPE Aruba Installation and Configuration
    1. [Updating Firmware](409-MGMT-NET-FIRMWARE-UPDATE.md)
    1. [Baseline Switch Configuration](402-MGMT-NET-BASE-CONFIG.md)
    1. Access to m001 and iLO
    1. CSI tool
    1. enable sw-leaf-001 access from m001
        1. Serial connection to sw-leaf-01 connected to m001 
        1. config leaf VSX and MC-LAG to enable m001 connection via IPv6 VLAN1
    1. Config all switches via IPv6 connection from m001
        1. Layer 2 config: VLANs, VSX pairs, MTU, BMC access ports, switch uplink ports
        1. Create the CAN
        1. Layer 3 config: L3 interfaces, static CAN routes, ACLs.
        1. Layer 3 dynamic routing: OSPFv2

----------------------------------------

# New for v1.4
The network architecture and configuration changes from v1.3 to v1.4 are fairly small. The biggest change is the introduction of HPE/Aruba switches, as well as Cray Site Init (CSI) generating switch IPs. HPE Aruba switch configuration is contained in separate documents as described in the index [above](#overview).  Dell and Mellanox changes to upgrade from v1.3 to v.14 Shasta releases are describe in the [following sections](#shasta-v1.3-to-v1.4-changes-for-dell-and-mellanox).

*   Aruba/HPE switches.
*   ACL configuration
*   Moving Site connection from ncn-w001 to ncn-m001
*   The IP-Helper will reside on the switches where the default gateway for the servers, such as bmcs and computes, is configured.
*   IP-Helper applied on vlan 1 and vlan 7, this will point to 10.92.100.222.
*   Make sure 1.3.2 changes are applied, this includes flow-control and MAGP changes.
*   Remove BPDUfilter on the Dell access ports.
*   Add BPDUguard to the Dell access ports.

 # Shasta v1.3 to v1.4 Changes for Dell and Mellanox
## Dell Changes
* Remove spanning-tree bpdufilter
* Add spanning-tree bpduguard

Shasta v1.3 (old) config
```
!v1.3 config
interface ethernet1/1/3
 no shutdown
 switchport mode trunk
 switchport access vlan 1
 switchport trunk allowed vlan 2,4,7,10
 mtu 9216
 flowcontrol receive on
 flowcontrol transmit off
 spanning-tree bpdufilter enable
 spanning-tree port type edge
```

Shasta v1.4 (new) config
```
!v1.4 config
interface ethernet1/1/2
 no shutdown
 switchport mode trunk
 switchport access vlan 1
 switchport trunk allowed vlan 2,4,7,10
 mtu 9216
 flowcontrol receive on
 flowcontrol transmit off
 spanning-tree bpduguard enable
 spanning-tree port type edge
```

Shasta v1.3 to v1.4 Delta
```
!v1.3 to v1.4 changes
configure terminal
interface ethernet 1/1/x
no spanning-tree bpdufilter 
spanning-tree bpduguard enable
exit
write memory
```

## Mellanox Changes
### MAGP
MAGP setup for mellanox spine switches, this should be set for every VLAN interface. 
https://community.mellanox.com/s/article/howto-configure-magp-on-mellanox-switches
#### Spine01
```
(config) protocol magp
(config) interface vlan 2 ip address 10.252.0.2/17 primary
(config) interface vlan 2 magp 2 ip virtual-router address 10.252.0.1
(config) interface vlan 2 magp 2 ip virtual-router mac-address 00:00:5E:00:01:02
```
#### Spine02
```
(config) protocol magp
(config) interface vlan 2 ip address 10.252.0.3/17 primary
(config) interface vlan 2 magp 2 ip virtual-router address 10.252.0.1
(config) interface vlan 2 magp 2 ip virtual-router mac-address 00:00:5E:00:01:02
```

### MLAG
https://community.mellanox.com/s/article/how-to-configure-mlag-on-mellanox-switches
#### Spine01
```
(config) # protocol mlag
(config) # interface port-channel 100
(config) # interface ethernet 1/14 channel-group 100 mode active
(config) # interface ethernet 1/13 channel-group 100 mode active
(config) # interface ethernet 1/13 dcb priority-flow-control mode on force
(config) # interface ethernet 1/14 dcb priority-flow-control mode on force
(config) # vlan 4000
(config) # interface vlan 4000
(config) # interface port-channel 100 ipl 1
(config) # interface port-channel 100 dcb priority-flow-control mode on force
(config interface vlan 4000) # ip address 192.168.255.254 255.255.255.252
(config interface vlan 4000) # ipl 1 peer-address 192.168.255.253
(config) # mlag system-mac 00:00:5E:00:01:5D
(config) # no mlag shutdown

(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # lacp-individual enable force
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10

(config) # interface ethernet 1/1
(config interface ethernet 1/1) # mlag-channel-group 1 mode active
(config interface ethernet 1/1) # interface ethernet 1/1 speed 40G force
(config interface ethernet 1/1) # interface ethernet 1/1 mtu 9216 force
```

#### Spine02
```
(config) # protocol mlag
(config) # interface port-channel 100
(config) # interface ethernet 1/14 channel-group 100 mode active
(config) # interface ethernet 1/13 channel-group 100 mode active
(config) # interface ethernet 1/13 dcb priority-flow-control mode on force
(config) # interface ethernet 1/14 dcb priority-flow-control mode on force
(config) # vlan 4000
(config) # interface vlan 4000
(config) # interface port-channel 100 ipl 1
(config) # interface port-channel 100 dcb priority-flow-control mode on force
(config interface vlan 4000) # ip address 192.168.255.253 255.255.255.252
(config interface vlan 4000) # ipl 1 peer-address 192.168.255.254
(config) # mlag system-mac 00:00:5E:00:01:5D
(config) # no mlag shutdown

(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # lacp-individual enable force
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10

(config) # interface ethernet 1/1
(config interface ethernet 1/1) # mlag-channel-group 1 mode active
(config interface ethernet 1/1) # interface ethernet 1/1 speed 40G force
(config interface ethernet 1/1) # interface ethernet 1/1 mtu 9216 force
```