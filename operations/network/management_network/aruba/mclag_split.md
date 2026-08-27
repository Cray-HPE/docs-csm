# VSX: Split

This document showcases a complete inter-switch-link (ISL) link failure scenario where both of the ISL links between spine switches goes down.

The following is a visualization of a disconnected ISL link and how the traffic pattern would look:

![Disconnected ISL link](../../../../img/network/management_network/vsx_split.png "Disconnected ISL link")

The following is expected in this scenario:

* After disconnecting both ISL links and `keepalive` is up and properly configured, the VSX secondary switch should put all its MCLAGs into `lacp-blocked` state and traffic should only flow through VSX primary.
* VSX primary switch should continue to operate without any problems.
* If traffic was originally flowing through secondary VSX member, a small percentage of packets may be dropped when disconnecting the ISL. A sub second value is expected during this event.
* When connecting back ISL link, the hashing needs to be recalculated and some packets may be dropped during this event as well. A sub second value is expected during this event.

[Back to Index](../README.md)
