# Management Network ACL configuration

This page describes the purpose of the ACLs and how they are configured

# Requirements
- Access to the switches 

# Aruba Configuration

These ACLS are designed to to block traffic from the node management network to and from the hardware management network.
These need to be set where the Layer3 interface is located, this will most likely be a VSX pair of switches. These ACLS are required on both switches in the pair.

The first step is to create the access list, once it's created we have to apply it to a VLAN.
```
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

Apply ACL to a VLANs
```
sw-24g03(config)# vlan 2
sw-s24g03(config-vlan-2)# apply access-list ip nmn-hmn in
sw-s24g03(config-vlan-2)# apply access-list ip nmn-hmn out
sw-24g03(config)# vlan 4
sw-s24g03(config-vlan-4)# apply access-list ip nmn-hmn in
sw-s24g03(config-vlan-4)# apply access-list ip nmn-hmn out
```

If you are on a CDU switch you will need to apply it to the 2xxx and 3xxx VLANs

# Mellanox Configuration

```
ipv4 access-list nmn-hmn
  bind-point rif
  seq-number 10 deny ip 10.252.0.0 mask 255.255.128.0 10.254.0.0 mask 255.255.128.0
  seq-number 20 deny ip 10.252.0.0 mask 255.255.128.0 10.104.0.0 mask 255.252.0.0
  seq-number 30 deny ip 10.254.0.0 mask 255.255.128.0 10.252.0.0 mask 255.255.128.0
  seq-number 40 deny ip 10.254.0.0 mask 255.255.128.0 10.100.0.0 mask 255.252.0.0
  seq-number 50 deny ip 10.100.0.0 mask 255.252.0.0 10.254.0.0 mask 255.255.128.0
  seq-number 60 deny ip 10.100.0.0 mask 255.252.0.0 10.104.0.0 mask 255.252.0.0
  seq-number 70 deny ip 10.104.0.0 mask 255.252.0.0 10.252.0.0 mask 255.255.128.0
  seq-number 80 deny ip 10.104.0.0 mask 255.252.0.0 10.100.0.0 mask 255.252.0.0
  exit
interface vlan 2 ipv4 port access-group nmn-hmn
interface vlan 4 ipv4 port access-group nmn-hmn