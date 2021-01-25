# Management Network Access Port configurations.

# Requirements
- Access to switches
- SHCD

# Configuration

This configuration describes the ports that go to the Hardware Management Network (HMN/VLAN4).
Typically these are ports that are connected to iLOs (BMCs) or gateway nodes.
You can Identify these ports by referencing the HMN tab on the SHCD.

```
sw-smn01(config)#  interface 1/1/28
sw-smn01(config)# no shutdown 
sw-smn01(config)# mtu 9198
sw-smn01(config)# description HMN
sw-smn01(config)# no routing
sw-smn01(config)# vlan access 4
```

This configuration describes the ports that go to the Node Management Network (NMN/VLAN2).
You can Identify these ports by referencing the NMN tab on the SHCD.

```
sw-smn01(config)# interface 1/1/6
sw-smn01(config)# no shutdown 
sw-smn01(config)# mtu 9198
sw-smn01(config)# description NMN
sw-smn01(config)# no routing
sw-smn01(config)# vlan access 2
```
