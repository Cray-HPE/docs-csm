# Check BGP and MetalLB

Log in to the spine switches if you have access and check that MetalLB is peering to the spines via BGP.

Check both spines if they are available (powered up):

```bash
show ip bgp summary
```

Example working state:

All the neighbors should be in the `Established` state.

```bash
sw-spine01 [standalone: master] # show ip bgp summary

VRF name                  : default
BGP router identifier     : 10.252.0.1
local AS number           : 65533
BGP table version         : 6
Main routing table version: 6
IPV4 Prefixes             : 84
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
------------------------------------------------------------------------------------------------------------------
10.252.0.4        4    65533        465       501       6         0      0      0:03:37:43    ESTABLISHED/28
10.252.0.5        4    65533        463       501       6         0      0      0:03:36:51    ESTABLISHED/28
10.252.0.6        4    65533        463       500       6         0      0      0:03:36:39    ESTABLISHED/28
```

If the `State`/`pfxrcd` is "IDLE" you need to restart the BGP process with the following command:

```bash
sw-spine01 [standalone: master] # clear ip bgp all
```

[Back to Index](../index.md)
