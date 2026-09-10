# Multiple Spanning Tree Protocol (MSTP)

MSTP (`802.1s`) ensures that only one active path exists between any two nodes in a `spanning-tree` instance.
A `spanning-tree` instance comprises a unique set of VLANs. MSTP instances significantly improve network
resource utilization while maintaining a loop-free environment.

## Configuration commands

(`switch#`) Enable MSTP (default mode for `spanning-tree`):

```text
spanning-tree
spanning-tree mode mstp
spanning-tree mst revision 1
spanning-tree mst name mellanox
```

## Show commands to validate functionality

(`switch#`)

```text
show spanning-tree
```

## Expected results

* `spanning-tree` mode is configured.
* `spanning-tree` is enabled, if loops are detected ports should go blocked state.
* `spanning-tree` splits traffic domain between two DUTs.

[Back to Index](../README.md)
