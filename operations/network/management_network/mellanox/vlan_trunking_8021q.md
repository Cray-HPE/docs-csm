# VLAN Trunking 802.1Q

A trunk port carries packets on one or more specified VLANs.
Packet that ingress on a trunk port are in the VLAN specified in its 802.1Q header, or native VLAN if the packet has no 802.1Q header.
A packet that egresses through a trunk port will have an 802.1Q header if it has a nonzero VLAN ID.
Any packet that ingresses on a trunk port tagged with a VLAN that the port does not trunk is dropped.

## Configuration commands

(`switch (config) #`) Create a VLAN:

```console
vlan 100
```

(`switch (config vlan 100)#`) Exit configuration mode:

```console
exit
```

(`switch (config) #`) Enter the interface configuration mode:

```console
interface ethernet 1/35
```

(`switch (config interface ethernet 1/35)#`) From within the interface context, configure the interface mode to "hybrid":

```console
switchport mode hybrid
```

(`switch (config interface ethernet 1/35)#`) From within the interface context, configure the allowed VLAN membership:

```console
switchport hybrid allowed-vlan add 100
```

## Expected results

* Administrators can create and enable multiple VLAN interfaces
* Administrators can assign the trunk VLAN interfaces

[Back to Index](../README.md)
