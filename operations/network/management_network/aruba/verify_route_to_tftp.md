# Verify Route to TFTP

On **BOTH** Aruba switches, a single route to the TFTP server `10.92.100.60` is needed.
The configuration may differ on the system in use.

This is needed because there are issues with Aruba ECMP hashing and TFTP traffic.

```bash
show ip route 10.92.100.60
```

Example output:

```text
Displaying ipv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

10.92.100.60/32, vrf default, tag 0
    via  10.252.1.9,  [70/0],  bgp
```

This route can be a static route or a BGP route that is pinned to a single worker. The 1.4.2 patch introduced the BGP pinned route.

Verify that the next hop of this route can be pinged.
For example, in the example above, this would verify that `10.252.1.9` can be pinged.
If this is not reachable, this is the problem.

[Back to Index](../README.md)
