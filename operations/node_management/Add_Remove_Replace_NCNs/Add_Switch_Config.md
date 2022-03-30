# Add Switch Config for NCN

## Description

Update the network switches for the NCN that is being added.

## Procedure

### Update Networking to Add NCN
## Example:
#### ncn-w004 IP data

```text
10.102.4.15     ncn-w004.can
10.254.1.22     ncn-w004.hmn
10.1.1.11       ncn-w004.mtl
10.252.1.13     ncn-w004.nmn ncn-w004
10.254.1.21     ncn-w004-mgmt
```

## Mellanox & Dell

### Spine/Agg switch updates

[spine/agg edge port configuration](../../../install/configure_mellanox_spine_switch.md#Configure-MLAG)

### only workers

### spine-01 switch updates

```text
route-map ncn-w004 permit 10 match ip address pl-can
route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15 
route-map ncn-w004 permit 20 match ip address pl-hmn
route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22  
route-map ncn-w004 permit 30 match ip address pl-nmn
route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13 
router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```

#### spine-02 switch updates

```text
route-map ncn-w004 permit 10 match ip address pl-can
route-map ncn-w004 permit 10 set ip next-hop 10.102.4.15 
route-map ncn-w004 permit 20 match ip address pl-hmn
route-map ncn-w004 permit 20 set ip next-hop 10.254.1.22  
route-map ncn-w004 permit 30 match ip address pl-nmn
route-map ncn-w004 permit 30 set ip next-hop 10.252.1.13 
router bgp 65533 vrf default neighbor 10.252.1.13 remote-as 65533
router bgp 65533 vrf default neighbor 10.252.1.13 route-map ncn-w004
router bgp 65533 vrf default neighbor 10.252.1.13 timers 1 3
router bgp 65533 vrf default neighbor 10.252.1.13 transport connection-mode passive
```

## Aruba

### spine-01 switch updates

[spine/agg edge port configuration](../../../install/configure_aruba_spine_switch.md#Configure-Edge-Port)

Proceed to the next step to [Add NCN Data](Add_NCN_Data.md) or return to the main [Add, Remove, Replace or Move NCNs](Add_Remove_Replace_NCNs.md) page.
