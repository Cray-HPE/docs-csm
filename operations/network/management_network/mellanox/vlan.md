# Virtual local access networks (VLANs) 

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network. 

Relevant Configuration 

Create VLAN 

```
switch(config)# vlan <VLAN> 
```

Configure an interface to associate it with a VLAN 

```
switch (config) # interface ethernet 1/22
switch (config interface ethernet 1/22) #
```

From within the interface context, configure the interface mode to Access.

```
switch (config interface ethernet 1/22) # switchport mode access
```

From within the interface context, configure the Access VLAN membership.

```
switch (config interface ethernet 1/22) # switchport access vlan 6
```

Configure an interface as a trunk port .

```
switch (config) # interface ethernet 1/35
switch (config interface ethernet 1/35) #
```

From within the interface context, configure the interface mode to Trunk.

```
switch (config interface ethernet 1/35) # switchport mode trunk
```

Show Commands to Validate Functionality 

```
switch# show vlan [VLAN]
```

Expected Results 

* Step 1: You can create a VLAN
* Step 2: You can assign a VLAN to the physical interface 

[Back to Index](../index.md)