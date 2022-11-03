# Management Network Example Config

The following example configs are from a TDS system with one Hill cabinet.

This network architecture include two Aruba 8325s that are configured as VSX/MC-LAG pair, one Aruba 6300, and two Aruba 8360s for the CDU switches.

First 8325
```
sw-spine-001# show run
Current configuration:
!
!Version ArubaOS-CX GL.10.05.0020
!export-password: default
hostname sw-spine-001
allow-unsupported-transceiver
user admin group administrators password ciphertext AQBapa
no ip icmp redirect
debug bgp all
vrf keepalive
ntp server 10.254.0.8
!
!
!
ssh server vrf default
ssh server vrf mgmt
access-list ip nmn-hmn
    10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
    20 deny any 10.252.0.0/255.255.128.0 10.104.0.0/255.252.0.0
    30 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
    40 deny any 10.254.0.0/255.255.128.0 10.100.0.0/255.252.0.0
    50 deny any 10.100.0.0/255.252.0.0 10.254.0.0/255.255.128.0
    60 deny any 10.100.0.0/255.252.0.0 10.104.0.0/255.252.0.0
    70 deny any 10.104.0.0/255.252.0.0 10.252.0.0/255.255.128.0
    80 deny any 10.104.0.0/255.252.0.0 10.100.0.0/255.252.0.0
    90 permit any any any
vlan 1
vlan 2
    name RVR_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4
    name RVR_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 7
    name CAN
vlan 10
    name SUN
spanning-tree mode rpvst
spanning-tree
spanning-tree priority 7
spanning-tree bpdu-guard timeout 30
spanning-tree vlan 1,2,4,7,10
interface mgmt
    shutdown
    ip dhcp
system interface-group 3 speed 10g
    !interface group 3 contains ports 1/1/25-1/1/36
interface lag 1 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 2 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 3 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 4 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 5 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 6 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 7 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 8 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 9 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 10 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 11 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 13 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 99
    no shutdown
    description ISL link
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active
interface lag 100 multi-chassis
    no shutdown
    description leaf-VSX-1
    no routing
    vlan trunk native 1
    vlan trunk allowed all
    lacp mode active
interface lag 149 multi-chassis
    no shutdown
    description cdu0-vsx
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4
    lacp mode active
interface 1/1/1
    no shutdown
    mtu 9198
    lag 1
interface 1/1/2
    mtu 9198
interface 1/1/3
    no shutdown
    mtu 9198
    lag 2
interface 1/1/4
    mtu 9198
interface 1/1/5
    no shutdown
    mtu 9198
    lag 3
interface 1/1/6
    mtu 9198
interface 1/1/7
    no shutdown
    mtu 9198
    lag 4
interface 1/1/8
    no shutdown
    mtu 9198
    lag 5
interface 1/1/9
    no shutdown
    mtu 9198
    lag 6
interface 1/1/10
    no shutdown
    mtu 9198
    lag 7
interface 1/1/11
    no shutdown
    mtu 9198
    lag 8
interface 1/1/12
    no shutdown
    mtu 9198
    lag 9
interface 1/1/13
    no shutdown
    mtu 9198
    lag 10
interface 1/1/14
    no shutdown
    mtu 9198
    lag 11
interface 1/1/15
    no shutdown
    mtu 9198
    lag 12
interface 1/1/16
    lag 13
interface 1/1/17
    lag 14
interface 1/1/18
    no routing
    vlan access 1
interface 1/1/19
    no routing
    vlan access 1
interface 1/1/20
    no routing
    vlan access 1
interface 1/1/21
    no routing
    vlan access 1
interface 1/1/22
    no routing
    vlan access 1
interface 1/1/23
    no routing
    vlan access 1
interface 1/1/24
    no routing
    vlan access 1
interface 1/1/25
    no routing
    vlan access 1
interface 1/1/26
    no routing
    vlan access 1
interface 1/1/27
    no routing
    vlan access 1
interface 1/1/28
    no routing
    vlan access 1
interface 1/1/29
    no routing
    vlan access 1
interface 1/1/30
    no routing
    vlan access 1
interface 1/1/31
     no routing
    vlan access 1
interface 1/1/32
    no routing
    vlan access 1
interface 1/1/33
    no routing
    vlan access 1
interface 1/1/34
    no routing
    vlan access 1
interface 1/1/35
    no routing
    vlan access 1
interface 1/1/36
    no shutdown
    ip address 10.102.255.78/30
interface 1/1/37
    no routing
    vlan access 1
interface 1/1/38
    no routing
    vlan access 1
interface 1/1/39
    no routing
    vlan access 1
interface 1/1/40
    no routing
    vlan access 1
interface 1/1/41
    no routing
    vlan access 1
interface 1/1/42
    no routing
    vlan access 1
interface 1/1/43
    no routing
    vlan access 1
interface 1/1/44
    no routing
    vlan access 1
interface 1/1/45
    no routing
    vlan access 1
interface 1/1/46
    no routing
    vlan access 1
interface 1/1/47
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.0/31
interface 1/1/48
    no shutdown
    mtu 9198
    description ags01_49
    lag 100
interface 1/1/49
    no shutdown
    mtu 9198
    description cdu0sw
    lag 149
interface 1/1/50
    no shutdown
    mtu 9198
    description cdu0sw
    lag 149
interface 1/1/51
    no shutdown
    mtu 9198
    lag 99
interface 1/1/52
    no shutdown
    mtu 9198
    lag 99
interface 1/1/53
    no routing
    vlan access 1
interface 1/1/54
    no routing
    vlan access 1
interface 1/1/55
    no routing
    vlan access 1
interface 1/1/56
    no routing
    vlan access 1
interface loopback 1
interface vlan 1
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.1.0.2/16
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.1.0.1
    ip helper-address 10.92.100.222
interface vlan 2
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.252.0.2/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.252.0.1
    ip ospf 1 area 0.0.0.2
interface vlan 4
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.254.0.2/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.254.0.1
    ip ospf 1 area 0.0.0.4
interface vlan 7
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.102.11.1/24
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.102.11.111
    ip helper-address 10.92.100.222
interface vlan 10
    ip address 10.11.0.1/16
vsx
    system-mac 02:01:00:00:01:00
    inter-switch-link lag 99
    role primary
    keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global
ip route 0.0.0.0/0 10.102.255.77
ip prefix-list pl-can seq 10 permit 10.102.11.0/24 ge 24
ip prefix-list pl-hmn seq 20 permit 10.94.100.0/24 ge 24
ip prefix-list pl-nmn seq 30 permit 10.92.100.0/24 ge 24
!
!
!
!
route-map ncn-w001 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.9
route-map ncn-w001 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.15
route-map ncn-w001 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.11
route-map ncn-w002 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.8
route-map ncn-w002 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.13
route-map ncn-w002 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.10
route-map ncn-w003 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.7
route-map ncn-w003 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.11
route-map ncn-w003 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.9
!
router ospf 1
    router-id 10.252.0.2
    redistribute bgp
    area 0.0.0.2
    area 0.0.0.4
router bgp 65533
    bgp router-id 10.252.0.2
    maximum-paths 8
    distance bgp 85 70
    neighbor 10.252.0.3 remote-as 65533
    neighbor 10.252.1.7 remote-as 65533
    neighbor 10.252.1.8 remote-as 65533
    neighbor 10.252.1.9 remote-as 65533
    address-family ipv4 unicast
        neighbor 10.252.0.3 activate
        neighbor 10.252.1.7 activate
        neighbor 10.252.1.7 route-map ncn-w003 in
        neighbor 10.252.1.8 activate
        neighbor 10.252.1.8 route-map ncn-w002 in
        neighbor 10.252.1.9 activate
        neighbor 10.252.1.9 route-map ncn-w001 in
    exit-address-family
!
https-server vrf default
https-server vrf mgmt
```

