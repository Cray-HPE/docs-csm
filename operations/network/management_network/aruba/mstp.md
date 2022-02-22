# Multiple spanning tree protocol (MSTP) 

MSTP (802.1s) ensures that only one active path exists between any two nodes in a spanning-tree instance. A spanning- tree instance comprises a unique set of VLANs. MSTP instances significantly improve network resource utilization while maintaining a loop-free environment. 

Relevant Configuration 

Enable MSTP (default mode for spanning-tree) 

```
switch(config)# spanning-tree
switch(config)# spanning-tree config-name <NAME> 
switch(config)# spanning-tree config-revision <VALUE> Configure an MSTP instance and priority
switch(config)# spanning-tree instance VALUE vlan VLANS 
switch(config)# spanning-tree instance VALUE priority VALUE 
```

Show Commands to Validate Functionality 

```
switch# show spanning-tree mst detail
```

Example Output 

```
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

Expected Results 

* Step 1: Spanning-tree mode is configured
* Step 2: Spanning-tree is enabled, if loops are detected ports should go blocked state.
* Step 3: Spanning-tree splits traffic domain between two DUTs

[Back to Index](../index.md)
