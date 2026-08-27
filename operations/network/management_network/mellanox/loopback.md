# Loopback Interface

Loopbacks can be thought of as internal virtual interfaces.
Loopback interfaces are not bound to a physical port and are used for device management and routing protocols.

## Relevant configuration

(`switch (config)#`) Create a loopback interface. Run:

```console
interface loopback 2
```

(`switch (config interface loopback 2)#`) Configure an IP address on the loopback interface. Run:

```console
ip address 20.20.20.20 /32
```

## Show commands to validate functionality

```console
show interfaces loopback 2
```

## Expected results

* Administrators can create a loopback interface
* Administrators can give a loopback interface an IP address
* Administrators can validate the configuration using the show commands

[Back to Index](../README.md)
