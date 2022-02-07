# Domain name system (DNS) client 

The Domain Name System (DNS) translates domain and host names to and from IP addresses. A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address. 

Relevant Configuration 

Configure the switch to resolve queries via a DNS server 

```
switch(config)# ip dns server-address IP-ADDR [vrf VRF]
```

Configure a domain name 

```
switch(config)# ip dns domain-name NAME
```

Show Commands to Validate Functionality 

```
switch# show ip dns 
```

Expected Results 

* Step 1: You can configure the DNS client 
* Step 2: The output is correct
* Step 3: You can ping the device

[Back to Index](./index.md)