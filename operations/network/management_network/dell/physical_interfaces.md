# Physical Interfaces

Ethernet port interfaces are enabled by default.

## Configuration commands

(`switch#`) Enable the interface:

```text
interface ethernet 1/1/1
no shutdown
```

(`switch#`) Disable the interface:

```text
interface ethernet 1/1/1
shutdown
```

## Show commands to validate functionality

(`switch#`)

```text
show configuration
```

## Expected results

* The switch recognizes the transceiver without errors.
* Administrators can enter the interface context for the port and enable it.
* Administrators can establish a link with a partner.
* Administrators can pass traffic as expected.

[Back to Index](../README.md)
