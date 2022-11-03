# Troubleshoot BGP not Accepting Routes from MetalLB

Check the number of routes that the Border Gateway Protocol \(BGP\) Router is accepting in the peering session. This procedure is useful if Kubernetes LoadBalancer services in the NMN, HMN, or CAN address pools are not accessible from outside the cluster.

Regain access to Kubernetes LoadBalancer services from outside the cluster.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Log into the spine or aggregate switch.

    In this example, the Aruba or Mellanox spine or aggregate switch is accessed from `ncn-m001`. In this case, sw-spine-001.mtl is being accessed:

    ```bash
    ncn-m001# ssh admin@sw-spine-001.mtl
    ```

2.  Check the number of routes that the BGP Router is accepting in the peering session.

    -   **Mellanox:**

        Look at the number under the State/Pfx column in the output. There should be a number that matches the number of unique LoadBalancer IP addresses configured in the cluster.

        ```bash
        sw-spine-001# show ip bgp summary
        VRF name                  : vrf-default
        BGP router identifier     : 10.252.0.1
        local AS number           : 65533
        BGP table version         : 45
        Main routing table version: 45
        IPV4 Prefixes             : 51
        IPV6 Prefixes             : 0
        L2VPN EVPN Prefixes       : 0

        ------------------------------------------------------------------------------------------------------------------
        Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
        ------------------------------------------------------------------------------------------------------------------
        10.252.0.4        4    65533        2687      3072      45        0      0      0:22:14:03    ESTABLISHED/17
        10.252.0.5        4    65533        2687      3070      45        0      0      0:22:14:03    ESTABLISHED/17
        10.252.0.6        4    65533        2687      3067      45        0      0      0:22:14:03    ESTABLISHED/17
        ```

        If there is a number smaller than expected, check the routes that have been accepted with the following command:

        ```bash
        sw-spine-001# show ip route bgp
        Flags:

          F: Failed to install in H/W
          B: BFD protected (static route)
          i: BFD session initializing (static route)
          x: protecting BFD session failed (static route)
          c: consistent hashing
          p: partial programming in H/W

        VRF Name default:
          ------------------------------------------------------------------------------------------------------
          Destination       Mask              Flag     Gateway           Interface        Source     AD/M
          ------------------------------------------------------------------------------------------------------
          10.92.100.0       255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.1       255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.60      255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.71      255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.72      255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.75      255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.92.100.76      255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                              c        10.252.0.5        vlan2            bgp        200/0
                                              c        10.252.0.6        vlan2            bgp        200/0
          10.94.100.0       255.255.255.255   c        10.254.0.4        vlan4            bgp        200/0
                                              c        10.254.0.5        vlan4            bgp        200/0
                                              c        10.254.0.6        vlan4            bgp        200/0
          10.94.100.1       255.255.255.255   c        10.254.0.4        vlan4            bgp        200/0
                                              c        10.254.0.5        vlan4            bgp        200/0
                                              c        10.254.0.6        vlan4            bgp        200/0
          10.94.100.2       255.255.255.255   c        10.254.0.4        vlan4            bgp        200/0
                                              c        10.254.0.5        vlan4            bgp        200/0
                                              c        10.254.0.6        vlan4            bgp        200/0
          10.94.100.3       255.255.255.255   c        10.254.0.4        vlan4            bgp        200/0
                                              c        10.254.0.5        vlan4            bgp        200/0
                                              c        10.254.0.6        vlan4            bgp        200/0
          10.102.3.112      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
          10.102.3.113      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
          10.102.3.128      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
          10.102.3.129      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
          10.102.3.130      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
          10.102.3.131      255.255.255.255   c        10.102.3.4        vlan7            bgp        200/0
                                              c        10.102.3.5        vlan7            bgp        200/0
                                              c        10.102.3.6        vlan7            bgp        200/0
        ```

        If the expected routes are not present, check the route-map or prefix-list configuration on the spine switch.

    -   **Aruba:**

        To check the status for Aruba:

        ```bash
        sw-spine-001# show bgp ipv4 unicast summary
        VRF : default
        BGP Summary
        -----------
         Local AS               : 65533        BGP Router Identifier  : 10.252.0.2
         Peers                  : 4            Log Neighbor Changes   : No
         Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
         Confederation Id       : 0

         Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
         10.252.0.3      65533       1041    1037    15h:00m:52s  Established   Up
         10.252.1.7      65533       1752    2003    14h:29m:26s  Established   Up
         10.252.1.8      65533       1752    2002    14h:29m:21s  Established   Up
         10.252.1.9      65533       1751    2005    14h:28m:43s  Established   Up
        ```

        To check the routes for Aruba:

        ```bash
        sw-spine-001# show ip route bgp
        10.92.100.71/32, vrf default
        	via  10.252.1.7,  [200/0],  bgp
        	via  10.252.1.8,  [200/0],  bgp
        	via  10.252.1.9,  [200/0],  bgp
        10.92.100.81/32, vrf default
        	via  10.252.1.7,  [200/0],  bgp
        	via  10.252.1.8,  [200/0],  bgp
        	via  10.252.1.9,  [200/0],  bgp
        10.92.100.222/32, vrf default
        	via  10.252.1.7,  [200/0],  bgp
        	via  10.252.1.8,  [200/0],  bgp
        	via  10.252.1.9,  [200/0],  bgp
        10.92.100.225/32, vrf default
        	via  10.252.1.7,  [200/0],  bgp
        	via  10.252.1.8,  [200/0],  bgp
        	via  10.252.1.9,  [200/0],  bgp
        10.94.100.0/32, vrf default
        	via  10.254.1.10,  [200/0],  bgp
        	via  10.254.1.12,  [200/0],  bgp
        	via  10.254.1.14,  [200/0],  bgp
        10.94.100.71/32, vrf default
        	via  10.254.1.10,  [200/0],  bgp
        	via  10.254.1.12,  [200/0],  bgp
         -- MORE --, next page: Space, next line: Enter, quit: q
        ```

        There should be a route for each unique LoadBalancer IP addresses configured in the cluster.

