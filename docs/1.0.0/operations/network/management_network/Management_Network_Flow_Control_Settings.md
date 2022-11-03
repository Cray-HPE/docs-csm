# Management Network Flow Control Settings

This page is designed to go over all the flow control settings for Dell/Mellanox systems.

## Leaf Switch Node Connections

For the node connections to a leaf switch, disable the transmit flowcontrol and enable receive flowcontrol with the following commands:

**NOTE:** If using a TDS system involving a Hill cabinet, make sure to confirm that no CMM nor CEC components are connected to any leaf switches in your system. If these components are connected to the leaf, confirm to which ports they are connected, and modify the commands below to avoid modifying the flowcontrol settings of those ports.
```
sw-leaf-001# configure terminal
sw-leaf-001(config)# interface range ethernet 1/1/1-1/1/48
sw-leaf-001(conf-range-eth1/1/1-1/1/48)# flowcontrol receive on
sw-leaf-001(conf-range-eth1/1/1-1/1/48)# flowcontrol transmit off
sw-leaf-001(conf-range-eth1/1/1-1/1/48)# end
sw-leaf-001# write memory
```

## Switch-to-Switch Connections for MLAG, VLT, or VSX
Flowcontrol is supposed to be enabled on the IPL for Mellanox MLAG.
Flowcontrol settings are defined elsewhere for the links between redundant Dell, Mellanox, or Aruba switches. This includes IPL and keepalive interfaces. This document is not relevant for those links.

The configuration below is supposed to be on for Mellanox MLAG:
```
   dcb priority-flow-control enable force
   interface port-channel 100 dcb priority-flow-control mode on force
```

## Switch-to-Switch Connections

Disable flowcontrol in both directions for all switch-to-switch connections: spine-to-leaf; spine-to-CDU; spine-to-aggregate; and aggregate-to-leaf (It is unlikely that any system has every type of connection).

How to identify which ports are part of a switch-to-switch connection will be covered first, and then the commands to make the changes. The commands for each switch group are provided separately, but it is strongly recommended to make the configuration changes for each end of the connection in short order; for example, for a spine-leaf connection, do not make the changes on the spine side if changes cannot also be made to the leaf switch end of the connection within a couple minutes.
Repeat the above commands for each leaf switch in the system. These changes can be performed before the switch-to-switch connections, or concurrent with those changes.

Recommended order of flow control changes for switch-to-switch connections:
1. Make change on sw-spine-001 side of leaf/aggregate/CDU ISL connections.
2. Make change on sw-spine-002 side of leaf/aggregate/CDU ISL connections.
3. Make change on leaf/aggregate/CDU side of spine ISL connections.
4. Make change on aggregate01/CDU01 side of VLT ISL connections.
5. Make change on aggregate02/CDU02 side of VLT ISL connections.
6. Repeat Steps 4 and 5 for each aggregate/CDU switch pair.
7. Make change on aggregate side of leaf ISL connections.
8. Make change on leaf side of aggregate ISL connections.

## Identify Switch-to-Switch Connections

#### Leaf Switches

Our standard for the configuration uses 'port-channel 100' for the connection to the spine or aggregate switch. To get what ports are part of this composite interface, use the following command:
```
sw-leaf-001# show interface port-channel 100 summary
LAG     Mode      Status    Uptime              Ports
100     L2-HYBRID up        2 weeks 5 days 01:2 Eth 1/1/51 (Up)
                                                Eth 1/1/52 (Up)
```
The physical ports in this example are '1/1/51' and '1/1/52'. Record this information for each leaf switch.

#### CDU Switches

In order to get the ports involved in the connection to the spine switches, use the command shared for the leaf switch above.

The ports connecting the pair of CDU switches together is also required. The best way to determine the ports involved is to run the following command:
```
sw-cdu-001# show running-configuration | grep discovery
 discovery-interface ethernet1/1/25,1/1/29
```
The ports 1/1/25 and 1/1/29 in this example are being used as connections between the CDU switches. As with the connection to the spine, record the ports involved.

**NOTE:** It is very important that the flowcontrol settings for the CMM and CEC devices connected to the CDU switches NOT be modified.

