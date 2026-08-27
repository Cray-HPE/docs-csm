# Configure Address Resolution Protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses.

## Configuration commands

Configure static ARP on an interface:

```text
ip arp ipv4 IP-ADDR mac MAC-ADDR
```

Show commands to validate functionality:

```text
show ip arp
```

## Expected results

1. Administrators are able to ping the connected device
1. Administrators can view the ARP entries

[Back to Index](../README.md)
