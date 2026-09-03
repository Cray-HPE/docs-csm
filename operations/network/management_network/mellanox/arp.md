# Address Resolution Protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses.

## Configuration commands

(`switch (config)#`) Configure static ARP on an interface:

> Static ARP addresses only supported in management interfaces.

```console
interface mgmt0
arp ipv4 IP-ADDR mac MAC-ADDR
```

## Show commands to validate functionality

(`switch (config)#`)

```console
show ip arp
```

## Expected results

* Administrators are able to ping the connected device.
* Administrators can view the ARP entries.

[Back to Index](../README.md)
