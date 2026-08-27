# IGMP

The Internet Group Multicast Protocol (IGMP) is a communications protocol used by hosts and adjacent
routers on IP networks. It is used to establish multicast group memberships. The host joins a multicast group
by sending a join request message towards the network router, and responds to queries sent from the network
router by dispatching a join report.

## Relevant configuration

(`switch (config) #`) Enable IGMP snooping globally. Run:

```console
ip igmp snooping
```

(`switch (config) #`) Enable IGMP snooping on a VLAN. Run:

```console
vlan 2
ip igmp snooping
```

(`switch (config vlan 10)#`) (Optional) Verify the IGMP snooping querier configuration. Run:

```console
show ip igmp snooping querier
```

[Back to Index](../README.md)
