# Configuration of Spine Switch 01

Copy the following text for `sw-spine01` configuration:

> __Note:__ The username and password must be updated accordingly.

```text
##
## Running database "hpcm230223.10"
## Generated at 2023/03/09 05:59:08 +0000
## Hostname: sw-spine01
## Product release: 3.9.3210
##

##
## Running-config temporary prefix mode setting
##
no cli default prefix-modes enable

##
## MLAG protocol
##
   protocol mlag

##
## Interface Ethernet configuration
##
   interface mlag-port-channel 1-9
   interface mlag-port-channel 15
   interface port-channel 100
   interface ethernet 1/1-1/9 speed 40G force
   interface ethernet 1/13-1/14 speed 40G force
   interface ethernet 1/15 speed 10G force
   interface ethernet 1/1 mlag-channel-group 1 mode active
   interface ethernet 1/2 mlag-channel-group 2 mode active
   interface ethernet 1/3 mlag-channel-group 3 mode active
   interface ethernet 1/4 mlag-channel-group 4 mode active
   interface ethernet 1/5 mlag-channel-group 5 mode active
   interface ethernet 1/6 mlag-channel-group 6 mode active
   interface ethernet 1/7 mlag-channel-group 7 mode active
   interface ethernet 1/8 mlag-channel-group 8 mode active
   interface ethernet 1/9 mlag-channel-group 9 mode active
   interface ethernet 1/13-1/14 channel-group 100 mode active
   interface ethernet 1/15 mlag-channel-group 15 mode on
   interface mlag-port-channel 1 switchport mode hybrid
   interface mlag-port-channel 2 switchport mode hybrid
   interface mlag-port-channel 3 switchport mode hybrid
   interface mlag-port-channel 4 switchport mode hybrid
   interface mlag-port-channel 5 switchport mode hybrid
   interface mlag-port-channel 6 switchport mode hybrid
   interface mlag-port-channel 7 switchport mode hybrid
   interface mlag-port-channel 8 switchport mode hybrid
   interface mlag-port-channel 9 switchport mode hybrid
   interface mlag-port-channel 15 switchport mode hybrid
   interface ethernet 1/13 description "sw-spine02-1/10"
   interface ethernet 1/14 description "sw-spine02-1/12"
   interface port-channel 100 description "mlag-isl"
   interface mlag-port-channel 1-9 no shutdown
   interface mlag-port-channel 15 no shutdown

##
## LAG configuration
##
   lacp
   interface mlag-port-channel 1-9 lacp-individual enable force
   port-channel load-balance ethernet source-destination-ip ingress-port

##
## VLAN configuration
##
   vlan 1999
   vlan 4000
   vlan 4091
   vlan 1999 name "OSPF"
   vlan 4000 name "MLAG"
   vlan 4091 name "CMM_RECOVERY"
   interface mlag-port-channel 15 switchport hybrid allowed-vlan add 1999
   interface mlag-port-channel 15 switchport hybrid allowed-vlan add 4091

##
## STP configuration
##
   spanning-tree mode rpvst
   spanning-tree port type edge default
   interface mlag-port-channel 1-9 spanning-tree port type edge
   interface mlag-port-channel 15 spanning-tree port type network
   interface mlag-port-channel 15 spanning-tree guard root
   spanning-tree port type edge bpdufilter default
   spanning-tree port type edge bpduguard default
   spanning-tree vlan 1 priority 0

##
## L3 configuration
##
   vrf definition mgmt
   ip routing vrf default
   interface vlan 1
   interface vlan 1999
   interface vlan 4000
   interface vlan 1 ip address 10.1.0.2/16 primary
   interface vlan 1999 ip address 1.1.255.252/16 primary
   interface vlan 4000 ip address 1.2.0.1/30 primary
   ip load-sharing source-ip-port
   ip load-sharing type consistent

##
## DCBX PFC configuration
##
   dcb priority-flow-control enable force
   interface port-channel 100 dcb priority-flow-control mode on force

##
## OSPF configuration
##
   protocol ospf
   router ospf 1 vrf default
   router ospf 1 vrf default router-id 1.1.255.252
   interface vlan 1999 ip ospf area 0.0.0.0
   interface vlan 1999 ip ospf priority 254

##
## MAGP configuration
##
   protocol magp
   interface vlan 1 magp 1
   interface vlan 1 magp 1 ip virtual-router address 10.1.0.254
   interface vlan 1 magp 1 ip virtual-router mac-address 00:00:5E:01:01:55

##
## MLAG configurations
##
no mlag shutdown
   mlag system-mac 00:00:5E:00:01:5D
   interface port-channel 100 ipl 1
   interface vlan 4000 ipl 1 peer-address 1.2.0.2

##
## Other IP configuration
##
   hostname sw-spine-001
   ip domain-list local

##
## Local user account configuration
##
   username [ADMIN] password [PASSWORD]
   username [MONITOR] password [PASSWORD]

##
## AAA remote server configuration
##
# ldap bind-password ********
   ldap vrf mgmt enable
   radius-server vrf mgmt enable
# radius-server key ********
   tacacs-server vrf mgmt enable
# tacacs-server key ********

##
## Password restriction configuration
##
no password hardening enable

##
## SNMP configuration
##
   snmp-server vrf mgmt enable

##
## Network management configuration
##
# web proxy auth basic password ********
no ntp server 10.1.0.5 disable
   ntp server 10.1.0.5 keyID 0
no ntp server 10.1.0.5 trusted-enable
   ntp server 10.1.0.5 version 4
   ntp vrf mgmt enable
   web vrf mgmt enable

##
## X.509 certificates configuration
##
#
# Certificate name system-self-signed, ID f06e069b6d007764b95fc9f3f1b383af194aaf8d
# (public-cert config omitted since private-key config is hidden)

##
## Persistent prefix mode setting
##
cli default prefix-modes enable
```
