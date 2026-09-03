# Physical Interfaces

Configure the physical interfaces for a switch.

## Configuration commands

(`switch(config)#`) Enable the interface:

```text
interface IFACE
no shutdown
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show interface IFACE [transceiver|brief|dom|extended]
```

## Expected results

* The switch recognizes the transceiver without errors.
* Administrators can enter the interface context for the port and enable it.
* Administrators can establish a link with a partner.
* Administrators can pass traffic as expected.

[Back to Index](../README.md)
