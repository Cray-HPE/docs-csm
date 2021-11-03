

# Configure Mellanox Spine Switch

This page describes how Mellanox spine switches are configured.

Depending on the size of the HPE Cray EX system, the spine switches will serve different purposes. On TDS systems, the NCNs will plug directly into the spine switches. On larger systems with aggregation switches, the spine switches will provide connection between the aggregation switches.

## Prerequisites

- One connection between the switches is used for the Inter switch link (ISL).
- Connectivity to the switch is established.

Here is an example snippet about a spine switch from the SHCD.

The ISL ports are port 32 on both spine switches.

| Source | Source Label Info | Destination Label Info | Destination | Description |
| --- | --- | --- | --- | --- |
| sw-100g01 | x3105u40-j32 | x3105u41-j32 | sw-100g02 | 100g-1m-DAC |


## Configure VLAN

**Cray Site Init (CSI) generates the IP addresses used by the system, below are samples only.**
The VLAN information is located in the network YAML files. The following are examples.

1. Verify the spine switches have VLAN interfaces in NMN, HMN, and CAN networks.
   
   Example NMN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/NMN.yaml
   SNIPPET
     - ip_address: 10.252.0.2
       name: sw-spine-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.252.0.3
       name: sw-spine-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: NMN
     vlan_id: 2
     comment: ""
     gateway: 10.252.0.1
   ```

   Example HMN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/HMN.yaml
   SNIPPET
     - ip_address: 10.254.0.2
       name: sw-spine-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.254.0.3
       name: sw-spine-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: HMN
     vlan_id: 4
     comment: ""
     gateway: 10.254.0.1
   ```

   Example CAN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/CAN.yaml
   SNIPPET
     - ip_address: 10.102.11.2
       name: can-switch-1
       comment: ""
       aliases: []
     - ip_address: 10.102.11.3
       name: can-switch-2
       comment: ""
       aliases: []
     net-name: CAN
     vlan_id: 7
     comment: ""
     gateway: 10.102.11.1
   ```

   The following is an example of spine switch IP addressing based on the network .yaml files from above.

   | VLAN | Spine01 | Spine02 | Purpose |
   | --- | --- | ---| --- |
   | 2 | 10.252.0.2/17| 10.252.0.3/17 | River Node Management |
   | 4 | 10.254.0.2/17| 10.254.0.3/17 | River Hardware Management |
   | 7 | 10.102.11.2/24| 10.102.11.3/24 | Customer Access |


## Configure MAGP

MAGP setup for Mellanox spine switches. This should be set for every VLAN interface (1,2,4,7,10).

See https://community.mellanox.com/s/article/howto-configure-magp-on-mellanox-switches for more information.

1. Enable MAGP protocol.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
   protocol magp
   ```

## Configure DHCP

IP-Helpers will reside on VLANs 1,2,4, and 7.

1. Add DHCP configuration.

   ```bash
   ## DHCP relay configuration
   ##
      ip dhcp relay instance 2 vrf default
      ip dhcp relay instance 4 vrf default
      ip dhcp relay instance 2 address 10.92.100.222
      ip dhcp relay instance 4 address 10.94.100.222
      interface vlan 1 ip dhcp relay instance 2 downstream
      interface vlan 2 ip dhcp relay instance 2 downstream
      interface vlan 4 ip dhcp relay instance 4 downstream
      interface vlan 7 ip dhcp relay instance 2 downstream
   ```

## Configure OSPF

OSPF is a dynamic routing protocol used to exchange routes.
It provides reachability from the MTN networks to NMN/Kubernetes networks.
The router-id used here is the NMN IP address (VLAN 2 IP).

1. Configure OSPF.
   
   ```bash
   sw-spine-001 & sw-spine-002 (config)#
   protocol ospf
   router ospf 1 vrf default
   interface vlan 2 ip ospf area 0.0.0.2
   interface vlan 4 ip ospf area 0.0.0.4
   interface vlan 2 ip ospf priority 254
   interface vlan 4 ip ospf priority 254
   ```