#### Aggregate Switches

On large air-cooled systems, aggregate switches are situated between the leaf and spine switches. In general, it is expected that every port that is up on these switches to either be a connection to the spine (as 'port-channel 100'), a connection to a leaf, or a connection to its peer aggregate switch. To see which ports are currently up, run the following command:

```
sw-10g01# show interface status

--------------------------------------------------------------------------------------------------
Port            Description     Status   Speed    Duplex   Mode Vlan Tagged-Vlans
--------------------------------------------------------------------------------------------------
Eth 1/1/1       LEAF_CONN_1     up       10G      full     -
Eth 1/1/2       LEAF_CONN_2     up       10G      full     -
Eth 1/1/3       LEAF_CONN_3     up       10G      full     -
Eth 1/1/4       LEAF_CONN_4     up       10G      full     -
Eth 1/1/5       LEAF_CONN_5     up       10G      full     -
Eth 1/1/6       LEAF_CONN_6     up       10G      full     -
Eth 1/1/7       LEAF_CONN_7     up       10G      full     -
Eth 1/1/8       LEAF_CONN_8     up       10G      full     -
Eth 1/1/9       LEAF_CONN_9     up       10G      full     -
Eth 1/1/10                      down     0        full     A    1    -
Eth 1/1/11                      down     0        full     A    1    -
Eth 1/1/12                      down     0        full     A    1    -
Eth 1/1/13                      down     0        full     A    1    -
Eth 1/1/14                      down     0        full     A    1    -
Eth 1/1/15                      down     0        full     A    1    -
Eth 1/1/16                      down     0        full     A    1    -
Eth 1/1/17                      down     0        full     A    1    -
Eth 1/1/18                      down     0        full     A    1    -
Eth 1/1/19                      down     0        full     A    1    -
Eth 1/1/20                      down     0        full     A    1    -
Eth 1/1/21                      down     0        full     A    1    -
Eth 1/1/22                      down     0        full     A    1    -
Eth 1/1/23                      down     0        full     A    1    -
Eth 1/1/24                      down     0        full     A    1    -
Eth 1/1/25                      up       100G     full     -
Eth 1/1/26                      down     0        full     A    1    -
Eth 1/1/27                      up       40G      full     -
Eth 1/1/28                      up       40G      full     -
Eth 1/1/29                      up       100G     full     -
Eth 1/1/30                      down     0        full     A    1    -
Eth 1/1/31                      down     0        full     A    1    -
Eth 1/1/32                      down     0        full     A    1    -
Eth 1/1/33                      down     0        full     A    1    -
Eth 1/1/34                      down     0        full     A    1    -
Eth 1/1/35                      down     0        full     A    1    -
Eth 1/1/36                      down     0        full     A    1    -
Eth 1/1/37                      down     0        full     A    1    -
Eth 1/1/38                      down     0        full     A    1    -
Eth 1/1/39                      down     0        full     A    1    -
Eth 1/1/40                      down     0        full     A    1    -
Eth 1/1/41                      down     0        full     A    1    -
Eth 1/1/42                      down     0        full     A    1    -
Eth 1/1/43                      down     0        full     A    1    -
Eth 1/1/44                      down     0        full     A    1    -
Eth 1/1/45                      down     0        full     A    1    -
Eth 1/1/46                      down     0        full     A    1    -
Eth 1/1/47                      down     0        full     A    1    -
Eth 1/1/48                      down     0        full     A    1    -
Eth 1/1/49                      down     0        full     A    1    -
Eth 1/1/50                      down     0        full     A    1    -
Eth 1/1/51                      down     0        full     A    1    -
Eth 1/1/52                      down     0        full     A    1    -
Eth 1/1/53                      down     0        full     A    1    -
Eth 1/1/54                      down     0        full     A    1    -
--------------------------------------------------------------------------------------------------
```
From the output in this example, ports 1/1/1 through 1/1/9, 1/1/25, and 1/1/27 through 1/1/29 are up. Record this information.

#### Spine Switches

The convenient way to identify the ports involved with connections to other switches is to look at the output from `show interface status`.

