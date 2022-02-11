# CANU 1.0 > CANU 1.2

#### Prerequisites 
- System is already running with CANU generated 1.0 configs.
- Generated Switch configs for 1.2.
    - [Generate Switch Config](generate_switch_configs.md)

### Mellanox
Compare 1.0 and 1.2 generated configs.
```
canu validate switch config --running ./1.0/sw-spine-001.cfg --generated ./1.2/sw-spine-001.cfg --vendor mellanox
- banner motd "
###############################################################################
# CSM version:  1.0
# CANU version: 1.1.10
###############################################################################
"
- vlan 7 name "CAN"
- interface vlan 7
- interface vlan 7 ip address 10.102.3.2/25 primary
- interface vlan 7 ip dhcp relay instance 2 downstream
- ip prefix-list pl-can
- ip prefix-list pl-can seq 10 permit 10.102.3.0 /25 ge 25
- route-map ncn-w001 permit 10 match ip address pl-can
- route-map ncn-w002 permit 10 match ip address pl-can
- route-map ncn-w003 permit 10 match ip address pl-can
+ banner motd "
###############################################################################
# CSM version:  1.2
# CANU version: 1.1.10
###############################################################################
"
+ vlan 6
+ vlan 7 name "CMN"
+ vlan 6 name "CAN"
+ interface mlag-port-channel 1 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 2 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 3 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 4 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 5 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 6 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 7 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 8 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 9 switchport hybrid allowed-vlan add 6
+ interface mlag-port-channel 10 switchport hybrid allowed-vlan add 7
+ interface mlag-port-channel 151 switchport hybrid allowed-vlan add 7
+ vrf definition Customer
+ vrf definition Customer rd 7:7
+ ip routing vrf Customer
+ interface vlan 7 vrf forwarding Customer
+ interface vlan 6 vrf forwarding Customer
+ interface vlan 7 ip address 10.102.3.98/25 primary
+ interface vlan 6 ip address 10.102.3.130/26 primary
+ no interface vlan 6 ip icmp redirect
+ interface vlan 6 mtu 9184
+ ipv4 access-list cmn-can
+ ipv4 access-list cmn-can bind-point rif
+ ipv4 access-list cmn-can seq-number 10 deny ip 10.102.3.0 mask 255.255.255.128 10.102.3.128 mask 255.255.255.192
+ ipv4 access-list cmn-can seq-number 20 deny ip 10.102.3.128 mask 255.255.255.192 10.102.3.0 mask 255.255.255.128
+ ipv4 access-list cmn-can seq-number 30 permit ip any any
+ interface vlan 7 ipv4 port access-group cmn-can
+ interface vlan 6 ipv4 port access-group cmn-can
+ router ospf 2 vrf Customer
+ router ospf 2 vrf Customer router-id 10.2.0.2
+ router ospf 2 vrf Customer default-information originate
+ interface vlan 7 ip ospf area 0.0.0.0
+ interface vlan 6 magp 6
+ interface vlan 6 magp 6 ip virtual-router address 10.102.3.129
+ interface vlan 6 magp 6 ip virtual-router mac-address 00:00:5E:00:01:01
+ ip prefix-list pl-cmn
+ ip prefix-list pl-cmn seq 10 permit 10.102.3.0 /25 ge 25
+ route-map ncn-w001 permit 10 match ip address pl-cmn
+ route-map ncn-w002 permit 10 match ip address pl-cmn
+ route-map ncn-w003 permit 10 match ip address pl-cmn
+ router bgp 65533 vrf Customer
+ router bgp 65533 vrf Customer router-id 10.2.0.2 force
+ router bgp 65533 vrf Customer distance 20 70 20
+ router bgp 65533 vrf Customer maximum-paths ibgp 32
+ router bgp 65533 vrf Customer maximum-paths 32
+ router bgp 65533 vrf Customer neighbor 10.102.3.8 remote-as 65534
+ router bgp 65533 vrf Customer neighbor 10.102.3.9 remote-as 65534
+ router bgp 65533 vrf Customer neighbor 10.102.3.10 remote-as 65534
+ router bgp 65533 vrf Customer neighbor 10.102.3.8 timers 1 3
+ router bgp 65533 vrf Customer neighbor 10.102.3.9 timers 1 3
+ router bgp 65533 vrf Customer neighbor 10.102.3.10 timers 1 3
+ router bgp 65533 vrf Customer neighbor 10.102.3.8 transport connection-mode passive
+ router bgp 65533 vrf Customer neighbor 10.102.3.9 transport connection-mode passive
+ router bgp 65533 vrf Customer neighbor 10.102.3.10 transport connection-mode passive
-------------------------------------------------------------------------

Config differences between running config and generated config


lines that start with a minus "-" and RED: Config that is present in running config but not in generated config
lines that start with a plus "+" and GREEN: Config that is present in generated config but not in running config.
```

