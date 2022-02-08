# Border Gateway Protocol (BGP) Basics

“The primary function of a Border Gateway Protocol (BGP) speaking system is to exchange network reachability information with other BGP systems. This network reachability information includes information on the list of Autonomous Systems (ASes) that reachability information traverses. This information is sufficient for constructing a graph of AS connectivity for this reachability, from which routing loops may be pruned and, at the AS level, some policy decisions may be enforced.” –rfc4271A 

BGP is configurable to run in either internal (iBGP) or external (eBGP) mode. 

## Configuration Commands

Create a static route towards a blackhole interface: 

```
switch(config)# ip route IP-ADDR/SUBNET blackhole
```

Configure a BGP instance: 

```
switch(config)# router bgp AS-NUM [vrf VRF]
```

Create network statements for each subnet to advertise: 

```
switch(config-router)# network IP-ADDR/SUBNET
```

Configure a neighbor relationship with another BGP speaker: 

```
switch(config-router)# neighbor IP-ADDR remote-as AS-NUM
```

Configure an MD5 encrypted password to secure the neighbor relationship: 

```
switch(config-router)# neighbor IP-ADDR password <cipher|plain>text PSWD
```

Configure soft reconfiguration: 

```
switch(config-router)# neighbor IP-ADDR soft-reconfiguration inbound
```

Show commands to validate functionality: : 

```
switch# show bgp all [summary|neighbors]
```

## Expected Results
 
1. You can configure BGP on the switch
2. You can create the network statements and the routes are in the routing table
3. You can configure a BGP neighbor that uses an MD5 encrypted password
4. You can validate the BGP relationship is established and that the network statement is advertised to the peer
5. Soft reconfiguration is enabled

[Back to Index](index_aruba.md)