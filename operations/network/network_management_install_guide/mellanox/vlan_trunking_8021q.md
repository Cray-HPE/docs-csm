# VLAN trunking 802.1Q 

A trunk port carries packets on one or more VLANs specified. Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header. A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID. Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped. 

Relevant Configuration 


Create a VLAN: 

```
switch (config) # vlan 100
switch (config vlan 100) #
```

Exit config mode:

```
switch (config vlan 100) # exit
switch (config) #
```

Enter the interface configuration mode:

```
switch (config) # interface ethernet 1/35
switch (config interface ethernet 1/35) #
```

From within the interface context, configure the interface mode to Hybrid:

```
switch (config interface ethernet 1/35) # switchport mode hybrid
```

From within the interface context, configure the allowed VLAN membership:

```
switch (config interface ethernet 1/35) # switchport hybrid allowed-vlan add 100
```

Expected Results 

* Step 1: You can create and enable multiple VLAN interfaces 
* Step 2: You can assign the trunk VLAN interfaces

[Back to Index](./index.md)