1. Set the NMN VLAN configuration.

   ```bash
   sw-spine-001(config)#
         vlan 2
         interface vlan 2
         interface vlan 2 ip address 10.252.0.2/17 primary
         interface vlan 2 ipv4 port access-group nmn-hmn
         interface vlan 2 ip ospf area 0.0.0.2
         interface vlan 2 ip ospf priority 254
         interface vlan 2 ip dhcp relay instance 2 downstream
         interface vlan 2 magp 2
         interface vlan 2 magp 2 ip virtual-router address 10.252.0.1
         interface vlan 2 magp 2 ip virtual-router mac-address 00:00:5E:00:01:02

   sw-spine-002(config)#
         vlan 2
         interface vlan 2
         interface vlan 2 ip address 10.252.0.3/17 primary
         interface vlan 2 ipv4 port access-group nmn-hmn
         interface vlan 2 ip ospf area 0.0.0.2
         interface vlan 2 ip ospf priority 254
         interface vlan 2 ip dhcp relay instance 2 downstream
         interface vlan 2 magp 2
         interface vlan 2 magp 2 ip virtual-router address 10.252.0.1
         interface vlan 2 magp 2 ip virtual-router mac-address 00:00:5E:00:01:02
   ```

1. Set the HMN VLAN configuration.

   ```bash
   sw-spine-001(config)#
         vlan 4
         interface vlan 4
         interface vlan 4 ip address 10.254.0.2/17 primary
         interface vlan 4 ipv4 port access-group nmn-hmn
         interface vlan 4 ip ospf area 0.0.0.4
         interface vlan 4 ip ospf priority 254
         interface vlan 4 ip dhcp relay instance 4 downstream
         interface vlan 4 magp 4
         interface vlan 4 magp 4 ip virtual-router address 10.254.0.1
         interface vlan 4 magp 4 ip virtual-router mac-address 00:00:5E:00:01:04

   sw-spine-002(config)#
         vlan 4
         interface vlan 4
         interface vlan 4 ip address 10.254.0.3/17 primary
         interface vlan 4 ipv4 port access-group nmn-hmn
         interface vlan 4 ip ospf area 0.0.0.4
         interface vlan 4 ip ospf priority 254
         interface vlan 4 ip dhcp relay instance 4 downstream
         interface vlan 4 magp 4
         interface vlan 4 magp 4 ip virtual-router address 10.254.0.1
         interface vlan 4 magp 4 ip virtual-router mac-address 00:00:5E:00:01:04
       exit
   ```

1. Set the CAN VLAN configuration.

   ```bash
   sw-spine-001(config)#
         vlan 7
         interface vlan 7 ip address 10.101.8.2/24 primary
         interface vlan 7 ip dhcp relay instance 2 downstream
         interface vlan 7 magp 7
         interface vlan 7 magp 7 ip virtual-router address 10.101.8.1
         interface vlan 7 magp 7 ip virtual-router mac-address 00:00:5E:00:01:07

   sw-spine-002(config)#
         vlan 7
         interface vlan 7 ip address 10.101.8.3/24 primary
         interface vlan 7 ip dhcp relay instance 2 downstream
         interface vlan 7 magp 7
         interface vlan 7 magp 7 ip virtual-router address 10.101.8.1
         interface vlan 7 magp 7 ip virtual-router mac-address 00:00:5E:00:01:07
   ```

## Configure MLAG

These two ports are cabled between the Mellanox switches.


#### Spine01


```bash
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
```

#### Spine02


```bash
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
```

Adding MLAG ports (these ports go to NCNs/UANs/switch downlinks).


#### Spine01


```bash
(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # lacp-individual enable force
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10
```

#### Spine02

**NOTE:** 'lacp fallback' is only on one of the Spines.
Disable "lacp-individual enable force" on Spine02 if it was set previously.

```bash
(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # no lacp-individual enable force
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10
```

Add ports to the MLAG after it is created:

```bash
(config) # interface ethernet 1/1
(config interface ethernet 1/1) # mlag-channel-group 1 mode active
(config interface ethernet 1/1) # interface ethernet 1/1 speed 40G force
(config interface ethernet 1/1) # interface ethernet 1/1 mtu 9216 force
```

Configuration with Recommended MLAG-VIP cable.

