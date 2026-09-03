# Open Shortest Path First (OSPF) v2

"OSPF is a link-state based routing protocol. It is designed to be run internal to a
single Autonomous System. Each OSPF router maintains an identical database describing
the Autonomous System's topology. From this database, a routing table is calculated by
constructing a shortest-path tree. OSPF recalculates routes quickly in the face of
topological changes, utilizing a minimum of routing protocol traffic. OSPF provides
support for equal-cost multipath. An area routing capability is provided, enabling an
additional level of routing protection and a reduction in routing protocol traffic." – RFC 1247

## Configuration commands

(`switch(config)#`) Enable IP routing:

```console
ip routing
```

(`switch(config)#`) Configure OSPF protocol:

```console
protocol ospf
router ospf
```

(`switch(config)#`) Associate area to VLAN interface:

```console
interface vlan 10
no shutdown
ip address 10.10.10.1/24
ip ospf area 0
```

## Show commands to validate functionality

(`switch#`)

```console
show ip ospf
```

## Expected results

* Administrators can enable OSPF globally on the switch.
* Administrators can enable OSPF on the loopback, SVI, or routed interfaces.
* The output of the show commands looks correct.

[Back to Index](../README.md)
