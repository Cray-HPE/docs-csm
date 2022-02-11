# VLAN Trunking 802.1Q 

A trunk port carries packets on one or more VLANs specified. Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header. A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID. Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped. 

## Configuration Commands

Configure an interface as a trunk port: 

```bash
switch(config-if)# vlan trunk allowed VLANS
```

Show commands to validate functionality:  

```bash
switch# show vlan [VLAN-ID]
```

## Example Output 

```bash
switch(config)# vlan 10
switch(config-vlan-10)# no shutdown
switch(config-vlan-10)# exit
switch(config)# vlan 20
switch(config-vlan-20)# no shutdown
switch(config-vlan-20)# exit
switch(config)# interface 1/1/1
switch(config-if)# no shutdown
switch(config-if)# no routing
switch(config-if)# vlan trunk native 10
switch(config-if)# vlan trunk allowed 10,20
switch(config-if)# end
```

## Expected Results 

1. Administrators can create and enable multiple VLAN interfaces 
2. Administrators can assign the trunk VLAN interfaces


[Back to Index](../index.md)