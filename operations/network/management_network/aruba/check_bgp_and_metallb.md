# Check BGP and MetalLB

Use the following procedure to verify if the spine switches are available and that MetalLB peering to the spine switches via Border Gateway Protocol (BGP) is established.

## Prerequisites

Access to the spine switches is required.

## Procedure

1. Log in to the spine switches.

1. Check that MetalLB is peering to the spines via BGP.

    Check both spines if they are available (powered up):

    ```console
    `sw-spine# show ip bgp summary
    ```

    All the neighbors should be in the `Established` state.

    Example working state:

    ```text
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

1. If the `State/PfxRcd` is `IDLE`, then restart the BGP process.

    ```console
    sw-spine# clear ip bgp all
    ```

[Back to index](index.md).
