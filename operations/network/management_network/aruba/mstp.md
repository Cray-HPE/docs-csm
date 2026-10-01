# Multiple Spanning Tree Protocol (MSTP)

MSTP (`802.1s`) ensures that only one active path exists between any two nodes in a `spanning-tree` instance.
A `spanning-tree` instance comprises a unique set of VLANs. MSTP instances significantly improve network
resource utilization while maintaining a loop-free environment.

## Configuration commands

(`switch#`) Enable MSTP (default mode for `spanning-tree`):

```text
spanning-tree
spanning-tree config-name <NAME>
spanning-tree config-revision <VALUE> Configure an MSTP instance and priority
spanning-tree instance VALUE vlan VLANS
spanning-tree instance VALUE priority VALUE
```

## Show commands to validate functionality

(`switch#`)

```text
show spanning-tree mst detail
```

(`switch#`)

```text
show span
```

Example output:

```text
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

* `spanning-tree` mode is configured.
* `spanning-tree` is enabled, if loops are detected ports should go blocked state.
* `spanning-tree` splits traffic domain between two DUTs.

[Back to Index](../README.md)
