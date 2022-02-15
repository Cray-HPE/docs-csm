# Virtual local access networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.


Relevant Configuration

Create VLAN


```
switch(config)# interface vlan <VLAN>
```

Show Commands to Validate Functionality

```
switch# show vlan [VLAN]
```


Expected Results

* Step 1: You can create a VLAN
* Step 2: You can assign a VLAN to the physical interface


[Back to Index](index.md)
