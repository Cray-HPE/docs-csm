# BGP basics 

“The primary function of a Border Gateway Protocol (BGP) speaking system is to exchange network reachability information with other BGP systems. This network reachability information includes information on the list of Autonomous Systems (ASes) that reachability information traverses. This information is sufficient for constructing a graph of AS connectivity for this reachability, from which routing loops may be pruned and, at the AS level, some policy decisions may be enforced.” –rfc4271A 

You can configure BGP to run in either internal (iBGP) or external (eBGP) mode. 

Relevant Configuration 

Create a static route towards a blackhole interface 

```
switch(config)# ip route IP-ADDR/SUBNET blackhole
```

Configure a BGP Instance 

```
switch(config)# router bgp AS-NUM [vrf VRF]
```

Create network statements for each subnet you wish to advertise 

```
switch(config-router)# network IP-ADDR/SUBNET
```

Configure a neighbor relationship with another BGP speaker 

```
switch(config-router)# neighbor IP-ADDR remote-as AS-NUM
```

Configure an MD5 encrypted password to secure the neighbor relationship 

```
switch(config-router)# neighbor IP-ADDR password <cipher|plain>text PSWD
```

Configure soft reconfiguration 

```
switch(config-router)# neighbor IP-ADDR soft-reconfiguration inbound
```

Show Commands to Validate Functionality 

```
switch# show bgp all [summary|neighbors]
```

Expected Results
 
* Step 1: You can configure BGP on the switch
* Step 2: You can create the network statements and the routes are in the routing table
* Step 3: You can configure a BGP neighbor that uses an MD5 encrypted password
* Step 4: You can validate the BGP relationship is established and that the network statement is advertised to the peer □ Step 5: Soft reconfiguration is enabled

[Back to Index](../index.md)