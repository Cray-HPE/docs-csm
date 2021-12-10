# Configure Internet Group Multicast Protocol (IGMP)

The Internet Group Multicast Protocol (IGMP) is a communications protocol used by hosts and adjacent routers on IP networks to establish multicast group memberships. The host joins a multicast-group by sending a join request message towards the network router, and responds to queries sent from the network router by dispatching a join report.

General notes:

* In ArubaOS-CX igmp snooping is disabled by default
* IGMP v3 is used by default, supported configuration allows v2 and v3

## Configuration Commands

```
switch(config)# interface vlan 1
switch(config-if-vlan)# igmp
```

## Expected Results

`show ip igmp-snooping vlan 1` should show IGMP enabled on the VLAN, but no IGMP Querier set.

[Back to Index](../index_aruba.md)