The following config will need to be removed before aplying the 1.2 config

```
- banner motd "
###############################################################################
# CSM version:  1.0
# CANU version: 1.1.10
###############################################################################
"
- vlan 7 name "CAN"
- interface vlan 7
- interface vlan 7 ip address 10.102.3.2/25 primary
- interface vlan 7 ip dhcp relay instance 2 downstream
- ip prefix-list pl-can
- ip prefix-list pl-can seq 10 permit 10.102.3.0 /25 ge 25
- route-map ncn-w001 permit 10 match ip address pl-can
- route-map ncn-w002 permit 10 match ip address pl-can
- route-map ncn-w003 permit 10 match ip address pl-can
```
Remove the config, the ordering of this is important, the route map entry will need to be removed before the prefix list.
```
sw-spine-001 [mlag-domain: master] (config) # no banner motd
sw-spine-001 [mlag-domain: master] (config) # no interface vlan 7
sw-spine-001 [mlag-domain: master] (config) # no route-map ncn-w001 permit 10
sw-spine-001 [mlag-domain: master] (config) # no route-map ncn-w002 permit 10
sw-spine-001 [mlag-domain: master] (config) # no route-map ncn-w003 permit 10
sw-spine-001 [mlag-domain: master] (config) # no ip prefix-list pl-can
```
Copy in all the new config.
```
sw-spine-001 [mlag-domain: master] (config) #  banner motd "
> ###############################################################################
> # CSM version:  1.2
> # CANU version: 1.1.10
> ###############################################################################
> "
sw-spine-001 [mlag-domain: master] (config) #  vlan 6
sw-spine-001 [mlag-domain: master] (config) #  vlan 7 name "CMN"
sw-spine-001 [mlag-domain: master] (config) #  vlan 6 name "CAN"
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 1 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 2 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 3 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 4 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 5 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 6 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 7 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 8 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 9 switchport hybrid allowed-vlan add 6
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 10 switchport hybrid allowed-vlan add 7
sw-spine-001 [mlag-domain: master] (config) #  interface mlag-port-channel 151 switchport hybrid allowed-vlan add 7
sw-spine-001 [mlag-domain: master] (config) #  vrf definition Customer
sw-spine-001 [mlag-domain: master] (config) #  vrf definition Customer rd 7:7
sw-spine-001 [mlag-domain: master] (config) #  ip routing vrf Customer
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 7 vrf forwarding Customer
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 vrf forwarding Customer
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 7 ip address 10.102.3.98/25 primary
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 ip address 10.102.3.130/26 primary
sw-spine-001 [mlag-domain: master] (config) #  no interface vlan 6 ip icmp redirect
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 mtu 9184
sw-spine-001 [mlag-domain: master] (config) #  ipv4 access-list cmn-can
sw-spine-001 [mlag-domain: master] (config) #  ipv4 access-list cmn-can bind-point rif
sw-spine-001 [mlag-domain: master] (config) #  ipv4 access-list cmn-can seq-number 10 deny ip 10.102.3.0 mask 255.255.255.128 10.102.3.128 mask 255.255.255.192
sw-spine-001 [mlag-domain: master] (config) #  ipv4 access-list cmn-can seq-number 20 deny ip 10.102.3.128 mask 255.255.255.192 10.102.3.0 mask 255.255.255.128
sw-spine-001 [mlag-domain: master] (config) #  ipv4 access-list cmn-can seq-number 30 permit ip any any
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 7 ipv4 port access-group cmn-can
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 ipv4 port access-group cmn-can
sw-spine-001 [mlag-domain: master] (config) #  router ospf 2 vrf Customer
sw-spine-001 [mlag-domain: master] (config) #  router ospf 2 vrf Customer router-id 10.2.0.2
sw-spine-001 [mlag-domain: master] (config) #  router ospf 2 vrf Customer default-information originate
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 7 ip ospf area 0.0.0.0
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 magp 6
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 magp 6 ip virtual-router address 10.102.3.129
sw-spine-001 [mlag-domain: master] (config) #  interface vlan 6 magp 6 ip virtual-router mac-address 00:00:5E:00:01:01
sw-spine-001 [mlag-domain: master] (config) #  ip prefix-list pl-cmn
sw-spine-001 [mlag-domain: master] (config) #  ip prefix-list pl-cmn seq 10 permit 10.102.3.0 /25 ge 25
sw-spine-001 [mlag-domain: master] (config) #  route-map ncn-w001 permit 10 match ip address pl-cmn
sw-spine-001 [mlag-domain: master] (config) #  route-map ncn-w002 permit 10 match ip address pl-cmn
sw-spine-001 [mlag-domain: master] (config) #  route-map ncn-w003 permit 10 match ip address pl-cmn
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer router-id 10.2.0.2 force
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer distance 20 70 20
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer maximum-paths ibgp 32
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer maximum-paths 32
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.8 remote-as 65534
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.9 remote-as 65534
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.10 remote-as 65534
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.8 timers 1 3
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.9 timers 1 3
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.10 timers 1 3
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.8 transport connection-mode passive
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.9 transport connection-mode passive
sw-spine-001 [mlag-domain: master] (config) #  router bgp 65533 vrf Customer neighbor 10.102.3.10 transport connection-mode passive
```
Add the rest of the CMN config.
    - since we deleted `interface vlan 7` we'll need to add that back.
    - This is from the 1.2 generated config.
