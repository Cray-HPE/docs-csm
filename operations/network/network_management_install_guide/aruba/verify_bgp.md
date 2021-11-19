# Verify BGP

Verify the BGP neighbors are in the established state on BOTH the switches.

How to check Aruba BGP status:

```
sw-spine-002# show bgp ipv4 u s

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

[Back to Index](./index.md)