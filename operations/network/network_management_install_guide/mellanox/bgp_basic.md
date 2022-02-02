# BGP basics 

"The primary function of a Border Gateway Protocol (BGP) speaking system is to exchange network reachability information with other BGP systems. This network reachability information includes information on the list of Autonomous Systems (ASes) that reachability information traverses. This information is sufficient for constructing a graph of AS connectivity for this reachability, from which routing loops may be pruned and, at the AS level, some policy decisions may be enforced." –rfc4271A 
You can configure BGP to run in either internal (iBGP) or external (eBGP) mode. 

Relevant Configuration 

Enable BGP

```
switch(config)# protocol bgp
```

Configure a BGP Instance 

```
switch(config)# router bgp 100
```

Apply IP address to the VLAN interface on Router 1. Run:

```
switch (config interface vlan 10)# ip address 10.10.10.1 /24
```

Apply IP address to the VLAN interface on Router 2. Run:

```
switch (config interface vlan 10)# ip address 10.10.10.2 /24
```

On BGP router 1

```
switch(config router bgp 100)# neighbor 10.10.10.2 remote-as 100
```

On BGP router 2

```
switch(config router bgp 100)# neighbor 10.10.10.1 remote-as 100
```

Show Commands to Validate Functionality 

```
switch# show ip bgp summary
```

Expected Results 

* Step 1: You can configure BGP on the switch
* Step 2: You can create the network statements and the routes are in the routing table
* Step 3: You can configure a BGP neighbor that uses an MD5 encrypted password
* Step 4: You can validate the BGP relationship is established and that the network statement is advertised to the peer □ Step 5: Soft reconfiguration is enabled
Use the space below for notes as needed. 

[Back to Index](./index.md)
