# Virtual Local Access Networks (VLANs)

VLANs allow for the logical grouping of switch interfaces, enabling communication as if all connected devices were on the same isolated network.

## Configuration commands

(`switch#`) Create VLAN:

```text
vlan <VLAN>
```

(`switch#`) Configure an interface to associate it with a VLAN:

```text
interface <IFACE>
no shutdown
no routing
```

(`switch#`) Configure an interface as an access port:

```text
vlan access VLAN
```

(`switch#`) Configure an interface as a trunk port:

```text
vlan trunk native <VLAN>
vlan trunk allowed <VLAN>
```

(`switch#`) Configure VLAN as voice:

> **NOTE** In order to give a specific VLAN a voice designation and add the proper hooks,
> it is necessary to add the `voice` command in the VLAN context.
> This configuration is the same for all CX-series switches.

```text
vlan <VLAN>
voice
```

## Show commands to validate functionality

(`switch#`)

```text
show vlan [VLAN]
```

Example output:

```text
show vlan
--------------------------------------------------------------------------------------
VLAN  Name                              Status  Reason          Type      Interfaces
--------------------------------------------------------------------------------------
1     DEFAULT_VLAN_1                    up      no_member_port  static    1/1/2
10    VLAN10                            up      ok              static    1/1/1-1/1/2
```

## Expected results

* Administrators can create a VLAN.
* Administrators can assign a VLAN to the physical interface.

[Back to Index](../README.md)
