# Remove Switch Config for NCN

Update the network switches for the NCN that was removed.

## Update Networking to Remove NCN

### `ncn-w004` IP data:
```
10.102.4.15     ncn-w004.can
10.254.1.22     ncn-w004.hmn
10.1.1.11       ncn-w004.mtl
10.252.1.13     ncn-w004.nmn ncn-w004
10.254.1.21     ncn-w004-mgmt
```

### spine-01 switch updates
```
no route-map ncn-w004 permit 10 match ip address pl-can
no route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15
no route-map ncn-w004 permit 20 match ip address pl-hmn
no route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22
no route-map ncn-w004 permit 30 match ip address pl-nmn
no route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13

no interface mlag-port-channel 12
no interface ethernet 1/12 mlag-channel-group 12 mode active
no interface mlag-port-channel 12 switchport mode hybrid
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 2
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 4
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 7
no interface mlag-port-channel 12 description "sw-spine-001:12==>ncn-w004:pcie-slot1:1"
no interface mlag-port-channel 12 no shutdown
```

### spine-02 switch updates
```
no route-map ncn-w004 permit 10 match ip address pl-can
no route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15
no route-map ncn-w004 permit 20 match ip address pl-hmn
no route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22
no route-map ncn-w004 permit 30 match ip address pl-nmn
no route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13

no interface mlag-port-channel 12
no interface ethernet 1/12 mlag-channel-group 12 mode active
no interface mlag-port-channel 12 switchport mode hybrid
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 2
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 4
no interface mlag-port-channel 12 switchport hybrid allowed-vlan add 7
no interface mlag-port-channel 12 description "sw-spine-002:12==>ncn-w004:pcie-slot1:2"
no interface mlag-port-channel 12 no shutdown
```

## Worker Nodes

**These steps only need to be performed when the node removed was a worker node.**

### spine-01 switch updates
```
no router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
no router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
no router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
no router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```

### spine-02 switch updates
```
no router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
no router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
no router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
no router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```

## Next Step

Proceed to the next step to [Redeploy Services](Redeploy_Services.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
