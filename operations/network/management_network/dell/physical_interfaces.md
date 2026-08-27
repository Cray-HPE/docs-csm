# Configure Physical Interfaces

Ethernet port interfaces are enabled by default.

## Configuration commands

Enable the interface:

```text
interface ethernet 1/1/1
no shutdown
```

Disable the interface:

```text
interface ethernet 1/1/1
shutdown
```

Show commands to validate functionality:

```text
show configuration
```

## Expected results

1. The switch recognizes the transceiver without errors
1. Administrators can enter the interface context for the port and enable it
1. Administrators can establish a link with a partner
1. Administrators can pass traffic as expected

[Back to Index](../README.md)
