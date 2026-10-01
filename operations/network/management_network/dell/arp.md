# Address Resolution Protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses.

## Configuration commands

(`switch#`) Configure static ARP on an interface:

```text
ip arp ipv4 IP-ADDR mac MAC-ADDR
```

## Show commands to validate functionality

(`switch#`)

```text
show ip arp
```

## Expected results

* Administrators are able to ping the connected device.
* Administrators can view the ARP entries.

[Back to Index](../README.md)
