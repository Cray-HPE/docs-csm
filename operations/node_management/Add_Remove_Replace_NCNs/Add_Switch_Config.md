# Add Switch Config for NCN

## Description

Update the network switches for the NCN that is being added.

## Procedure

### Update Networking to Add NCN

## Example

`ncn-w004` IP data:

```text
10.102.4.15     ncn-w004.can
10.254.1.22     ncn-w004.hmn
10.1.1.11       ncn-w004.mtl
10.252.1.13     ncn-w004.nmn ncn-w004
10.254.1.21     ncn-w004-mgmt
```

## Mellanox and Dell

### Spine/Agg Switch Updates

[spine/agg edge port configuration](../../../install/configure_mellanox_spine_switch.md#Configure-MLAG)

### Spine BGP Updates

The configuration will be the same across both switches.

This is for workers only.

For more information, see [Update BGP Neighbors](../../network/metallb_bgp/Update_BGP_Neighbors.md).

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

### BMC Port Configuration

[Dell edge port configuration](../../../install/configure_dell_leaf_switch.md#Configure-Edge-Port)

## Aruba

### Spine/Agg Switch Updates

[spine/agg edge port configuration](../../../install/configure_aruba_spine_switch.md#Configure-Edge-Port)

### Spine BGP Updates

The configuration will be the same across both switches.

This is for workers only.

For more information, see [Update BGP Neighbors](../../network/metallb_bgp/Update_BGP_Neighbors.md).

- The `tftp` route maps will only include the first 3 workers.

```
route-map ncn-w004 permit seq 10
     match ip address prefix-list tftp
     match ip next-hop $worker1.nmn.ip
     set local-preference 1000
route-map ncn-w004 permit seq 20
     match ip address prefix-list tftp
     match ip next-hop $worker2.nmn.ip
     set local-preference 1100
route-map ncn-w004 permit seq 30
     match ip address prefix-list tftp
     match ip next-hop $worker3.nmn.ip
     set local-preference 1200
route-map ncn-w004 permit seq 40
     match ip address prefix-list pl-can
     set ip next-hop 10.102.4.15 ($worker4.can.ip)
route-map ncn-w004 permit seq 50
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.1.13 ($worker4.hmn.ip)
route-map ncn-w004 permit seq 60
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.1.13 ($worker4.nmn.ip)
router bgp 65533
    neighbor 10.252.1.13 ($worker4.nmn.ip) remote-as 65533
    neighbor 10.252.1.13 ($worker4.nmn.ip) passive
    address-family ipv4 unicast
        neighbor 10.252.1.13 ($worker4.nmn.ip) activate
        neighbor 10.252.1.13 ($worker4.nmn.ip) route-map ncn-w004 in
```

### BMC Port Configuration

Refer to [Aruba edge port configuration](../../../install/configure_aruba_leaf_switch.md#Configure-Edge-Port) for more information.

Proceed to the next step to [Add NCN Data](Add_NCN_Data.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