```
sw-spine-001 [standalone: master] # show interfaces status

--------------------------------------------------------------------------------------------------------------------------------------------------------
Port                  Operational state     Admin                           Speed             MTU               Description
--------------------------------------------------------------------------------------------------------------------------------------------------------
mgmt1                 Down                  Enabled                         UNKNOWN           1500              -
mgmt0                 Down                  Enabled                         UNKNOWN           1500              -
Po100                 Up                    Enabled                                           9216              mlag-isl
Mpo1                  Up                    Enabled                                           9216              -
Mpo2                  Up                    Enabled                                           9216              -
Mpo3                  Up                    Enabled                                           9216              -
Mpo4                  Up                    Enabled                                           9216              -
Mpo5                  Up                    Enabled                                           9216              -
Mpo6                  Up                    Enabled                                           9216              -
Mpo7                  Up                    Enabled                                           9216              -
Mpo8                  Up                    Enabled                                           9216              -
Mpo9                  Up                    Enabled                                           9216              -
Mpo10                 Up                    Enabled                                           9216              -
Mpo11                 Up                    Enabled                                           9216              -
Mpo17                 Up                    Enabled                                           9216              -
Mpo113                Up                    Enabled                                           9216              -
Mpo151                Up                    Enabled                                           9216              -
Mpo152                Up                    Enabled                                           9216              -
Eth1/1 (Mpo1)         Up                    Enabled                         40G               9216              -
Eth1/2 (Mpo2)         Up                    Enabled                         40G               9216              -
Eth1/3 (Mpo3)         Up                    Enabled                         40G               9216              -
Eth1/4 (Mpo4)         Up                    Enabled                         40G               9216              -
Eth1/5 (Mpo5)         Up                    Enabled                         40G               9216              -
Eth1/6 (Mpo6)         Up                    Enabled                         40G               9216              -
Eth1/7 (Mpo7)         Up                    Enabled                         40G               9216              -
Eth1/8 (Mpo8)         Up                    Enabled                         40G               9216              -
Eth1/9 (Mpo9)         Up                    Enabled                         40G               9216              -
Eth1/10 (Mpo10)       Up                    Enabled                         40G               9216              -
Eth1/11 (Mpo11)       Up                    Enabled                         40G               9216              -
Eth1/12 (Po100)       Up                    Enabled                         40G               9216              sw-spine-002-1/12
Eth1/13 (Mpo113)      Up                    Enabled                         40G               9216              -
Eth1/14 (Mpo113)      Up                    Enabled                         40G               9216              -
Eth1/15/1 (Mpo151)    Up                    Enabled                         10G               9216              -
Eth1/15/2 (Mpo152)    Up                    Enabled                         10G               9216              -
Eth1/15/3             Down                  Enabled                         Unknown           1500              -
Eth1/15/4             Down                  Enabled                         Unknown           1500              -
Eth1/17 (Mpo17)       Up                    Enabled                         40G               9216              -
Eth1/18 (Po100)       Up                    Enabled                         40G               9216              sw-spine-002-1/18
Eth1/19               Up                    Enabled                         10G               1500              -
Eth1/20               Down                  Enabled                         Unknown           1500              -
Eth1/21               Down                  Enabled                         Unknown           1500              -
Eth1/22               Down                  Enabled                         Unknown           1500              -
Eth1/23               Down                  Enabled                         Unknown           1500              -
Eth1/24               Down                  Enabled                         Unknown           1500              -
Eth1/25               Down                  Enabled                         Unknown           1500              -
Eth1/26               Down                  Enabled                         Unknown           1500              -
Eth1/27               Down                  Enabled                         Unknown           1500              -
Eth1/28               Down                  Enabled                         Unknown           1500              -
Eth1/29               Down                  Enabled                         Unknown           1500              -
Eth1/30               Down                  Enabled                         Unknown           1500              -
Eth1/31               Down                  Enabled                         Unknown           1500              -
Eth1/32               Down                  Enabled                         Unknown           1500
```
The links between the 2 spines should be `port-channel` 100 (`Po100`). The `mlag-port-channel` interfaces which are connections to leaf, aggregate, or CDU switches would be `Mpo` interfaces with indices greater than 100. So here, `Mpo1`-`Mpo11` and `Mpo17` are connections to NCNs, whereas `Mpo113`, `Mpo151`, and `Mpo152` are connections to other switches. When identifying the `port-channel` and `mlag-port-channel` devices, look for the `Eth` rows, which have one of these labels in parentheses next to it. In the example above, these are:

