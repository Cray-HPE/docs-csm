# Physical Interfaces

Configure the physical interfaces for a switch.

## Configuration commands

Enable the interface:

```text
switch(config)# interface IFACE
switch(config-if)# no shutdown
```

Show commands to validate functionality:

```text
show interface IFACE [transceiver|brief|dom|extended]
```

## Expected results

1. The switch recognizes the transceiver without errors
1. Administrators can enter the interface context for the port and enable it
1. Administrators can establish a link with a partner
1. Administrators can pass traffic as expected

[Back to Index](../README.md)
