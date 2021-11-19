# MLAG (Multi-Chassis LAG)

Is a type of Link Aggregation Group where ports from single device such as server terminate on two separate switches providing switch-level redundancy.


What are the benefits of MLAG


* Increased bandwidth achieved by dual connection to node.
    
* High availability (HA) for servers while allowing full use of the bandwidth of both links

* To achieve HA on a switch level without the using of STP


Key limitations of MLAG in mellanox: 

* Only one MLAG domain supported per device

* Maximum number of devices in MLAG domain is two switches.

* At least one port per switch (in MLAG domain) MUST be reserved for inter-switch link.

More details, requirements and limitations on Mellanox devices can be found from: 

[https://docs.mellanox.com/display/ONYXv381174/MLAG]()

[Back to Index](./index.md)
