
# Open Shortest Path First (OSPF) v2 

“OSPF is a link-state based routing protocol. It is designed to be run internal to a single Autonomous System. Each OSPF router maintains an identical database describing the Autonomous System’s topology. From this database, a routing table is calculated by constructing a shortest-path tree. OSPF recalculates routes quickly in the face of topological changes, utilizing a minimum of routing protocol traffic. OSPF provides support for equal-cost multipath. An area routing capability is provided, enabling an additional level of routing protection and a reduction in routing protocol traffic.” –rfc1247 

## Configuration Commands 

Enable an OSPF instance: 

```bash
switch(config)# router ospf INSTANCE [vrf NAME] switch(config-ospf)# router-id ROUTER
```

Configure an OSPF area:

```bash
switch(config-ospf)# area AREA [stub|nssa|default-metric COST] Configure external 
```

Route redistribution and control: 

```bash
switch(config-ospf)# redistribute <bgp|connected|static> 
switch(config-ospf)# default-metric VALUE switch(config-ospf)# maximum-paths VALUE
```

Influence route choice by changing the administrative distance: 

```bash
switch(config-ospf)# distance VALUE 
```

Enable OSPF on an interface: 

```bash
switch(config-if)# ip ospf PROCESS-ID area AREA
```

Configure optional OSPF interface settings: 

```bash
switch(config-if)# ip ospf cost COST
switch(config-if)# ip ospf hello-interval SECONDS
switch(config-if)# ip ospf dead-interval SECONDS
switch(config-if)# ip ospf retransmit-interval SECONDS
switch(config-if)# ip ospf transit-delay SECONDS
switch(config-if)# ip ospf network <broadcast|point-to-point> 
switch(config-if)# ip ospf priority VALUE
switch(config-if)# ip ospf <active|passive>
switch(config-if)# ip ospf bfd
```

Configure OSPF interface authentication:

```bash
switch(config-if)# ip ospf authentication <message-digest|simple-text|null> switch(config-if)# ip ospf authentication-key PSWD
switch(config-if)# ip ospf message-digest-key md5 <cipher|plain>text KEY 
```

Show commands to validate functionality:  

```bash
switch# show ip ospf [interface|neighbors]
switch# show ip route ospf
```

## Expected Results 

1. You can enable OSPF globally on the switch
2. You can enable OSPF on the loopback, SVI or routed interfaces
3. The output of the `show` commands looks correct


[Back to Index](../index.md)


