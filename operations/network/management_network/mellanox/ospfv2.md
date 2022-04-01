# Open shortest path first (OSPF) v2

"OSPF is a link-state based routing protocol. It is designed to be run internal to a single Autonomous System. Each OSPF router maintains an identical database describing the Autonomous System's topology. From this database, a routing table is calculated by constructing a shortest-path tree. OSPF recalculates routes quickly in the face of topological changes, utilizing a minimum of routing protocol traffic. OSPF provides support for equal-cost multipath. An area routing capability is provided, enabling an additional level of routing protection and a reduction in routing protocol traffic." –rfc1247

Relevant Configuration

Enable Ip routing

```
switch(config)# ip routing
```

Configure ospf protocol

```
switch(config)# protocol ospf
switch(config)#. router ospf
```

Associate area to vlan interface

```
switch(config)# interface vlan 10
switch(config interface vlan 10)# no shutdown
switch(config interface vlan 10)# ip address 10.10.10.1/24
switch(config interface vlan 10)# ip ospf area 0
```

Show Commands to Validate Functionality

```
switch# show ip ospf
```

Expected Results

* Step 1: You can enable OSPF globally on the switch
* Step 2: You can enable OSPF on the loopback, SVI or routed interfaces.
* Step 3: The output of the show commands looks correct.

[Back to Index](../index.md)

