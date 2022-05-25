# Address resolution protocol (ARP)

ARP is commonly used for mapping IPv4 addresses to MAC addresses. Static ARP addresses only supported in management interfaces;

Relevant Configuration

Configure static ARP on an interface

```
Switch (config) #  interface mgmt0
switch(config interface mgmt0)# arp ipv4 IP-ADDR mac MAC-ADDR
```

Show Commands to Validate Functionality

```
switch# show ip arp
```

Expected Results

* Step 1: You are able to ping the connected device
* Step 2: You can view the ARP entries

[Back to Index](../index.md)

