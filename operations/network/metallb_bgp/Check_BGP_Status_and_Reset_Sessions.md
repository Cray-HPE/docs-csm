# Check BGP Status and Reset Sessions

Check the Border Gateway Protocol \(BGP\) status on the Aruba and Mellanox switches and verify that all sessions are in an Established state.
If the state of any session in the table is Idle, then the BGP sessions must be reset.

- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
  - [Mellanox](#mellanox)
  - [Aruba](#aruba)

## Prerequisites

This procedure requires administrative privileges.

## Procedure

The following procedures may not resolve the problem after just one attempt. In some cases, the procedures need to be followed multiple times before the situation resolves.

### Mellanox

1. Verify that all BGP sessions are in an `ESTABLISHED` state for the Mellanox spine switches.

    SSH to each spine switch and check the status of all BGP sessions.

    1. (`ncn#`) SSH to a spine switch.

        For example:

        ```bash
        ssh admin@sw-spine-001.hmn
        ```

    1. (`sw-spine#`) View the status of the BGP sessions.

        ```text
        enable
        show ip bgp vrf all summary
        ```

        Example output:

        ```text
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
        10.101.8.8        4    65536        667385    678016    1634      0      0      6:21:29:59    ESTABLISHED/14
        10.101.8.9        4    65536        667177    678199    1634      0      0      6:21:30:04    ESTABLISHED/18
        10.101.8.10       4    65536        667359    678211    1634      0      0      6:21:30:16    ESTABLISHED/14

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
        10.252.1.7        4    65533        595814    595793    40        0      0      6:21:29:52    ESTABLISHED/12
        10.252.1.8        4    65533        595827    595804    40        0      0      6:21:30:03    ESTABLISHED/16
        10.252.1.9        4    65533        595842    595817    40        0      0      6:21:30:16    ESTABLISHED/12
        ```

        If any of the sessions are in an `IDLE` state, then proceed to the next step.

1. Reset BGP to re-establish the sessions.

    1. (`ncn#`) SSH to each spine switch.

        For example:

        ```bash
        ssh admin@sw-spine-001.hmn
        ```

    1. (`sw-spine#`) Enter enable mode.

        ```text
        enable
        ```

    1. (`sw-spine#`) Verify that BGP is enabled.

        ```text
        show protocols | include bgp
        ```

        If BGP is enabled, then the output should be similar to the following:

        ```text
         bgp:                    enabled
        ```

    1. (`sw-spine#`) Clear the BGP sessions.

        There are two VRF's that may need to be cleared. Clear the VRF that has the `Idle` session state.

        Default VRF:

        ```text
        clear ip bgp vrf default all
        ```

        Customer VRF:

        ```text
        clear ip bgp vrf Customer all
        ```

    1. (`sw-spine#`) Check the status of the BGP sessions to see if they are now `ESTABLISHED`.

        It may take a few minutes for sessions to become `ESTABLISHED`.

        ```text
        enable
        show ip bgp vrf all summary
        ```

        Example output:

        ```text
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
        10.101.8.8        4    65536        667385    678016    1634      0      0      6:21:29:59    ESTABLISHED/14
        10.101.8.9        4    65536        667177    678199    1634      0      0      6:21:30:04    ESTABLISHED/18
        10.101.8.10       4    65536        667359    678211    1634      0      0      6:21:30:16    ESTABLISHED/14

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
        10.252.1.7        4    65533        595814    595793    40        0      0      6:21:29:52    ESTABLISHED/12
        10.252.1.8        4    65533        595827    595804    40        0      0      6:21:30:03    ESTABLISHED/16
        10.252.1.9        4    65533        595842    595817    40        0      0      6:21:30:16    ESTABLISHED/12
        ```

    Once all sessions are in an `ESTABLISHED` state, BGP reset is complete.

### Aruba

1. Verify that all BGP sessions are in an `Established` state for the Aruba spine switches.

    SSH to each spine switch and check the status of all BGP sessions.

    1. (`ncn#`) SSH to a spine switch.

        ```bash
        ssh admin@sw-spine-001.hmn
        ```

    1. (`sw-spine#`) View the status of the BGP sessions.

        ```text
        show bgp all-vrf all summary
        ```

        Example output:

        ```text
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

        If any of the sessions are in an `Idle` state, then proceed to the next step.

1. Reset BGP to re-establish the sessions.

    1. (`ncn#`) SSH to each spine switch.

        For example:

        ```bash
        ssh admin@sw-spine-001.hmn
        ```

    1. (`sw-spine#`) Clear the BGP sessions.

        There are two VRF's that may need to be cleared. Clear the VRF that has the `Idle` session state.

        Default VRF:

        ```text
        clear bgp vrf default *
        ```

        Customer VRF:

        ```text
        clear bgp vrf Customer *
        ```

    1. (`sw-spine#`) Check the status of the BGP sessions.

        It may take a few minutes for sessions to become `Established`.

        ```text
        show bgp all-vrf all summary
        ```

        Example output:

        ```text
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

    Once all sessions are in an `Established` state, BGP reset is complete.
