# VSX: MCLAG link HA

The intent here is to show case a typical MCLAG link failover scenario where one of the links to the edge device, whether that is connected switch or server. 
 
In below a typical traffic pattern coming off from MCLAG connected device, as you can see the traffic is going north to south and ISL is not carrying any traffic. The only time ISL would carry traffic would be if one of the links to downstream devices would be down. 

![](../img/mclag_link_ha.png) 

You now have your network fully configured up, and you decide to test HA functionality by pulling MCLAG link off from Spine-02 and the bottom switch, what would you be expected to see?

* A small percentage of packets will be dropped when disconnecting the cable where traffic is flowing. A sub second value is expected during this event.
* When connecting back the cable, the hashing needs to be recalculated and some packets may be dropped during this event as well. A sub second value is expected during this event.


[Back to Index](./index.md)