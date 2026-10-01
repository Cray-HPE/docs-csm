# Border Gateway Protocol (BGP) Basics

"The primary function of a Border Gateway Protocol (BGP) speaking system is to exchange
network reachability information with other BGP systems. This network reachability
information includes information on the list of Autonomous Systems (ASes) that reachability
information traverses. This information is sufficient for constructing a graph of AS
connectivity for this reachability, from which routing loops may be pruned and, at the AS
level, some policy decisions may be enforced." – RFC `4271A`

BGP is configurable to run in either internal (iBGP) or external (eBGP) mode.

## Configuration commands

(`switch(config)#`) Create a static route towards a blackhole interface:

```console
ip route IP-ADDR/SUBNET blackhole
```

(`switch(config)#`) Configure a BGP instance:

```console
router bgp AS-NUM [vrf VRF]
```

(`switch(config-router)#`) Create network statements for each subnet to advertise:

```console
network IP-ADDR/SUBNET
```

(`switch(config-router)#`) Configure a neighbor relationship with another BGP speaker:

```console
neighbor IP-ADDR remote-as AS-NUM
```

(`switch(config-router)#`) Configure an MD5 encrypted password to secure the neighbor relationship:

```console
neighbor IP-ADDR password <cipher|plain>text PSWD
```

(`switch(config-router)#`) Configure soft reconfiguration:

```console
neighbor IP-ADDR soft-reconfiguration inbound
```

(`switch#`) Show commands to validate functionality:

```console
show bgp all [summary|neighbors]
```

## Expected results

* Administrators can configure BGP on the switch.
* Administrators can create the network statements and the routes are in the routing table.
* Administrators can configure a BGP neighbor that uses an MD5 encrypted password.
* Administrators can validate the BGP relationship is established and that the network statement is advertised to the peer.
* Soft reconfiguration is enabled.

[Back to Index](README.md)
