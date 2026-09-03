# Internet Group Multicast Protocol (IGMP)

The Internet Group Multicast Protocol (IGMP) is a communications protocol used by hosts and adjacent
routers on IP networks. It is used to establish multicast group memberships. The host joins a multicast group
by sending a join request message towards the network router, and responds to queries sent from the network
router by dispatching a join report.

General notes:

* In ArubaOS-CX IGMP snooping is disabled by default
* IGMP v3 is used by default; supported configuration allows v2 and v3

## Configuration commands

(`switch(config)#`)

```console
interface vlan 1
igmp
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show ip igmp-snooping vlan 1
```

## Expected results

The `show` command should show IGMP enabled on the VLAN, but no IGMP querier set.

[Back to Index](../README.md)
