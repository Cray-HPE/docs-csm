# IGMP

The Internet Group Multicast Protocol (IGMP) is a communications protocol used by hosts and adjacent routers on IP networks to establish multicast group memberships. The host joins a multicast-group by sending a join request message towards the network router, and responds to queries sent from the network router by dispatching a join report.

Relevant Configuration 

Enable IGMP snooping globally. Run: 

```
switch (config) # ip igmp snooping
```

Enable IGMP snooping on a VLAN. Run: 

```
switch (config) # vlan 2
switch (config vlan 2) # ip igmp snooping
```

(Optional) Verify the IGMP snooping querier configuration. Run:

```
switch (config vlan 10)# show ip igmp snooping querier
```

[Back to Index](./index.md)
