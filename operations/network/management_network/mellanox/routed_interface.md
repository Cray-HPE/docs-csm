# Routed Interfaces

By default Mellanox interfaces are set as `switchports`, which is to allow L2 communication.
To change to routed only port, L2 functionality must be disabled.

## Relevant configuration

(`switch (config) #`) Disable L2 functionality:

```console
interface ethernet 1/4
no switchport force
```

(`switch (config) #`) Give an interface an IP address:

```console
interface ethernet 1/14 ip address 192.168.75.1/31
primary
```

## Show commands to validate functionality

(`switch #`)

```console
show ethernet interface IFACE
```

## Expected results

* Administrators are able to configure an IP address on the interface
* Administrators can configure an IP address on the connected network client
* The interface is up, and administrators can validate that the IP address and subnet are correct
* Administrators can ping from the switch to the client and from the client to the switch

[Back to Index](../README.md)
