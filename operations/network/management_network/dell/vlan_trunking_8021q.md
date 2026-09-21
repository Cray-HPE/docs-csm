# VLAN Trunking 802.1Q

A trunk port carries packets on one or more specified VLANs.
Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header.
A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID.
Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped.

## Configuration commands

(`switch(config-if)#`) Configure an interface as a trunk port:

```text
switchport mode trunk
```

(`switch(config-if)#`) Add the allowed VLANs:

```text
switchport trunk allowed vlan add 1,50,100
```

(`switch(config-if)#`) Assign a native VLAN:

```text
switchport trunk native vlan-id 1
```

## Show commands to validate functionality

(`switch#`)

```text
show interfaces switchport
```

## Expected results

* Administrators can create and enable multiple VLAN interfaces
* Administrators can assign the trunk VLAN interfaces

[Back to Index](../README.md)