Second 8325
```
sw-spine-002# show run
Current configuration:
!
!Version ArubaOS-CX GL.10.05.0020
!export-password: default
hostname sw-spine-002
allow-unsupported-transceiver
user admin group administrators password ciphertext AQBapWcbqh2GB9yAT6oln21BOY+3jKy2nth07vZLpzNwXNBVYgAAADGyXE3TJ7+ez0DzF/NNBCsaMXTyBJgqvtIvLd907Jr2JCIB9xgJ0R4qhp4Mf24L7aMJ0rXZ0DqDFS3vvz5aZ4Cj2wVu4h4kt/JV6RBpSk/j3QPSCCpj85BMUaSK11ECjXRM
no ip icmp redirect
debug lag all
vrf keepalive
ntp server 10.254.0.8
!
!
!
ssh server vrf default
ssh server vrf mgmt
access-list ip nmn-hmn
    10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
    20 deny any 10.252.0.0/255.255.128.0 10.104.0.0/255.252.0.0
    30 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
    40 deny any 10.254.0.0/255.255.128.0 10.100.0.0/255.252.0.0
    50 deny any 10.100.0.0/255.252.0.0 10.254.0.0/255.255.128.0
    60 deny any 10.100.0.0/255.252.0.0 10.104.0.0/255.252.0.0
    70 deny any 10.104.0.0/255.252.0.0 10.252.0.0/255.255.128.0
    80 deny any 10.104.0.0/255.252.0.0 10.100.0.0/255.252.0.0
    90 permit any any any
vlan 1
vlan 2
    name RVR_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4
    name RVR_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 7
    name CAN
vlan 10
    name SUN
spanning-tree mode rpvst
spanning-tree
spanning-tree priority 7
spanning-tree bpdu-guard timeout 30
spanning-tree vlan 1,2,4,7,10
interface mgmt
    shutdown
    ip dhcp
system interface-group 3 speed 10g
    !interface group 3 contains ports 1/1/25-1/1/36
interface lag 1 multi-chassis
    no shutdown
    description CMM_CAB_1000
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 2 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 3 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 4 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 5 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 6 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 7 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 8 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 9 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 10 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 11 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 12 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 13 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 14 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface lag 99
    no shutdown
    description ISL trunk
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active
interface lag 100 multi-chassis
    no shutdown
    description Leaf-VSX-1
    no routing
    vlan trunk native 1
    vlan trunk allowed all
    lacp mode active
interface lag 149 multi-chassis
    no shutdown
    description cdu0-vsx
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4
    lacp mode active
interface 1/1/1
    no shutdown
    mtu 9198
    lag 1
interface 1/1/2
    mtu 9198
interface 1/1/3
    no shutdown
    mtu 9198
    lag 2
interface 1/1/4
    mtu 9198
interface 1/1/5
    no shutdown
    mtu 9198
    lag 3
interface 1/1/6
    mtu 9198
interface 1/1/7
    no shutdown
    mtu 9198
    lag 4
interface 1/1/8
    no shutdown
    mtu 9198
    lag 5
interface 1/1/9
    no shutdown
    mtu 9198
    lag 6
interface 1/1/10
    no shutdown
    mtu 9198
    lag 7
interface 1/1/11
    no shutdown
    mtu 9198
    lag 8
interface 1/1/12
    no shutdown
    mtu 9198
    lag 9
interface 1/1/13
    no shutdown
    mtu 9198
    lag 10
interface 1/1/14
    no shutdown
    mtu 9198
    lag 11
interface 1/1/15
    no shutdown
    mtu 9198
    lag 12
interface 1/1/16
    lag 13
interface 1/1/17
    lag 14
interface 1/1/18
    no routing
    vlan access 1
interface 1/1/19
    no routing
    vlan access 1
interface 1/1/20
    no routing
    vlan access 1
interface 1/1/21
    no routing
    vlan access 1
interface 1/1/22
    no routing
    vlan access 1
interface 1/1/23
    no routing
    vlan access 1
interface 1/1/24
    no routing
    vlan access 1
interface 1/1/25
    no routing
    vlan access 1
interface 1/1/26
    no routing
    vlan access 1
interface 1/1/27
    no routing
    vlan access 1
interface 1/1/28
    no routing
    vlan access 1
interface 1/1/29
    no routing
    vlan access 1
interface 1/1/30
    no routing
    vlan access 1
interface 1/1/31
    no routing
    vlan access 1
interface 1/1/32
    no routing
    vlan access 1
interface 1/1/33
    no routing
    vlan access 1
interface 1/1/34
    no routing
    vlan access 1
interface 1/1/35
    no routing
    vlan access 1
interface 1/1/36
    no shutdown
    ip address 10.102.255.82/30
interface 1/1/37
    no routing
    vlan access 1
interface 1/1/38
    no routing
    vlan access 1
interface 1/1/39
    no routing
    vlan access 1
interface 1/1/40
    no routing
    vlan access 1
interface 1/1/41
    no routing
    vlan access 1
interface 1/1/42
    no routing
    vlan access 1
interface 1/1/43
    no routing
    vlan access 1
interface 1/1/44
    no routing
    vlan access 1
interface 1/1/45
    no routing
    vlan access 1
interface 1/1/46
    no routing
    vlan access 1
interface 1/1/47
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.1/31
interface 1/1/48
    no shutdown
    mtu 9198
    description ags01_49
    lag 100
interface 1/1/49
    no shutdown
    mtu 9198
    description cdu0sw
    lag 149
interface 1/1/50
    no shutdown
    mtu 9198
    description cdu0sw
    lag 149
interface 1/1/51
    no shutdown
    mtu 9198
    lag 99
interface 1/1/52
    no shutdown
    mtu 9198
    lag 99
interface 1/1/53
    no routing
    vlan access 1
interface 1/1/54
    no routing
    vlan access 1
interface 1/1/55
    no routing
    vlan access 1
interface 1/1/56
    no routing
    vlan access 1
interface loopback 1
interface vlan 1
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.1.0.3/16
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.1.0.1
interface vlan 2
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.252.0.3/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.252.0.1
    ip ospf 1 area 0.0.0.2
interface vlan 4
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.254.0.3/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.254.0.1
    ip ospf 1 area 0.0.0.4
interface vlan 7
    vsx-sync active-gateways
    ip mtu 9198
    ip address 10.102.11.3/24
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.102.11.111
vsx
    system-mac 02:01:00:00:01:00
    inter-switch-link lag 99
    role secondary
    keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global
ip route 0.0.0.0/0 10.102.255.81 distance 5
ip prefix-list pl-can seq 10 permit 10.102.11.0/24 ge 24
ip prefix-list pl-hmn seq 20 permit 10.94.100.0/24 ge 24
ip prefix-list pl-nmn seq 30 permit 10.92.100.0/24 ge 24
!
!
!
!
route-map ncn-w001 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.9
route-map ncn-w001 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.15
route-map ncn-w001 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.11
route-map ncn-w002 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.8
route-map ncn-w002 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.13
route-map ncn-w002 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.10
route-map ncn-w003 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.7
route-map ncn-w003 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.11
route-map ncn-w003 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.102.11.9
!
router ospf 1
    router-id 10.252.0.3
    redistribute bgp
    area 0.0.0.2
    area 0.0.0.4
router bgp 65533
    bgp router-id 10.252.0.3
    maximum-paths 8
    distance bgp 85 70
    neighbor 10.252.0.2 remote-as 65533
    neighbor 10.252.1.7 remote-as 65533
    neighbor 10.252.1.8 remote-as 65533
    neighbor 10.252.1.9 remote-as 65533
    address-family ipv4 unicast
        neighbor 10.252.0.2 activate
        neighbor 10.252.1.7 activate
        neighbor 10.252.1.7 route-map ncn-w003 in
        neighbor 10.252.1.8 activate
        neighbor 10.252.1.8 route-map ncn-w002 in
        neighbor 10.252.1.9 activate
        neighbor 10.252.1.9 route-map ncn-w001 in
    exit-address-family
!
https-server vrf default
https-server vrf mgmt
```

