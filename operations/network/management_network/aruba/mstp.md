# Multiple Spanning Tree Protocol (MSTP)

MSTP (802.1s) ensures that only one active path exists between any two nodes in a spanning-tree instance.
A spanning-tree instance comprises a unique set of VLANs. MSTP instances significantly improve network
resource utilization while maintaining a loop-free environment.

## Configuration commands

Enable MSTP (default mode for spanning-tree):

```text
switch# spanning-tree
switch# spanning-tree config-name <NAME>
switch# spanning-tree config-revision <VALUE> Configure an MSTP instance and priority
switch# spanning-tree instance VALUE vlan VLANS
switch# spanning-tree instance VALUE priority VALUE
```

Show commands to validate functionality:

```text
switch# show spanning-tree mst detail
```

## Example output

```text
switch# show span
Spanning tree status
Extended System-id
Ignore PVID Inconsistency : Disabled
Path cost method          : Long
VLAN1 Root ID
Priority   : 32769
MAC-Address: 70:72:cf:1d:32:04
This bridge is the root
Hello time(in seconds):2  Max Age(in seconds):20
Forward Delay(in seconds):15
: Enabled Protocol: MSTP
: Enabled
  Bridge ID  Priority  : 32768
             MAC-Address: 70:72:cf:1d:32:04
             Hello time(in seconds):2  Max Age(in seconds):20
             Forward Delay(in seconds):15
Port         Role           State        Cost    Priority   Type
------------ -------------- ------------ ------- ---------- ----------
```

## Expected results

1. Spanning-tree mode is configured
2. Spanning-tree is enabled, if loops are detected ports should go blocked state
3. Spanning-tree splits traffic domain between two DUTs

[Back to Index](../index.md)
