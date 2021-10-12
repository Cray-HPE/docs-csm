# VLAN interface

The switch also supports classic L3 VLAN interfaces.

Relevant Configuration

Configure the VLAN

```
switch(config)# vlan VLAN
```

The default mode of any vlan is L2 only. To enable L3 functionality, you must do 'no shutdown' on the VLAN. 

```
switch(config)# interface vlan 2
switch(conf-if-vl-2)# no shutdown
```

Show Commands to Validate Functionality

```
switch# show interface vlan 
```

Expected Results

* Step 1: You can configure the VLAN
* Step 2: You can enable the interface and associate it with the VLAN
* Step 3: You can create an IP enabled VLAN interface, and it is up
* Step 4: You validate the configuration is correct
* Step 5: You can ping from the switch to the client and from the client to the switch

[Back to Index](./index.md)

