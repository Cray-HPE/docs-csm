# Virtual local access networks (VLANs) 

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network. 


Relevant Configuration 

Create VLAN 

```
switch(config)# vlan <VLAN> 
```

Configure an interface to associate it with a VLAN 

```
switch(config)# interface <IFACE> 
switch(config-if)# no shutdown 
switch(config-if)# no routing

```
Configure an interface as an access port

```
switch(config-if)# vlan access VLAN 
```

Configure an interface as a trunk port 

```
switch(config-if)# vlan trunk native <VLAN> 
switch(config-if)# vlan trunk allowed <VLAN> 
```

Configure VLAN as Voice: 

NOTE:
To give a specific VLAN a voice designation and adding the proper hooks, you need to add voice command in the vlan context. This configuration is the same for all CX-series switches.

```
switch(config)# vlan <VLAN> 
switch(config-vlan-100)# voice 
```

Show Commands to Validate Functionality 

```
switch# show vlan [VLAN]
```

Example Output 

```
switch# show vlan
--------------------------------------------------------------------------------------
VLAN  Name                              Status  Reason          Type      Interfaces
--------------------------------------------------------------------------------------
1     DEFAULT_VLAN_1                    up      no_member_port  static    1/1/2
10    VLAN10                            up      ok              static    1/1/1-1/1/2
```

Expected Results 

* Step 1: You can create a VLAN
* Step 2: You can assign a VLAN to the physical interface 


[Back to Index](../index.md)