The 6300

```
sw-leaf-001# show run
Current configuration:
!
!Version ArubaOS-CX FL.10.05.0040
!export-password: default
hostname sw-leaf-001
user admin group administrators password ciphertext AQBapTQZPv
ntp server 10.254.0.8
!
!
!
!
ssh server vrf default
ssh server vrf mgmt
vsf member 1
    type jl663a
vlan 1
vlan 2
    name RVR_NMN
vlan 4
    name RVR_HMN
vlan 7
    name CAN
vlan 10
    name SUN
spanning-tree mode rpvst
spanning-tree
spanning-tree bpdu-guard timeout 30
spanning-tree vlan 1,2,4,7,10
interface mgmt
    no shutdown
    ip dhcp
interface lag 1
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed all
    lacp mode active
interface 1/1/1
    no shutdown
    mtu 9198
    description UAN
    no routing
    vlan trunk native 2
    vlan trunk allowed 7
interface 1/1/2
    no shutdown
    mtu 9198
    description NMN
    no routing
    vlan access 2
interface 1/1/3
    no shutdown
    mtu 9198
    description NMN
    no routing
    vlan access 2
interface 1/1/4
    no shutdown
    mtu 9198
    description NMN
    no routing
    vlan access 2
interface 1/1/5
    no shutdown
    mtu 9198
    description NMN
    no routing
    vlan access 2
interface 1/1/6
    no shutdown
    mtu 9198
    description NMN
    no routing
    vlan access 2
interface 1/1/7
    no shutdown
    no routing
    vlan access 1
interface 1/1/8
    no shutdown
    no routing
    vlan access 1
interface 1/1/9
    no shutdown
    no routing
    vlan access 1
interface 1/1/10
    no shutdown
    no routing
    vlan access 1
interface 1/1/11
    no shutdown
    no routing
    vlan access 1
interface 1/1/12
    no shutdown
    no routing
    vlan access 1
interface 1/1/13
    no shutdown
    no routing
    vlan access 1
interface 1/1/14
    no shutdown
    no routing
    vlan access 1
interface 1/1/15
    no shutdown
    no routing
    vlan access 1
interface 1/1/16
    no shutdown
    no routing
    vlan access 1
interface 1/1/17
    no shutdown
    no routing
    vlan access 1
interface 1/1/18
    no shutdown
    no routing
    vlan access 1
interface 1/1/19
    no shutdown
    no routing
    vlan access 1
interface 1/1/20
    no shutdown
    no routing
    vlan access 1
interface 1/1/21
    no shutdown
    no routing
    vlan access 1
interface 1/1/22
    no shutdown
    no routing
    vlan access 1
interface 1/1/23
    no shutdown
    no routing
    vlan access 1
interface 1/1/24
    no shutdown
    no routing
    vlan access 1
interface 1/1/25
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/26
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/27
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/28
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/29
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/30
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/31
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/32
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/33
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/34
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/35
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/36
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/37
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/38
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/39
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/40
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/41
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/42
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/43
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/44
    no shutdown
    no routing
    vlan access 1
interface 1/1/45
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/46
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/47
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/48
    no shutdown
    no routing
    vlan access 1
interface 1/1/49
    no shutdown
    mtu 9198
    description ncn-core1_48
    lag 1
interface 1/1/50
    no shutdown
    mtu 9198
    description ncn-core2_48
    lag 1
interface 1/1/51
    shutdown
    no routing
    vlan access 1
interface 1/1/52
    shutdown
    no routing
    vlan access 1
interface vlan 1
    ip address 10.1.0.4/16
    no ip dhcp
interface vlan 2
    description RIVER_NMN
    ip address 10.252.0.4/17
    ip helper-address 10.92.100.222
interface vlan 4
    description RIVER_HMN
    ip address 10.254.0.4/17
    ip helper-address 10.94.100.222
interface vlan 7
    description CAN
    ip address 10.102.11.2/24
snmp-server vrf default
snmp-server system-contact "Contact Cray Global Technical Services (C.G.T.S.)"
snmpv3 user testuser auth md5 auth-pass ciphertext AQBapflTKYh28GLx4x7Bp5XyAT0j2jnm9fDMNei1tR+BTyrqCQAAAITcQ4YsQX2noQ== priv des priv-pass ciphertext AQBapaNP67WbY49eqp0jL27tInN1FeAD9TjgkcbW31S85/SBCQAAAP6e+534mdJiaA==
ip route 0.0.0.0/0 10.102.11.111
!
!
!
!
!
https-server vrf default
https-server vrf mgmt
```