```
sw-spine-001 [mlag-domain: master] (config) # interface vlan 7 magp 7
sw-spine-001 [mlag-domain: master] (config) # interface vlan 7 magp 7 ip virtual-router address 10.102.3.1
sw-spine-001 [mlag-domain: master] (config) # interface vlan 7 magp 7 ip virtual-router mac-address 00:00:5E:00:01:01
sw-spine-001 [mlag-domain: master] (config) # no interface vlan 7 ip icmp redirect
sw-spine-001 [mlag-domain: master] (config) # interface vlan 7 mtu 9184
```
Add site connections to Customer VRF

```
interface ethernet 1/16 speed 10G force                                                                                 
interface ethernet 1/16 mtu 1500 force                                                                                  
interface ethernet 1/16 no switchport force
interface ethernet 1/16 vrf forwarding Customer                                                                             
interface ethernet 1/16 ip address 10.102.255.10/30 primary                                                                     
   ip route vrf Customer 0.0.0.0/0 10.102.255.9 
```
Save this configuration to a new config file.
```
sw-spine-002 [mlag-domain: master] (config) # configuration write to csm1.2
```
### Dell

Backup config

```
sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0.xml
```

Use CANU to see the config differences.
```
canu validate switch config --running ./1.0/sw-leaf-bmc-001.cfg --generated .//1.2/sw-leaf-bmc-001.cfg --vendor dell    
interface port-channel100
  - switchport trunk allowed vlan 2,4
  + switchport trunk allowed vlan 2,4,7
- banner motd ^
###############################################################################
# CSM version:  1.0
# CANU version: 1.1.10
###############################################################################
^
+ ip vrf Customer
+ interface vlan7
  + description CMN
  + no shutdown
  + ip vrf forwarding Customer
  + mtu 9216
  + ip address 10.102.3.100/25
  + ip access-group cmn-can in
  + ip access-group cmn-can out
  + ip ospf 2 area 0.0.0.0
+ ip access-list cmn-can
  + seq 10 deny ip 10.102.3.0/25 10.102.3.128/26
  + seq 20 deny ip 10.102.3.128/26 10.102.3.0/25
  + seq 30 permit ip any any
+ router ospf 2 vrf Customer
  + router-id 10.2.0.4
+ banner motd ^
###############################################################################
# CSM version:  1.2
# CANU version: 1.1.10
###############################################################################
^
-------------------------------------------------------------------------

Config differences between running config and generated config


lines that start with a minus "-" and RED: Config that is present in running config but not in generated config
lines that start with a plus "+" and GREEN: Config that is present in generated config but not in running config.
```

