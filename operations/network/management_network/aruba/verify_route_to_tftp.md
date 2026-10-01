# Verify Route to TFTP

On **both** switches, it is required to have a single route to the TFTP server (By default this is `10.92.100.60`, but individual configurations may differ).

This is needed because there are issues with Aruba ECMP hashing and TFTP traffic.

(`switch#`)

```console
show ip route 10.92.100.60
```

Example output:

```text
Displaying ipv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

10.92.100.60/32, vrf default, tag 0
    via  10.252.1.9,  [70/0],  bgp
```

* This route can be a static route or a BGP route that is pinned to a single worker.
    * CSM 1.4.2 introduced the BGP pinned route.
* Verify that the next hop of this route is pingable.
    * For the example above, verify that `10.252.1.9` is pingable.
    * If this is not reachable, then this is a problem that must be resolved.

[Back to Index](../README.md)