- Eth1/12
- Eth1/13
- Eth1/14
- Eth1/15/1
- Eth1/15/2
- Eth1/18

Record these ports **AND** the port-channel and mlag-port-channel interfaces.

#### Spine Switch 'flowcontrol' Configuration Change

On the Mellanox spine switches, modify the flowcontrol settings on the port-channel, mlag-port-channel, and Ethernet interfaces. The general form looks similar to the following:

```
sw-spine-001 [standalone: master] # configure terminal
sw-spine-001 [standalone: master] (config) # interface port-channel <index> flowcontrol receive off force
sw-spine-001 [standalone: master] (config) # interface port-channel <index> flowcontrol send off force
sw-spine-001 [standalone: master] (config) # interface mlag-port-channel <index> flowcontrol receive off force
sw-spine-001 [standalone: master] (config) # interface mlag-port-channel <index> flowcontrol send off force
sw-spine-001 [standalone: master] (config) # interface ethernet <port> flowcontrol receive off force
sw-spine-001 [standalone: master] (config) # interface ethernet <port> flowcontrol send off force
sw-spine-001 [standalone: master] (config) # exit
sw-spine-001 [standalone: master] # write memory
```
"index" is the number after "Po" or "Mpo", so "113" or "151". "<port>" would be the value after "Eth", so "1/14" or "1/15/2". Make sure to run the `flowcontrol` commands for each mlag-port-channel and Ethernet port.

#### Leaf, CDU, and Aggregate Switch 'flowcontrol' Configuration Change

On the Dell switches, only modify the Ethernet interface configurations. The general form looks similar to the following:

```
sw-leaf-001# configure terminal
sw-leaf-001(config)# interface ethernet <port>
sw-leaf-001(conf-if-eth<port>)# flowcontrol receive off
sw-leaf-001(conf-if-eth<port>)# flowcontrol transmit off
sw-leaf-001(conf-if-eth<port>)# end
sw-leaf-001# write memory
```
Do this for each port. Alternatively, set it up to do multiple ports as one command. For instance, the common leaf switch would have ports 51 and 52 as connections to the spine. So in that case, these commands would work:

```
sw-leaf-001# configure terminal
sw-leaf-001(config)# interface range ethernet 1/1/51-1/1/52
sw-leaf-001(conf-if-eth1/1/51-1/1/52)# flowcontrol receive off
sw-leaf-001(conf-if-eth1/1/51-1/1/52)# flowcontrol transmit off
sw-leaf-001(conf-if-eth1/1/51-1/1/52)# end
sw-leaf-001# write memory
```

Alternatively, a typical CDU switch would have ports 27 and 28 as uplinks to the spine, with ports 25 and 29 as connections to the peer CDU switch. So in that case, use the following commands:

```
sw-cdu-001# configure terminal
sw-cdu-001(config)# interface range ethernet 1/1/25,1/1/27-1/1/29
sw-cdu-001(conf-range-eth1/1/25,1/1/27-1/1/29)# flowcontrol receive off
sw-cdu-001(conf-range-eth1/1/25,1/1/27-1/1/29)# flowcontrol transmit off
sw-cdu-001(conf-range-eth1/1/25,1/1/27-1/1/29)# end
sw-cdu-001# write memory
```

#### Disable iSCSI on Dell Switches (Leaf, CDU, and Aggregate)

The final configuration change needed on the Dell switches is to disable iSCSI in the configuration. This change ensures that all of the flowcontrol changes made above will persist through a reboot of the switch.

Run the following commands on all Dell switches in the system:

```
sw-leaf-001# configure terminal
sw-leaf-001(config)# no iscsi enable
sw-leaf-001(config)# exit
sw-leaf-001# write memory
```
