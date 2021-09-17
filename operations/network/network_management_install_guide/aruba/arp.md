# Address Resolution Protocol (ARP) 

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

Example Output 

```
switch# show arp
IPv4 Address     MAC                Port         Physical Port    State
---------------------------------------------------------------------------
10.10.31.2       ec:eb:b8:7a:e0:40  1/1/31       1/1/31           reachable
10.10.32.2       ec:eb:b8:7a:a0:00  1/1/32       1/1/32           reachable
Total Number Of ARP Entries Listed- 2.
```

Expected Results 

* Step 1: You are able to ping the connected device 
* Step 2: You can view the ARP entries 
