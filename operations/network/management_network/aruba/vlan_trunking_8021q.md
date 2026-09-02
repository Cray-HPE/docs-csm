# VLAN Trunking 802.1Q

A trunk port carries packets on one or more specified VLANs.
Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header.
A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID.
Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped.

## Configuration commands

(`switch#`) Configure an interface as a trunk port:

```text
vlan trunk allowed VLANS
```

## Show commands to validate functionality

(`switch#`)

```text
show vlan [VLAN-ID]
```

Example output:

```text
vlan 10
no shutdown
exit
vlan 20
no shutdown
exit
interface 1/1/1
no shutdown
no routing
vlan trunk native 10
vlan trunk allowed 10,20
end
```

## Expected results

* Administrators can create and enable multiple VLAN interfaces
* Administrators can assign the trunk VLAN interfaces

[Back to Index](../README.md)
