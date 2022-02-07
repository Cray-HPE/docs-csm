## Troubleshoot BGP not Accepting Routes from MetalLB

Check the number of routes that the Border Gateway Protocol \(BGP\) Router is accepting in the peering session. This procedure is useful if Kubernetes LoadBalancer services in the NMN, HMN, or CAN address pools are not accessible from outside the cluster.

Regain access to Kubernetes LoadBalancer services from outside the cluster.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Log into the spine or aggregate switch.

    In this example, the Aruba or Mellanox spine or aggregate switch is accessed from `ncn-m001`. In this case, sw-spine-001.hmn is being accessed:
    You should check BOTH spine switches during this process.

    ```bash
    ncn-m001# ssh admin@sw-spine-001.hmn
    ```

2.  Check the number of routes that the BGP Router is accepting in the peering session.

    -   **Mellanox:**

        Look at the number under the State/Pfx column in the output. There should be a number that matches the number of unique LoadBalancer IP addresses configured in the cluster.

        ```bash
        sw-spine-001 [standalone: master] # show ip bgp vrf all summary
        ```

        Example output:

        ```
        VRF name                  : CAN
        BGP router identifier     : 10.101.8.2
        local AS number           : 65533
        BGP table version         : 1634
        Main routing table version: 1634
        IPV4 Prefixes             : 46
        IPV6 Prefixes             : 0
        L2VPN EVPN Prefixes       : 0

        ------------------------------------------------------------------------------------------------------------------
        Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
        ------------------------------------------------------------------------------------------------------------------
        10.101.8.8        4    65536        1267504   1278132   1634      0      0      13:20:11:58   ESTABLISHED/14
        10.101.8.9        4    65536        1267296   1278315   1634      0      0      13:20:12:03   ESTABLISHED/18
        10.101.8.10       4    65536        1267478   1278327   1634      0      0      13:20:12:15   ESTABLISHED/14

        VRF name                  : default
        BGP router identifier     : 10.252.0.2
        local AS number           : 65533
        BGP table version         : 40
        Main routing table version: 40
        IPV4 Prefixes             : 40
        IPV6 Prefixes             : 0
        L2VPN EVPN Prefixes       : 0

        ------------------------------------------------------------------------------------------------------------------
        Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
        ------------------------------------------------------------------------------------------------------------------
        10.252.1.7        4    65533        1195933   1195910   40        0      0      13:20:11:51   ESTABLISHED/12
        10.252.1.8        4    65533        1195946   1195921   40        0      0      13:20:12:02   ESTABLISHED/16
        10.252.1.9        4    65533        1195961   1195934   40        0      0      13:20:12:15   ESTABLISHED/12
        ```

        If there is a number smaller than expected, check the routes that have been accepted with the following command:

        ```bash
        sw-spine-001 [standalone: master] # show ip route vrf all bgp
        ```

        Example output:

        ```
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
          10.92.100.60      255.255.255.255   c        10.252.1.7        vlan2            bgp        200/0
                                              c        10.252.1.8        vlan2            bgp        200/0
                                              c        10.252.1.9        vlan2            bgp        200/0
          10.92.100.71      255.255.255.255   c        10.252.1.7        vlan2            bgp        200/0
                                              c        10.252.1.8        vlan2            bgp        200/0
                                              c        10.252.1.9        vlan2            bgp        200/0
          10.92.100.81      255.255.255.255   c        10.252.1.8        vlan2            bgp        200/0
          10.92.100.82      255.255.255.255   c        10.252.1.8        vlan2            bgp        200/0
          10.92.100.85      255.255.255.255   c        10.252.1.7        vlan2            bgp        200/0
                                              c        10.252.1.8        vlan2            bgp        200/0
                                              c        10.252.1.9        vlan2            bgp        200/0
          10.92.100.222     255.255.255.255   c        10.252.1.8        vlan2            bgp        200/0
          10.92.100.225     255.255.255.255   c        10.252.1.7        vlan2            bgp        200/0
                                              c        10.252.1.8        vlan2            bgp        200/0
                                              c        10.252.1.9        vlan2            bgp        200/0
          10.94.100.60      255.255.255.255   c        10.254.1.10       vlan4            bgp        200/0
                                              c        10.254.1.12       vlan4            bgp        200/0
                                              c        10.254.1.14       vlan4            bgp        200/0
          10.94.100.71      255.255.255.255   c        10.254.1.10       vlan4            bgp        200/0
                                              c        10.254.1.12       vlan4            bgp        200/0
                                              c        10.254.1.14       vlan4            bgp        200/0
          10.94.100.85      255.255.255.255   c        10.254.1.10       vlan4            bgp        200/0
                                              c        10.254.1.12       vlan4            bgp        200/0
                                              c        10.254.1.14       vlan4            bgp        200/0
          10.94.100.222     255.255.255.255   c        10.254.1.12       vlan4            bgp        200/0
          10.94.100.225     255.255.255.255   c        10.254.1.10       vlan4            bgp        200/0
                                              c        10.254.1.12       vlan4            bgp        200/0
                                              c        10.254.1.14       vlan4            bgp        200/0

        VRF Name CAN:
          ------------------------------------------------------------------------------------------------------
          Destination       Mask              Flag     Gateway           Interface        Source     AD/M
          ------------------------------------------------------------------------------------------------------
          10.92.100.60      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.92.100.71      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.92.100.81      255.255.255.255   c        10.101.8.9        vlan7            bgp        20/0
          10.92.100.82      255.255.255.255   c        10.101.8.9        vlan7            bgp        20/0
          10.92.100.85      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.92.100.222     255.255.255.255   c        10.101.8.9        vlan7            bgp        20/0
          10.92.100.225     255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.94.100.60      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.94.100.71      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.94.100.85      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.94.100.222     255.255.255.255   c        10.101.8.9        vlan7            bgp        20/0
          10.94.100.225     255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.8.113      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.8.128      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.8.129      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.8.130      255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.10.128     255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
          10.101.11.128     255.255.255.255   c        10.101.8.8        vlan7            bgp        20/0
                                              c        10.101.8.9        vlan7            bgp        20/0
                                              c        10.101.8.10       vlan7            bgp        20/0
        ```

        If the expected routes are not present, check the route-map or prefix-list configuration on the spine switch.

    -   **Aruba:**

        To check the status for Aruba:

        ```bash
        sw-spine-001# show bgp all-vrf all summary
        ```

        Example output:

        ```
        VRF : default
        BGP Summary
        -----------
        Local AS               : 65533        BGP Router Identifier  : 10.2.0.2
        Peers                  : 4            Log Neighbor Changes   : No
        Cfg. Hold Time         : 3            Cfg. Keep Alive        : 1
        Confederation Id       : 0

        Address-family : IPv4 Unicast
        -----------------------------
        Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
        10.252.0.3      65533       571006  571002  06d:14h:38m  Established   Up
        10.252.1.7      65533       451712  451502  03d:09h:34m  Established   Up
        10.252.1.8      65533       450943  450712  03d:09h:36m  Established   Up
        10.252.1.9      65533       451463  451267  03d:09h:35m  Established   Up

        Address-family : IPv6 Unicast
        -----------------------------

        Address-family : L2VPN EVPN
        -----------------------------

        VRF : Customer
        BGP Summary
        -----------
        Local AS               : 65533        BGP Router Identifier  : 10.103.15.186
        Peers                  : 4            Log Neighbor Changes   : No
        Cfg. Hold Time         : 3            Cfg. Keep Alive        : 1
        Confederation Id       : 0

        Address-family : IPv4 Unicast
        -----------------------------
        Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
        10.103.11.3     65533       500874  500891  00h:00m:11s  Established   Up
        10.103.11.8     65536       374118  374039  03d:09h:35m  Established   Up
        10.103.11.9     65536       373454  373290  03d:09h:35m  Established   Up
        10.103.11.10    65536       374169  374087  03d:09h:34m  Established   Up

        Address-family : IPv6 Unicast
        -----------------------------
        ```

        To check the routes for Aruba:

        ```bash
        sw-spine-001# show ip route bgp all-vrfs
        ```

        Example output:

        ```
        Displaying ipv4 routes selected for forwarding

        Origin Codes: C - connected, S - static, L - local
                      R - RIP, B - BGP, O - OSPF
        Type Codes:   E - External BGP, I - Internal BGP, V - VPN, EV - EVPN
                      IA - OSPF internal area, E1 - OSPF external type 1
                      E2 - OSPF external type 2

        VRF: Customer

        Prefix               Nexthop           Interface     VRF(egress)   Origin/  Distance/    Age
                                                                          Type     Metric
        ----------------------------------------------------------------------------------------------
        10.92.100.60/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03h:54m:13s
                            10.103.11.8      vlan7         -                           [20/0]       03h:54m:13s
                            10.103.11.10     vlan7         -                           [20/0]       03h:54m:13s
        10.92.100.71/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.92.100.81/32     10.103.11.8      vlan7         -                 B/E       [20/0]       03d:09h:39m
        10.92.100.85/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m
        10.92.100.225/32    10.103.11.9      vlan7         -                 B/E       [20/0]       04h:06m:56s
                            10.103.11.8      vlan7         -                           [20/0]       04h:06m:56s
                            10.103.11.10     vlan7         -                           [20/0]       04h:06m:56s
        10.94.100.60/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03h:54m:13s
                            10.103.11.8      vlan7         -                           [20/0]       03h:54m:13s
                            10.103.11.10     vlan7         -                           [20/0]       03h:54m:13s
        10.94.100.71/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.94.100.85/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m
        10.94.100.225/32    10.103.11.9      vlan7         -                 B/E       [20/0]       04h:06m:56s
                            10.103.11.8      vlan7         -                           [20/0]       04h:06m:56s
                            10.103.11.10     vlan7         -                           [20/0]       04h:06m:56s
        10.103.11.61/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m
        10.103.11.64/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.103.11.65/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.103.11.66/32     10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m
        10.103.11.160/32    10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.103.11.161/32    10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m
        10.103.11.224/32    10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:38m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:38m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:38m
        10.103.11.225/32    10.103.11.9      vlan7         -                 B/E       [20/0]       03d:09h:33m
                            10.103.11.8      vlan7         -                           [20/0]       03d:09h:33m
                            10.103.11.10     vlan7         -                           [20/0]       03d:09h:33m

        VRF: default

        Prefix               Nexthop           Interface     VRF(egress)   Origin/  Distance/    Age
                                                                          Type     Metric
        ----------------------------------------------------------------------------------------------
        10.92.100.60/32     10.252.1.9       vlan2         -                 B/I       [70/0]       03h:54m:14s
        10.92.100.71/32     10.252.1.8       vlan2         -                 B/I       [70/0]       03d:09h:39m
                            10.252.1.7       vlan2         -                           [70/0]       03d:09h:39m
                            10.252.1.9       vlan2         -                           [70/0]       03d:09h:39m
        10.92.100.81/32     10.252.1.9       vlan2         -                 B/I       [70/0]       03d:09h:39m
        10.92.100.82/32     10.252.1.8       vlan2         -                 B/I       [70/0]       03h:51m:26s
                            10.252.1.7       vlan2         -                           [70/0]       03h:51m:26s
        10.92.100.85/32     10.252.1.8       vlan2         -                 B/I       [70/0]       03d:09h:33m
                            10.252.1.7       vlan2         -                           [70/0]       03d:09h:33m
                            10.252.1.9       vlan2         -                           [70/0]       03d:09h:33m
        10.92.100.222/32    10.252.1.7       vlan2         -                 B/I       [70/0]       03d:09h:39m
        10.92.100.225/32    10.252.1.8       vlan2         -                 B/I       [70/0]       04h:06m:57s
                            10.252.1.7       vlan2         -                           [70/0]       04h:06m:57s
                            10.252.1.9       vlan2         -                           [70/0]       04h:06m:57s
        10.94.100.60/32     10.252.1.9       vlan2         -                 B/I       [70/0]       03h:54m:14s
        10.94.100.71/32     10.254.1.14      vlan4         -                 B/I       [70/0]       03d:09h:39m
                            10.254.1.12      vlan4         -                           [70/0]       03d:09h:39m
                            10.254.1.10      vlan4         -                           [70/0]       03d:09h:39m
        10.94.100.85/32     10.254.1.14      vlan4         -                 B/I       [70/0]       03d:09h:33m
                            10.254.1.12      vlan4         -                           [70/0]       03d:09h:33m
                            10.254.1.10      vlan4         -                           [70/0]       03d:09h:33m
        10.94.100.222/32    10.254.1.10      vlan4         -                 B/I       [70/0]       03d:09h:39m
        10.94.100.225/32    10.254.1.14      vlan4         -                 B/I       [70/0]       04h:06m:57s
                            10.254.1.12      vlan4         -                           [70/0]       04h:06m:57s
                            10.254.1.10      vlan4         -                           [70/0]       04h:06m:57s

        Total Route Count : 29
        ```

        There should be a route for each unique LoadBalancer IP addresses configured in the cluster.