Apply new config, the ordering of this is important.  Some configuration needs to be in place before other configuration can be applied.

```
sw-leaf-bmc-001(config)# ip vrf Customer
sw-leaf-bmc-001(conf-vrf)# exit
sw-leaf-bmc-001(config)# ip access-list cmn-can
sw-leaf-bmc-001(config-ipv4-acl)# seq 10 deny ip 10.102.3.0/25 10.102.3.128/26
sw-leaf-bmc-001(config-ipv4-acl)# seq 20 deny ip 10.102.3.128/26 10.102.3.0/25
sw-leaf-bmc-001(config-ipv4-acl)# seq 30 permit ip any any
sw-leaf-bmc-001(config-ipv4-acl)# interface vlan7
sw-leaf-bmc-001(conf-if-vl-7)# description CMN
sw-leaf-bmc-001(conf-if-vl-7)# no shutdown
sw-leaf-bmc-001(conf-if-vl-7)# ip vrf forwarding Customer
sw-leaf-bmc-001(conf-if-vl-7)# mtu 9216
sw-leaf-bmc-001(conf-if-vl-7)# ip address 10.102.3.100/25
sw-leaf-bmc-001(conf-if-vl-7)# ip access-group cmn-can in
sw-leaf-bmc-001(conf-if-vl-7)# ip access-group cmn-can out
sw-leaf-bmc-001(conf-if-vl-7)# ip ospf 2 area 0.0.0.0
sw-leaf-bmc-001(config-ipv4-acl)# router ospf 2 vrf Customer
sw-leaf-bmc-001(config-router-ospf-2)# router-id 10.2.0.4
sw-leaf-bmc-001(config-router-ospf-2)# banner motd ^
Enter TEXT message.  End with the character '^'.
###############################################################################
# CSM version:  1.2
# CANU version: 1.1.10
###############################################################################
^
sw-leaf-bmc-001(config)# interface port-channel100
sw-leaf-bmc-001(conf-if-po-100)# switchport trunk allowed vlan 2,4,7
```

#### Verify Dell Config.

After the Mellanox and Dell switches have been configured you should have similar output to below.
- Two default routes.
- Four OSPF neighbors.

```
sw-leaf-bmc-001# show ip route vrf Customer
Codes: C - connected
       S - static
       B - BGP, IN - internal BGP, EX - external BGP, EV - EVPN BGP
       O - OSPF, IA - OSPF inter area, N1 - OSPF NSSA external type 1,
       N2 - OSPF NSSA external type 2, E1 - OSPF external type 1,
       E2 - OSPF external type 2, * - candidate default,
       + - summary route, > - non-active route
Gateway of last resort is via 10.102.3.98 to network 0.0.0.0
  Destination                 Gateway                                        Dist/Metric       Last Change     
----------------------------------------------------------------------------------------------------------
  *O E2 0.0.0.0/0           via 10.102.3.98          vlan7                   110/1             00:05:03
                            via 10.102.3.99          vlan7               
  C     10.102.3.0/25       via 10.102.3.100         vlan7                   0/0               00:08:50
```
```
sw-leaf-bmc-001# show ip ospf neighbor 
Neighbor ID         Pri            State             Dead Time      Address        Interface           Area
-----------------------------------------------------------------------------------------------------------------------
10.2.0.2            1              FULL/BDR          00:00:39       10.252.0.2     vlan2               0.0.0.0        
10.2.0.3            1              FULL/DROTHER      00:00:30       10.252.0.3     vlan2               0.0.0.0        
10.2.0.2            1              FULL/BDR          00:00:39       10.254.0.2     vlan4               0.0.0.0        
10.2.0.3            1              FULL/DROTHER      00:00:30       10.254.0.3     vlan4               0.0.0.0 
```
