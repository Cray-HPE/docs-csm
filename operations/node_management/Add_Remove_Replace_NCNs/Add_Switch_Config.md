# Add Switch Config for NCN

## Description

Update the network switches for the NCN that is being added.

## Procedure

### Update Networking to Add NCN
## Example:
#### ncn-w004 IP data
```
10.102.4.15     ncn-w004.can
10.254.1.22     ncn-w004.hmn
10.1.1.11       ncn-w004.mtl
10.252.1.13     ncn-w004.nmn ncn-w004
10.254.1.21     ncn-w004-mgmt
```
#### spine-01 switch updates
```
route-map ncn-w004 permit 10 match ip address pl-can
route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15 
route-map ncn-w004 permit 20 match ip address pl-hmn
route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22  
route-map ncn-w004 permit 30 match ip address pl-nmn
route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13 

interface mlag-port-channel 12
interface ethernet 1/12 mlag-channel-group 12 mode active
interface mlag-port-channel 12 switchport mode hybrid
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 12 description "sw-spine-001:12==>ncn-w004:pcie-slot1:1"
interface mlag-port-channel 12 no shutdown
```

#### spine-02 switch updates
```
route-map ncn-w004 permit 10 match ip address pl-can
route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15 
route-map ncn-w004 permit 20 match ip address pl-hmn
route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22  
route-map ncn-w004 permit 30 match ip address pl-nmn
route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13 

interface mlag-port-channel 12
interface ethernet 1/12 mlag-channel-group 12 mode active
interface mlag-port-channel 12 switchport mode hybrid
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 12 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 12 description "sw-spine-002:12==>ncn-w004:pcie-slot1:2"
interface mlag-port-channel 12 no shutdown
```
### only workers
#### spine-01 switch updates
```
router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```
#### spine-02 switch updates
```
router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```

Proceed to the next step to [Add NCN Data](Add_NCN_Data.md) or return to the main [Add, Remove, Replace or Move NCNs](Add_Remove_Replace_NCNs.md) page.
