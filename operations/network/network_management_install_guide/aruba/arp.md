# Address resolution protocol (ARP) 

ARP is commonly used for mapping IPv4 addresses to MAC addresses. 

Relevant Configuration 

Configure static ARP on an interface 

```
switch(config-if)# arp ipv4 IP-ADDR mac MAC-ADDR
```

Show Commands to Validate Functionality 

```
switch# show arp
```

Expected Results 

* Step 1: You are able to ping the connected device 
* Step 2: You can view the ARP entries 

[Back to Index](./index.md)