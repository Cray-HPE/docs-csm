# Management Network Spanning-Tree Configuration.

Spanning tree is used to protect the network against layer2 loops.

It is not recommended to add/adjust these settings while a system is running.

# Aruba Configuration

The following configuration is applied to each of the Spine VSX pairs, this config is identical.
```
spanning-tree mode rpvst
spanning-tree
spanning-tree priority 7
spanning-tree vlan 1,2,4,7,10
```

Verify that each VSX pair is the root bridge for all VLANs configured on that switch.
```
sw-spine-001# show spanning-tree summary root
STP status            : Enabled
Protocol              : RPVST
System ID             : 02:01:00:00:01:00

Root bridge for VLANs : 1,2,4,7,10

                                         Root Hello Max Fwd
VLAN     Priority Root ID                cost  Time Age Dly    Root Port
-------- -------- ----------------- --------- ----- --- --- ------------
VLAN1       32768 02:01:00:00:01:00         0     2  20  15            0
VLAN2       32768 02:01:00:00:01:00         0     2  20  15            0
VLAN4       32768 02:01:00:00:01:00         0     2  20  15            0
VLAN7       32768 02:01:00:00:01:00         0     2  20  15            0
VLAN10      32768 02:01:00:00:01:00         0     2  20  15            0
```

The following configuration is applied to Aruba leaf/Aggregation switches.
```
spanning-tree mode rpvst
spanning-tree
spanning-tree vlan 1,2,4,7,10
```

Verify Spanning tree is configured and we are not the Root Bridge for any VLANs.

```
sw-leaf-001# show spanning-tree summary root
STP status            : Enabled
Protocol              : RPVST
System ID             : 88:3a:30:9f:24:80

Root bridge for VLANs :

                                         Root Hello Max Fwd
VLAN     Priority Root ID                cost  Time Age Dly    Root Port
-------- -------- ----------------- --------- ----- --- --- ------------
VLAN1       32768 02:01:00:00:01:00       800     2  20  15         lag1
VLAN2       32768 02:01:00:00:01:00       800     2  20  15         lag1
VLAN4       32768 02:01:00:00:01:00       800     2  20  15         lag1
VLAN7       32768 02:01:00:00:01:00       800     2  20  15         lag1
VLAN10      32768 02:01:00:00:01:00       800     2  20  15         lag1
```

The following config is applied to Aruba CDU switches.
If there are more 2xxx or 3xxx VLANs you will add them to the ```spanning-tree vlan``` list
```
spanning-tree mode rpvst
spanning-tree
spanning-tree vlan 1,2,4,2000,3000,4091
```

Verify that each CDU switch is the root bridge for VLANs 2xxx and 3xxx

```
sw-cdu-002# show spanning-tree summary root
STP status            : Enabled
Protocol              : RPVST
System ID             : 02:01:00:00:01:02

Root bridge for VLANs : 2000,3000,4091

                                         Root Hello Max Fwd
VLAN     Priority Root ID                cost  Time Age Dly    Root Port
-------- -------- ----------------- --------- ----- --- --- ------------
VLAN1       32768 02:01:00:00:01:00       200     2  20  15       lag149
VLAN2       32768 02:01:00:00:01:00       200     2  20  15       lag149
VLAN4       32768 02:01:00:00:01:00       200     2  20  15       lag149
VLAN2000    32768 02:01:00:00:01:02         0     2  20  15            0
VLAN3000    32768 02:01:00:00:01:02         0     2  20  15            0
VLAN4091    32768 02:01:00:00:01:02         0     2  20  15            0
```

# Dell Configuration
Spanning tree configuration has not changed on Dell switches from 1.3 to 1.4

Dell leaf configuration
```
spanning-tree vlan 1-2,4,7,10 priority 61440
```

Dell CDU configuration
```
spanning-tree vlan 1-2,4,4091 priority 61440
```

# Mellanox Configuration

Spanning tree will need to be applied to each MAGP pair.  Spine01 will have a lower priority making it the root bridge.
Spanning tree configuration has not changed from 1.3 to 1.4.

```
## STP configuration
##
   spanning-tree mode rpvst
   spanning-tree port type edge default
   interface ethernet 1/13-1/14 spanning-tree port type network
   interface ethernet 1/15/1-1/15/2 spanning-tree port type network
   interface mlag-port-channel 113 spanning-tree port type network
   interface mlag-port-channel 151-152 spanning-tree port type network
   interface ethernet 1/13-1/14 spanning-tree guard root
   interface ethernet 1/15/1-1/15/2 spanning-tree guard root
   interface mlag-port-channel 113 spanning-tree guard root
   interface mlag-port-channel 151-152 spanning-tree guard root
   spanning-tree port type edge bpdufilter default
   spanning-tree port type edge bpduguard default
   spanning-tree vlan 1-2 priority 0
   spanning-tree vlan 4 priority 0
   spanning-tree vlan 7 priority 0
   spanning-tree vlan 10 priority 0
```

