# Multiple spanning tree protocol (MSTP)

MSTP (802.1s) ensures that only one active path exists between any two nodes in a spanning-tree instance. A spanning-tree instance comprises a unique set of VLANs. MSTP instances significantly improve network resource utilization while maintaining a loop-free environment.

Relevant Configuration

Enable MSTP (default mode for spanning-tree)

```
switch(config)# spanning-tree mode mst
switch(conf-mstp)# name my-mstp-region
switch(conf-mstp)# revision 0
```

Show Commands to Validate Functionality

```
switch# show spanning-tree mst
```

Expected Results

* Step 1: Spanning-tree mode is configured
* Step 2: Spanning-tree is enabled, if loops are detected ports should go blocked state.
* Step 3: Spanning-tree splits traffic domain between two DUTs

[Back to Index](index.md)