- This is recommended by Mellanox but not required.
- Its purpose is to prevent "split brain" which is where both spines think they are the active gateway.
- It requires an RJ45 cable between the mgmt0 ports on both switches.
- https://community.mellanox.com/s/article/how-to-configure-mlag-on-mellanox-switches#jive_content_id_MLAG_VIP

**NOTE:** Replace the SYSTEM_NAME value that is part of the mlag-vip name in the following examples with the actual name of the system.


#### Spine01

```
no interface mgmt0 dhcp
   interface mgmt0 ip address 192.168.255.241 /29
no mlag shutdown
   mlag system-mac 00:00:5E:00:01:5D
mlag-vip SYSTEM_NAME-mlag-domain ip 192.168.255.242 /29 force
```

#### Spine02

```
no interface mgmt0 dhcp
   interface mgmt0 ip address 192.168.255.243 /29
no mlag shutdown
   mlag system-mac 00:00:5E:00:01:5D
mlag-vip SYSTEM_NAME-mlag-domain ip 192.168.255.242 /29 force
```

Verify the mlag-vip:

```bash
sw-spine-001 [SYSTEM_NAME-mlag-domain: master] # show mlag-vip
MLAG-VIP:
 MLAG group name: SYSTEM_NAME-mlag-domain
 MLAG VIP address: 192.168.255.242/29
 Active nodes: 2

----------------------------------------------------------------------------------
Hostname                                 VIP-State            IP Address
----------------------------------------------------------------------------------
sw-spine-001                               master               192.168.255.241
sw-spine-002                               standby              192.168.255.243
```

## Configure ACL

These ACLs are designed to block traffic from the Node Management Network (NMN) to and from the Hardware Management Network (HMN).

1. Create the access list.

   **NOTE:** The following are examples only. The IP addresses below need to match what was generated by CSI.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
   sw-spine-001(config) # ipv4 access-list nmn-hmn
   sw-spine-001(config ipv4 access-list nmn-hmn) # bind-point rif
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 10 deny ip 10.252.0.0 mask 255.255.128.0 10.254.0.0 mask 255.255.128.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 20 deny ip 10.252.0.0 mask 255.255.128.0 10.104.0.0 mask 255.252.0.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 30 deny ip 10.254.0.0 mask 255.255.128.0 10.252.0.0 mask 255.255.128.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 40 deny ip 10.254.0.0 mask 255.255.128.0 10.100.0.0 mask 255.252.0.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 50 deny ip 10.100.0.0 mask 255.252.0.0 10.254.0.0 mask 255.255.128.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 60 deny ip 10.100.0.0 mask 255.252.0.0 10.104.0.0 mask 255.252.0.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 70 deny ip 10.104.0.0 mask 255.252.0.0 10.252.0.0 mask 255.255.128.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 80 deny ip 10.104.0.0 mask 255.252.0.0 10.100.0.0 mask 255.252.0.0
   sw-spine-001(config ipv4 access-list nmn-hmn) # seq-number 90 permit ip any any
   sw-spine-001(config ipv4 access-list nmn-hmn) # exit
   ```

1. Apply ACL to VLANs.

   ```bash
   sw-spine-001(config) # interface vlan 2 ipv4 port access-group nmn-hmn
   sw-spine-001(config) # interface vlan 4 ipv4 port access-group nmn-hmn
   ```

## Configure Spanning-Tree

Spanning-tree will need to be applied to each MAGP pair. Spine01 will have a lower priority making it the root bridge.
Spanning-tree configuration has not changed from 1.3 to 1.5.

1. Apply the following configuration to the Mellanox spine switches. 
   
   This is an example of a switch-to-switch connection.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
   spanning-tree mode rpvst
   spanning-tree port type edge default
   interface ethernet 1/13-1/14 spanning-tree port type network
   interface ethernet 1/15/1-1/15/2 spanning-tree port type network
   interface mlag-port-channel 113 spanning-tree port type network
   interface mlag-port-channel 151-152 spanning-tree port type network
   interface ethernet 1/13-1/14 spanning-tree guard root
   interface ethernet 1/15/1-1/15/2 spanning-tree guard root
   interface mlag-port-channel 113 spanning-tree guard root
   interface mlag-port-channel 151-152 spanning-tree guard root
   spanning-tree port type edge bpdufilter default
   spanning-tree port type edge bpduguard default
   spanning-tree vlan 1-2 priority 0
   spanning-tree vlan 4 priority 0
   spanning-tree vlan 7 priority 0
   spanning-tree vlan 10 priority 0
   ```

