# Address resolution protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses. Static ARP addresses only supported in management interfaces;

## Configure static ARP on an interface

```console
Switch (config) #  interface mgmt0
switch(config interface mgmt0)# arp ipv4 IP-ADDR mac MAC-ADDR
```

## Show commands to validate functionality

```console
show ip arp
```

## Expected results

* Administrators are able to ping the connected device
* Administrators can view the ARP entries

[Back to Index](../README.md)
