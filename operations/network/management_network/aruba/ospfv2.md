# Open Shortest Path First (OSPF) v2

"OSPF is a link-state based routing protocol. It is designed to be run internal to a
single Autonomous System. Each OSPF router maintains an identical database describing
the Autonomous System's topology. From this database, a routing table is calculated by
constructing a shortest-path tree. OSPF recalculates routes quickly in the face of
topological changes, utilizing a minimum of routing protocol traffic. OSPF provides
support for equal-cost multipath. An area routing capability is provided, enabling an
additional level of routing protection and a reduction in routing protocol traffic." – RFC 1247

## Configuration commands

(`switch(config)#`) Enable an OSPF instance:

```text
router ospf INSTANCE [vrf NAME] switch(config-ospf)# router-id ROUTER
```

(`switch(config-ospf)#`) Configure an OSPF area:

```text
area AREA [stub|nssa|default-metric COST] Configure external
```

(`switch(config-ospf)#`) Route redistribution and control:

```text
redistribute <bgp|connected|static>
default-metric VALUE switch(config-ospf)# maximum-paths VALUE
```

(`switch(config-ospf)#`) Influence route choice by changing the administrative distance:

```text
distance VALUE
```

(`switch(config-if)#`) Enable OSPF on an interface:

```text
ip ospf PROCESS-ID area AREA
```

(`switch(config-if)#`) Configure optional OSPF interface settings:

```text
ip ospf cost COST
ip ospf hello-interval SECONDS
ip ospf dead-interval SECONDS
ip ospf retransmit-interval SECONDS
ip ospf transit-delay SECONDS
ip ospf network <broadcast|point-to-point>
ip ospf priority VALUE
ip ospf <active|passive>
ip ospf bfd
```

(`switch(config-if)#`) Configure OSPF interface authentication:

```text
ip ospf authentication <message-digest|simple-text|null> switch(config-if)# ip ospf authentication-key PSWD
ip ospf message-digest-key md5 <cipher|plain>text KEY
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show ip ospf [interface|neighbors]
show ip route ospf
```

## Expected results

* Administrators can enable OSPF globally on the switch.
* Administrators can enable OSPF on the loopback, SVI or routed interfaces.
* The output of the `show` commands looks correct.

[Back to Index](../README.md)
