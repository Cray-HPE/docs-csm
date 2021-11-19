# Domain name system (DNS) client 

The Domain Name System (DNS) translates domain and host names to and from IP addresses. A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address. 

Relevant Configuration 

Configure the switch to resolve queries via a DNS server 

```
switch(config)# ip name-server <IPv4/IPv6 address>
```

Configure a domain name 

```
switch(config)# ip domain-list mydomain2.com
```

Show Commands to Validate Functionality 

```
switch# show hosts
```

Expected Results 

* Step 1: You can configure the DNS client 
* Step 2: The output is correct
* Step 3: You can ping the device

[Back to Index](./index.md)