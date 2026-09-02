# Configure Virtual Local Access Networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.

## Configuration commands

(`switch#`) Create VLAN:

```text
interface vlan <VLAN>
```

## Show commands to validate functionality

(`switch#`)

```text
show vlan [VLAN]
```

## Expected results

* Administrators can create a VLAN.
* Administrators can assign a VLAN to the physical interface.

[Back to Index](../README.md)
