# Shasta v1.3 to v1.4 Upgrades for Dell and Mellanox

*  The IP-Helper will reside on the switches where the default gateway for the servers, such as bmcs and computes, is configured.
*  IP-Helper applied on vlan 1 and vlan 7, this will point to 10.92.100.222.

## Dell Changes
* Remove spanning-tree bpdufilter
* Add spanning-tree bpduguard
* Remove IP-Helper if moving to a different switch.


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
Remove IP-Helper
```
sw-leaf-001# configure terminal
sw-leaf-001(config)# interface vlan 2
sw-leaf-001(conf-if-vl-2)# no ip helper-address 10.92.100.222

sw-leaf-001(config)# interface vlan 4
sw-leaf-001(conf-if-vl-4)# no ip helper-address 10.94.100.222
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

#### IP-Helper configuration
```
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