First 8360 CDU switch
```
sw-cdu-001# show run
Current configuration:
!
!Version ArubaOS-CX LL.10.06.0001
!export-password: default
hostname sw-cdu-001
user admin group administrators password ciphertext AQBapT3gxulv3VzyyLcGaKF1fZMtSAMoJzls0b2ojfJ0k9srYgAAABWZvTs5PSgj1JZenpQTO+zoKnbHsI5UaT6QSNOws1+jMSIoDAgunDoWkaRtCLkC2jQKdruZo3il1ESdzS4JNy9JmZqT9jB4QJXSl0nTJEZywQFaii7xjPZwW3UdyZPPNfMP
vrf keepalive
ntp server 10.254.0.8
ntp enable
!
!
!
ssh server vrf default
ssh server vrf mgmt
access-list ip nmn-hmn
    10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
    20 deny any 10.252.0.0/255.255.128.0 10.104.0.0/255.252.0.0
    30 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
    40 deny any 10.254.0.0/255.255.128.0 10.100.0.0/255.252.0.0
    50 deny any 10.100.0.0/255.252.0.0 10.254.0.0/255.255.128.0
    60 deny any 10.100.0.0/255.252.0.0 10.104.0.0/255.252.0.0
    70 deny any 10.104.0.0/255.252.0.0 10.252.0.0/255.255.128.0
    80 deny any 10.104.0.0/255.252.0.0 10.100.0.0/255.252.0.0
    90 permit any any any
vlan 1
vlan 2
    name RVR_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4
    name RVR_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 2000
    name CAB_1000_MTN_NMN
    description CAB_1000_MTN_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 3000
    name CAB_1000_MTN_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4091
    name CMM_RECOVERY
spanning-tree mode rpvst
spanning-tree
spanning-tree priority 11
spanning-tree bpdu-guard timeout 30
spanning-tree vlan 1,2,4,2000,3000,4091
interface mgmt
    shutdown
    ip dhcp
interface lag 2 multi-chassis
    vsx-sync vlans
    no shutdown
    description CMM_CAB_1000
    no routing
    vlan trunk native 2000
    vlan trunk allowed 2000,3000,4091
    lacp mode active
    lacp fallback
interface lag 3 multi-chassis
    vsx-sync vlans
    no shutdown
    description CMM_CAB_1000
    no routing
    vlan trunk native 2000
    vlan trunk allowed 2000,3000,4091
    lacp mode active
    lacp fallback
interface lag 99
    no shutdown
    description ISL link
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active
interface lag 149 multi-chassis
    no shutdown
    description sw-spine
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4
    lacp mode active
interface 1/1/1
    no shutdown
    mtu 9198
    description cec1
    no routing
    vlan access 3000
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/2
    no shutdown
    description cmm1
    lag 2
interface 1/1/3
    no shutdown
    description cmm3
    lag 3
interface 1/1/48
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.0/31
interface 1/1/49
    no shutdown
    description sw-spine-001_49
    lag 149
interface 1/1/50
    no shutdown
    description sw-spine-002_49
    lag 149
interface 1/1/51
    no shutdown
    mtu 9198
    lag 99
interface 1/1/52
    no shutdown
    mtu 9198
    lag 99
interface vlan 1
    description MGMT
    ip mtu 9198
    ip address 10.1.0.5/16
interface vlan 2
    ip mtu 9198
    ip address 10.252.0.5/17
    ip ospf 1 area 0.0.0.2
interface vlan 4
    ip mtu 9198
    ip address 10.254.0.5/17
    ip ospf 1 area 0.0.0.4
interface vlan 2000
    vsx-sync active-gateways
    description CAB_1000_MTN_NMN
    ip address 10.100.3.252/22
    active-gateway ip mac 02:01:00:00:01:02
    active-gateway ip 10.100.3.254
    ip helper-address 10.92.100.222
    ip ospf 1 area 0.0.0.2
    ip ospf passive
interface vlan 3000
    vsx-sync active-gateways
    description CAB_1000_MTN_HMN
    ip address 10.104.3.252/22
    active-gateway ip mac 02:01:00:00:01:02
    active-gateway ip 10.104.3.254
    ip helper-address 10.94.100.222
    ip ospf 1 area 0.0.0.4
    ip ospf passive
vsx
    system-mac 02:01:00:00:01:02
    inter-switch-link lag 99
    role primary
    keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global
!
!
!
!
!
router ospf 1
    router-id 10.252.0.5
    area 0.0.0.2
    area 0.0.0.4
https-server vrf default
https-server vrf mgmt
```

