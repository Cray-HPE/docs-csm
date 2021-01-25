# Management Network ACL configuration

This page describes the purpose of the ACLs and how they are configured

# Requirements
- Access to the switches 

# Configuration

These ACLS are designed to to block traffic from the node management network to and from the hardware management network.
These need to be set where the Layer3 interface is located, this will most likely be a VSX pair of switches. These ACLS are required on both switches in the pair.

The first step is to create the access list, once it's created we have to apply it to a VLAN.
```
sw-24g03(config)# access-list ip nmn-hmn
sw-24g03(config-acl-ip)# 10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
sw-24g03(config-acl-ip)# 20 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
sw-24g03(config-acl-ip)# 30 permit any any any
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