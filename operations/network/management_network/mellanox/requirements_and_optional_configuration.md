# How To Connect Management Network to the Campus Network

This guide goes over the two most typical ways of connecting the supercomputer to the campus network.
This is further explained in [Scenario A](scenario-a.md) and [Scenario B](scenario-b.md), which cover
examples of adding connections through the management network or the highspeed network.

## Requirements and optional configuration

* System must be completely installed and running.
* The edge router should be cabled either to the management network or Highspeed network switch.
* An IP address range on the management or highspeed network switch that is routable to the campus network.
* Other configuration items that may be required to facilitate remote connectivity however not covered in this example
    * Configuration may require a new LAG
    * Configuration may require a new VLAN
    * Configuration may require a new router OSPF context
    * Other things to consider
        * ACL
        * Stubby OSPF area
        * Route restrictions i.e. only provide default route

**IMPORTANT:** Because there are multiple ways of achieving the connectivity, these are just simple
examples of how remote access could be achieved. More complex configurations (e.g. security)
are up to the site network administrators.

[Back to Index](../README.md)
