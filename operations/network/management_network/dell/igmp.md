# IGMP

The Internet Group Multicast Protocol (IGMP) is a communications protocol used by hosts and adjacent routers on IP networks to establish multicast group memberships. The host joins a multicast-group by sending a join request message towards the network router, and responds to queries sent from the network router by dispatching a join report.


Relevant Configuration

```
switch(config)# ip igmp snooping enable
```

Expected Results.
* Step 1: show ip igmp-snooping vlan 1 should show IGMP enabled on the VLAN, but no IGMP Querier set.

[Back to Index](../index.md)
