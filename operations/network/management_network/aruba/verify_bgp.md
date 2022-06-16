# Verify BGP

Verify the BGP neighbors are in the established state on BOTH the switches.

## Procedure

1. Check Aruba BGP status.

    ```bash
    show bgp ipv4 u s
    ```

    Example output:

    ```
    VRF : default
    BGP Summary
    -----------
    Local AS               : 65533        BGP Router Identifier  : 10.252.0.3
    Peers                  : 4            Log Neighbor Changes   : No
    Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
    Confederation Id       : 0

    Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
    10.252.0.2      65533       45052   45044   02m:02w:02d  Established   Up
    10.252.1.7      65533       78389   90090   02m:02w:02d  Established   Up
    10.252.1.8      65533       78384   90059   02m:02w:02d  Established   Up
    10.252.1.9      65533       78389   90108   02m:02w:02d  Established   Up
    ```

[Back to Index](../README.md)
