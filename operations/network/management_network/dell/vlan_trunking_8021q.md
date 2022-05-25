# VLAN trunking 802.1Q

A trunk port carries packets on one or more VLANs specified. Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header. A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID. Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped.

Relevant Configuration

Configure an interface as a trunk port

```
switch(config-if)# switchport mode trunk
```

Add your allowed VLANs

```
switch(config-if)#switchport trunk allowed vlan add 1,50,100
```

Assign a native VLAN

```
switch(config-if)# switchport trunk native vlan-id 1
```

Show Commands to Validate Functionality

```
switch# show interfaces switchport
```

Expected Results

* Step 1: You can create and enable multiple VLAN interfaces
* Step 2: You can assign the trunk VLAN interfaces


[Back to Index](../index.md)

