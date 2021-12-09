
# VSX: ISL HA

The intent here is to showcase an inter-switch-link (ISL) link failover scenario where one of the two links between spine switches goes down, but ISL is still connected with single link.

The following image is a visualization of disconnected ISL link:

![](../img/vsx_isl_ha.png)
 
The following things are expected to be seen in this scenario:

* After disconnecting one ISL, the VSX functionality should not be affected
* A small percentage of packets will be dropped when disconnecting the cable where traffic is flowing; A sub second value is expected during this event
* When connecting back the cable, the hashing needs to be recalculated and some packets may be dropped during this event as well; A sub second value is expected during this event

[Back to Index](../index.md)