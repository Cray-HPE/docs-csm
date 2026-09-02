# Virtual Local Access Networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.

## Configuration commands

(`switch(config)#`) Create VLAN:

```console
vlan <VLAN>
```

(`switch(config)#`) Configure an interface to associate it with a VLAN:

```console
interface ethernet 1/22
```

(`switch(config interface ethernet 1/22)#`) From within the interface context, configure the interface mode to "access":

```console
switchport mode access
```

(`switch(config interface ethernet 1/22)#`) From within the interface context, configure the access VLAN membership:

```console
switchport access vlan 6
```

(`switch(config)#`) Configure an interface as a trunk port:

```console
interface ethernet 1/35
```

(`switch(config interface ethernet 1/35)#`) From within the interface context, configure the interface mode to "trunk".

```console
switchport mode trunk
```

## Show commands to validate functionality

(`switch#`)

```console
show vlan [VLAN]
```

## Expected results

* Administrators can create a VLAN.
* Administrators can assign a VLAN to the physical interface.

[Back to Index](../README.md)