## Configure NTP

The IP addresses used here will be the first three worker nodes on the NMN network. These can be found in NMN.yaml.

1. Get current NTP configuration.

   ```bash
   sw-spine-001 [standalone: master] (config) # show running-config | include ntp
   no ntp server 10.252.1.9 disable
      ntp server 10.252.1.9 keyID 0
   no ntp server 10.252.1.9 trusted-enable
      ntp server 10.252.1.9 version 4
   no ntp server 10.252.1.10 disable
      ntp server 10.252.1.10 keyID 0
   no ntp server 10.252.1.10 trusted-enable
      ntp server 10.252.1.10 version 4
   no ntp server 10.252.1.11 disable
      ntp server 10.252.1.11 keyID 0
   no ntp server 10.252.1.11 trusted-enable
      ntp server 10.252.1.11 version 4
   ```

1. Delete any current NTP configuration.

   ```bash
   sw-spine-001# configure terminal
   sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.9
   sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.10
   sw-spine-001 [standalone: master] (config) # no ntp server 10.252.1.11
   ```

1. Add new NTP server configuration.

   ```bash
   sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.12
   sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.13
   sw-spine-001 [standalone: master] (config) # ntp server 10.252.1.14
   ```

1. Verify NTP status.

   ```bash
   sw-spine-001 [standalone: master] # show ntp

   NTP is administratively            : enabled
   NTP Authentication administratively: disabled
   NTP server role                    : enabled

   Clock is synchronized:
     Reference: 10.252.1.14
     Offset   : -0.056 ms

   Active servers and peers:
     10.252.1.12:
       Conf Type          : serv
       Status             : candidat(+)
       Stratum            : 4
       Offset(msec)       : -0.119
       Ref clock          : 10.252.1.4
       Poll Interval (sec): 128
       Last Response (sec): 107
       Auth state         : none

     10.252.1.13:
       Conf Type          : serv
       Status             : candidat(+)
       Stratum            : 4
       Offset(msec)       : -0.059
       Ref clock          : 10.252.1.4
       Poll Interval (sec): 128
       Last Response (sec): 96
       Auth state         : none

     10.252.1.14:
       Conf Type          : serv
       Status             : sys.peer(*)
       Stratum            : 4
       Offset(msec)       : -0.056
       Ref clock          : 10.252.1.4
       Poll Interval (sec): 128
       Last Response (sec): 118
       Auth state         : none
   ```

## Configure DNS

1. Configure DNS.
   
   This will point to the unbound DNS server.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
   ip name-server 10.92.100.225
   ```

1. Verify the configuration.

   ```bash
   sw-spine-002 [standalone: master] # show ip dhcp relay

   Instance ID 2:
     VRF Name: default

     DHCP Servers:
       10.92.100.222

     DHCP relay agent options:
       always-on         : Disabled
       Information Option: Disabled
       UDP port          : 67
       Auto-helper       : Disabled

     -------------------------------------------
     Interface   Label             Mode
     -------------------------------------------
     vlan1       N/A               downstream
     vlan2       N/A               downstream
     vlan7       N/A               downstream

   Instance ID 4:
     VRF Name: default

     DHCP Servers:
       10.94.100.222

     DHCP relay agent options:
       always-on         : Disabled
       Information Option: Disabled
       UDP port          : 67
       Auto-helper       : Disabled

     -------------------------------------------
     Interface   Label             Mode
     -------------------------------------------
     vlan4       N/A               downstream
   ```


## Save Configuration

1. Save the changes made during this configuration session.

   ```bash
   sw-spine-001(config)# exit
   sw-spine-001# write memory
   ```


## Show Running Configuration

1. Show the current configuration

   ```bash
   sw-spine-001# show running-config
   ```


