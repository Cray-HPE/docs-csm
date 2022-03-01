# Configure Virtual Local Access Networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.

## Configuration Commands

Create VLAN:

```
switch(config)# interface vlan <VLAN>
```

Show commands to validate functionality:

```
switch# show vlan [VLAN]
```

## Expected Results

1. Administrators can create a VLAN
2. Administrators can assign a VLAN to the physical interface


[Back to Index](index.md)
