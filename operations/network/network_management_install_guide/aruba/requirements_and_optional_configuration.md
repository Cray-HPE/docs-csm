# How to connect management network to your campus network


In the event that you want to connect the Supercomputer to directly to your campus network. You have number of different possibilities to get this accomplished, in this guide we will go over the two most typical ways of accomplishing this. Further explained in Scenario A and B that will cover the examples of adding connections through management network or highspeed network.

Requirements and optional configuration

* System needs to be completely installed and running.
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

**IMPORTANT:** As there are multiple ways of achieving the connectivity these are just simple examples of how remote access could be achieved. And more complex configurations such as security etc. are up to the site network administrators.  

[Back to Index](./index.md)