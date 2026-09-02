# VLAN Interface

The switch supports classic L3 VLAN interfaces.

## Configuration commands

(`switch#`) Configure the VLAN:

```text
vlan VLAN
```

(`switch#`) The default mode of any VLAN is L2 only. To enable L3 functionality, run `no shutdown` on the VLAN:

```text
interface vlan 2
no shutdown
```

## Show commands to validate functionality

(`switch#`)

```text
show interface vlan
```

## Expected results

* Administrators can configure the VLAN.
* Administrators can enable the interface and associate it with the VLAN.
* Administrators can create an IP-enabled VLAN interface, and it is up.
* Administrators validate the configuration is correct.
* Administrators can ping from the switch to the client and from the client to the switch.

[Back to Index](../README.md)
