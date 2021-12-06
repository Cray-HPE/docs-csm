# Verify route to TFTP

On BOTH Aruba switches we need a single route to the TFTP server 10.92.100.60 (your configuration may differ).  

This is needed because there are issues with Aruba ECMP hashing and TFTP traffic.

```
sw-spine-002# show ip route 10.92.100.60
 
Displaying ipv4 routes selected for forwarding
 
'[x/y]' denotes [distance/metric]
 
10.92.100.60/32, vrf default, tag 0
    via  10.252.1.9,  [70/0],  bgp
```

* This route can be a static route or a BGP route that's pinned to a single worker. (1.4.2 patch introduces the BGP pinned route)
* Verify that you can ping the next hop of this route.
* For example above we would ping 10.252.1.9.  If this is not reachable this is your problem.


[Back to Index](./index.md)