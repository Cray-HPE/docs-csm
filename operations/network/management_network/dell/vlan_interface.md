# Configure VLAN Interface

The switch also supports classic L3 VLAN interfaces.

## Configuration commands

Configure the VLAN:

```text
vlan VLAN
```

The default mode of any VLAN is L2 only. To enable L3 functionality, run `no shutdown` on the VLAN:

```text
interface vlan 2
no shutdown
```

Show commands to validate functionality:

```text
show interface vlan
```

## Expected results

1. Administrators can configure the VLAN
1. Administrators can enable the interface and associate it with the VLAN
1. Administrators can create an IP-enabled VLAN interface, and it is up
1. Administrators validate the configuration is correct
1. Administrators can ping from the switch to the client and from the client to the switch

[Back to Index](../README.md)
