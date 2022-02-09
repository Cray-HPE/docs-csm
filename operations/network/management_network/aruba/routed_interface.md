# Routed interfaces

For platforms: 8400 and 83xx by default all interfaces are configured as routed interfaces with support for both IPv4 and IPv6. 

For platforms: 6400 and 6300 by default all interfaces are configured as access ports on VLAN 1

Relevant Configuration 

Give an interface an IP address 

```
switch(config-if)# <ip|ipv6> address IP-ADDR/<SUBNET|PREFIX>
```

Show Commands to Validate Functionality 

```
switch# show <ip|ipv6> interface IFACE
```

Expected Results 

* Step 1: You are able to configure an IP address on the interface
* Step 2: You can configure an IP address on the connected network client
* Step 3: The interface is up, and you can validate the IP address and subnet are correct 
* Step 4: You can ping from the switch to the client and from the client to the switch 


[Back to Index](../index.md)

