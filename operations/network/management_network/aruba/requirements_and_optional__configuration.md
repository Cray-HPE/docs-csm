
# Connect the Management Network to a Campus Network

There are several ways to connect an HPE Cray EX system directly to a campus network. In this guide, the two most typical ways of accomplishing this will be covered. The [Scenario A](scenario-a.md) and [Scenario B](scenario-b.md) examples will cover adding connections through the management network or high-speed network.

Requirements and optional configuration:

* System needs to be completely installed and running
* The edge router  should be cabled either to the management network or Highspeed network switch
* An IP range on the management or high-speed network switch that is routable to the campus network
* Other configuration items that may be required to facilitate remote connectivity:
	* Configuration may require a new LAG
	* Configuration may require a new VLAN
	* Configuration may require a new router OSPF context
	* Other things to consider
		* ACL
		* Stubby OSPF area
		* Route restrictions i.e. only provide default route

> **IMPORTANT:** As there are multiple ways of achieving the connectivity these are just simple examples of how remote access could be achieved. And more complex configurations such as security etc. are up to the site network administrators.  

[Back to Index](../index.md)