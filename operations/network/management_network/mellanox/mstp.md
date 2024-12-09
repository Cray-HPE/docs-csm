# Multiple spanning tree protocol (MSTP)

MSTP (802.1s) ensures that only one active path exists between any two nodes in a spanning-tree instance.
A spanning-tree instance comprises a unique set of VLANs. MSTP instances significantly improve network
resource utilization while maintaining a loop-free environment.

## Configuration commands

(`sw#`) Enable MSTP (default mode for spanning-tree)

```text
spanning-tree
spanning-tree mode mstp
spanning-tree mst revision 1
spanning-tree mst name mellanox
```

Show commands to validate functionality

```text
show spanning-tree
```

## Expected results

1. Spanning-tree mode is configured
1. Spanning-tree is enabled, if loops are detected ports should go blocked state.
1. Spanning-tree splits traffic domain between two DUTs

[Back to Index](../README.md)
