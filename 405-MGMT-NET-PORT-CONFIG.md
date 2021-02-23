# Management Network Access Port configurations.

# Requirements
- Access to switches
- SHCD

# Configuration

- This configuration describes the edge port configuration, you'll find these in the NMN/HMN/Mountain-TDS Management Tab of the SHCD.
- Typically these are ports that are connected to iLOs (BMCs), gateway nodes, or compute nodes/CMM switches.

```
sw-leaf-001(config)#  interface 1/1/28
sw-leaf-001(config)# no shutdown 
sw-leaf-001(config)# mtu 9198
sw-leaf-001(config)# description HMN
sw-leaf-001(config)# no routing
sw-leaf-001(config)# vlan access 4
```

- This configuration describes the ports that go to the Node Management Network (NMN/VLAN2).
- You can Identify these ports by referencing the NMN tab on the SHCD.

```
sw-leaf-001(config)# interface 1/1/6
sw-leaf-001(config)# no shutdown 
sw-leaf-001(config)# mtu 9198
sw-leaf-001(config)# description NMN
sw-leaf-001(config)# no routing
sw-leaf-001(config)# vlan access 2
```

# UAN port configuration
- UANs are going to have the same network connections as shasta 1.3.
- One connection will go to a NMN(VLAN2) access port, this is where the UAN will pxe boot and communicate with internal systems. (see SHCD for UAN cabling).
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a TRUNK port for the CAN connection.

Aruba UAN NMN Configuration
```
interface 1/1/16
    no shutdown
    mtu 9198
    no routing
    vlan access 2
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
    exit
```

Aruba UAN CAN Configuration

Port Configuration is the same on both switches.
```
interface lag 17 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 7
    lacp mode active
    lacp fallback
    exit
```

- This configuration describes the ports that go to the Mountain CMMs/Computes.
- The CDU switches have two cables connecting to each CMM, we will setup MC-LAG with the CDU switch pairs.
- The second CDU switch in the pair will have it's port to the CMM shutdown, Redundancy is not yet available for the CMM.

First CDU configuration.
```
sw-cdu-001(config)# int lag 2 multi-chassis
sw-cdu-001(config-lag-if)# vsx-sync vlans
sw-cdu-001(config-lag-if)# no shutdown
sw-cdu-001(config-lag-if)# description CMM_CAB_1000
sw-cdu-001(config-lag-if)# no routing
sw-cdu-001(config-lag-if)# vlan trunk native 2000
sw-cdu-001(config-lag-if)# vlan trunk allowed 2000,3000,4091
sw-cdu-001(config-lag-if)# lacp mode active
sw-cdu-001(config-lag-if)# lacp fallback
sw-cdu-001(config-lag-if)# exit

sw-cdu-001(config)# int 1/1/2
sw-cdu-001(config-if)# no shutdown
sw-cdu-001(config-if)# lag 2
sw-cdu-001(config-if)# exit
```

Second CDU configuration
```
sw-cdu-002(config)# int lag 2 multi-chassis
sw-cdu-002(config-lag-if)# vsx-sync vlans
sw-cdu-002(config-lag-if)# shutdown
sw-cdu-002(config-lag-if)# description CMM_CAB_1000
sw-cdu-002(config-lag-if)# no routing
sw-cdu-002(config-lag-if)# vlan trunk native 2000
sw-cdu-002(config-lag-if)# vlan trunk allowed 2000,3000,4091
sw-cdu-002(config-lag-if)# lacp mode active
sw-cdu-002(config-lag-if)# lacp fallback
sw-cdu-002(config-lag-if)# exit

sw-cdu-002(config)# int 1/1/2
sw-cdu-002(config-if)# no shutdown
sw-cdu-002(config-if)# lag 2
sw-cdu-002(config-if)# exit
```
