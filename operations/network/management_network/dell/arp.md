# Configure Address Resolution Protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses.

## Configuration Commands

Configure static ARP on an interface:

```
switch(config-if)# ip arp ipv4 IP-ADDR mac MAC-ADDR
```

Show commands to validate functionality:

```
switch# show ip arp
```

## Expected Results

1. Administrators are able to ping the connected device
2. Administrators can view the ARP entries

[Back to Index](index.md)