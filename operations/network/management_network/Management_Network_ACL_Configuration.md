# Management Network ACL Configuration

This page describes the purpose of the ACLs and how they are configured.

## Requirements
- Access to the switches

## Aruba Configuration

These ACLs are designed to block traffic from the Node Management Network (NMN) to and from the Hardware Management Network (HMN).

These need to be set where the Layer3 interface is located, this will most likely be a VSX pair of switches. These ACLs are required on both switches in the pair.

1. Create the access list.

    ```bash
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
    ```

    Once it is created, it needs to be applied to a VLAN.

1. Apply ACL to a VLANs:

    ```bash
    sw-24g03(config)# vlan 2
    sw-s24g03(config-vlan-2)# apply access-list ip nmn-hmn in
    sw-s24g03(config-vlan-2)# apply access-list ip nmn-hmn out
    sw-24g03(config)# vlan 4
    sw-s24g03(config-vlan-4)# apply access-list ip nmn-hmn in
    sw-s24g03(config-vlan-4)# apply access-list ip nmn-hmn out
    ```

    If on an Aruba CDU switch, apply the same access-list to the 2xxx and 3xxx VLANs (MTN VLANs).

## Mellanox Configuration

Create the `nmn-hmn` `access-list` and apply it to `vlan 2` and `vlan 4`.

```
sw-spine-001> enable
sw-spine-001# configure terminal
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
sw-spine-001(config) # interface vlan 2 ipv4 port access-group nmn-hmn
sw-spine-001(config) # interface vlan 4 ipv4 port access-group nmn-hmn
sw-spine-001(config) # exit
sw-spine-001# write memory
```

## Dell Configuration

Create the access list then apply it to all the `vlan` interfaces. In the example below, only the NMN VLAN is shown. This will need to go on all liquid-cooled and air-cooled networks.

```
ip access-list nmn-hmn
 seq 10 deny ip 10.252.0.0/17 10.254.0.0/17
 seq 20 deny ip 10.252.0.0/17 10.104.0.0/14
 seq 30 deny ip 10.254.0.0/17 10.252.0.0/17
 seq 40 deny ip 10.254.0.0/17 10.100.0.0/14
 seq 50 deny ip 10.100.0.0/14 10.254.0.0/17
 seq 60 deny ip 10.100.0.0/14 10.104.0.0/14
 seq 70 deny ip 10.104.0.0/14 10.252.0.0/17
 seq 80 deny ip 10.104.0.0/14 10.100.0.0/14
 seq 90 permit ip any any
```

```
interface vlan2
 ip access-group nmn-hmn in
 ip access-group nmn-hmn out
```

