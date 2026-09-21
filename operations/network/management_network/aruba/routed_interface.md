# Routed Interfaces

For platforms 8400 and `83xx`: By default, all interfaces are configured as routed interfaces with support for both IPv4 and IPv6.

For platforms 6400 and 6300: By default, all interfaces are configured as access ports on VLAN 1

## Configuration commands

(`switch(config-if)#`) Give an interface an IP address:

```console
<ip|ipv6> address IP-ADDR/<SUBNET|PREFIX>
```

## Show commands to validate functionality

(`switch(config-if)#`)

```console
show <ip|ipv6> interface IFACE
```

## Expected results

* Administrators are able to configure an IP address on the interface.
* Administrators can configure an IP address on the connected network client.
* The interface is up, and the administrator can validate the IP address and subnet are correct.
* Administrators can ping from the switch to the client and from the client to the switch.

[Back to Index](../README.md)