Second 8360 CDU switch

```
sw-cdu02# show run
Current configuration:
!
!Version ArubaOS-CX LL.10.06.0001
!export-password: default
hostname sw-cdu-002
user admin group administrators password ciphertext AQBap
vrf keepalive
ntp server 10.254.0.8
ntp enable
!
!
!
ssh server vrf default
ssh server vrf mgmt
access-list ip nmn-hmn
    10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
    20 deny any 10.252.0.0/255.255.128.0 10.104.0.0/255.252.0.0
    30 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
    40 deny any 10.254.0.0/255.255.128.0 10.100.0.0/255.252.0.0
    50 deny any 10.100.0.0/255.252.0.0 10.254.0.0/255.255.128.0
    60 deny any 10.100.0.0/255.252.0.0 10.104.0.0/255.252.0.0
    70 deny any 10.104.0.0/255.252.0.0 10.252.0.0/255.255.128.0
    80 deny any 10.104.0.0/255.252.0.0 10.100.0.0/255.252.0.0
    90 permit any any any
vlan 1
vlan 2
    name RVR_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4
    name RVR_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 2000
    name CAB_1000_MTN_NMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 3000
    name CAB_1000_MTN_HMN
    apply access-list ip nmn-hmn in
    apply access-list ip nmn-hmn out
vlan 4091
    name CMM_RECOVERY
spanning-tree mode rpvst
spanning-tree
spanning-tree priority 11
spanning-tree bpdu-guard timeout 30
spanning-tree vlan 1,2,4,2000,3000,4091
interface mgmt
    shutdown
    ip dhcp
interface lag 2 multi-chassis
    vsx-sync vlans
    no shutdown
    description CMM_CAB_1000
    no routing
    vlan trunk native 2000
    vlan trunk allowed 2000,3000,4091
    lacp mode active
    lacp fallback
interface lag 3 multi-chassis
    vsx-sync vlans
    no shutdown
    description CMM_CAB_1000
    no routing
    vlan trunk native 2000
    vlan trunk allowed 2000,3000,4091
    lacp mode active
    lacp fallback
interface lag 99
    no shutdown
    description ISL link
    no routing
    vlan trunk native 1 tag
    vlan trunk allowed all
    lacp mode active
interface lag 149 multi-chassis
    no shutdown
    description sw-spine
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4
    lacp mode active
    spanning-tree vlan 1 cost 203
    spanning-tree vlan 2 cost 203
    spanning-tree vlan 4 cost 203
interface 1/1/1
    description cmm1
    lag 2
interface 1/1/2
    description cmm3
    lag 3
interface 1/1/48
    no shutdown
    mtu 9198
    vrf attach keepalive
    description VSX keepalive
    ip address 192.168.255.1/31
interface 1/1/49
    no shutdown
    description sw-spine-001_50
    lag 149
interface 1/1/50
    no shutdown
    description sw-spine-002_50
    lag 149
interface 1/1/51
    no shutdown
    mtu 9198
    lag 99
interface 1/1/52
    no shutdown
    mtu 9198
    lag 99
interface vlan 1
    description MGMT
    ip mtu 9198
    ip address 10.1.0.6/16
interface vlan 2
    ip mtu 9198
    ip address 10.252.0.6/17
    ip ospf 1 area 0.0.0.2
interface vlan 4
    ip mtu 9198
    ip address 10.254.0.6/17
    ip ospf 1 area 0.0.0.4
interface vlan 2000
    vsx-sync active-gateways
    description CAB_1000_MTN_HMN
    ip address 10.100.3.253/22
    active-gateway ip mac 02:01:00:00:01:02
    active-gateway ip 10.100.3.254
    ip helper-address 10.92.100.222
    ip ospf 1 area 0.0.0.2
    ip ospf passive
interface vlan 3000
    vsx-sync active-gateways
    description CAB_1000_MTN_HMN
    ip address 10.104.3.253/22
    active-gateway ip mac 02:01:00:00:01:02
    active-gateway ip 10.104.3.254
    ip helper-address 10.94.100.222
    ip ospf 1 area 0.0.0.4
    ip ospf passive
interface vlan 4091
    description CMM_RECOVERY
vsx
    system-mac 02:01:00:00:01:02
    inter-switch-link lag 99
    role secondary
    keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
    linkup-delay-timer 600
    vsx-sync vsx-global
!
!
!
!
!
router ospf 1
    router-id 10.252.0.6
    area 0.0.0.2
    area 0.0.0.4
https-server vrf default
https-server vrf mgmt
```
