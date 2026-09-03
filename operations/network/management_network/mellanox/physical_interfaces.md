# Physical Interfaces

Interfaces in Mellanox are enabled by default.

## Configuration commands

(`switch (config) #`) Enter interface context

```console
interface ethernet 1/1
```

## Show commands to validate functionality

(`switch#`)

```console
show interfaces ethernet 1/1
```

## Expected results

* Administrators can enter the interface context for the port.
* Administrators can establish a link with a partner.
* Administrators can pass traffic as expected.

[Back to Index](../README.md)
