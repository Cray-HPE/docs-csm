# Management Network Access Port Configurations

## Requirements
- Access to switches
- SHCD

## Configuration

- This configuration describes the edge port configuration. This configuration is in the NMN/HMN/Mountain-TDS Management Tab of the SHCD.

- Typically, these are ports that are connected to iLOs (BMCs), gateway nodes, or compute nodes/CMM switches.

  ```
  sw-leaf-001(config)#
      interface 1/1/35
      no shutdown
      no routing
      vlan access 4
      spanning-tree bpdu-guard
      spanning-tree port-type admin-edge
  ```

- This configuration describes the ports that go to the Node Management Network (NMN/VLAN2).

- Identify these ports by referencing the NMN tab on the SHCD.

  ```
  sw-leaf-001(config)#
      interface 1/1/35
      no shutdown
      no routing
      vlan access 2
      spanning-tree bpdu-guard
      spanning-tree port-type admin-edge
  ```

## Apollo Server Port Configuration
This is for the Apollo XL645d only.

iLO BMC port:
```
sw-leaf-001(config)#
    interface 1/1/46
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
    exit
```
NMN port from OCP card:
```
interface 1/1/14
    no shutdown
    no routing
    vlan access 2
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
    exit
```

## UAN Port Configuration
- UANs have the same network connections as Shasta v1.3.
- One connection will go to a NMN(VLAN2) access port, this is where the UAN will pxe boot and communicate with internal systems (see SHCD for UAN cabling).
- ONE OF THESE PORTS IS SHUTDOWN.
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a TRUNK port for the CAN connection.

Aruba UAN NMN Configuration:
```
sw-spine-001 (config)#
    interface 1/1/16
    no shutdown
    mtu 9198
    no routing
    vlan access 2
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
    exit

sw-spine-002 (config)#
    interface 1/1/16
    shutdown
    mtu 9198
    no routing
    vlan access 2
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
    exit
```

Aruba UAN CAN Configuration:

Port configuration is the same on both switches.
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

## Gigabyte/Intel NCN Worker Port Configuration
The cabling guidelines for all servers can be found in [Cable Management Network Servers](../../../install/cable_management_network_servers.md).

Aruba port configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int ethernet 1/1
interface ethernet 1/1 speed 40G force
interface ethernet 1/1 mtu 9216 force
interface ethernet 1/1 mlag-channel-group 1 mode active
```
Aruba LAG configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int mlag-port-channel 1
interface mlag-port-channel 1
interface mlag-port-channel 1 mtu 9216 force
interface mlag-port-channel 1 switchport mode hybrid
interface mlag-port-channel 1 no shutdown
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 10
```

## HPE NCN Worker Port Configuration
Aruba port configuration:
```
sw-spine-001 & sw-spine-002 (config)#
    interface 1/1/7
    shutdown
    mtu 9198
    lag 4
    exit
```
Aruba LAG configuration:
```
sw-spine-001 & sw-spine-002 (config)#
    interface lag 4 multi-chassis
    shutdown
    no routing
    vlan access 10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
```

## Gigabyte/Intel NCN Master port configuration
Mellanox port configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int ethernet 1/1
interface ethernet 1/1 speed 40G force
interface ethernet 1/1 mtu 9216 force
interface ethernet 1/1 mlag-channel-group 1 mode active
```

Mellanox MLAG port configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int mlag-port-channel 1
interface mlag-port-channel 1
interface mlag-port-channel 1 mtu 9216 force
interface mlag-port-channel 1 switchport mode hybrid
interface mlag-port-channel 1 no shutdown
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 1 switchport hybrid allowed-vlan add 10
```

## HPE NCN Master Port Configuration
Aruba port configuration:
```
sw-spine02# show run int 1/1/7
interface 1/1/7
    no shutdown
    mtu 9198
    lag 4
    exit
```
Aruba LAG configuration:
```
sw-spine02# show run int lag 4
interface lag 4 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7
    lacp mode active
    lacp fallback
    exit
```

## Gigabyte/Intel NCN Storage Port Configuration
Mellanox port configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int ethernet 1/7
interface ethernet 1/7 speed 40G force
interface ethernet 1/7 mtu 9216 force
interface ethernet 1/7 mlag-channel-group 7 mode active
```
Mellanox MLAG port configuration:
```
sw-spine-002 [gamora-mlag-domain: master] # show run int mlag-port-channel 7
interface mlag-port-channel 7
interface mlag-port-channel 7 mtu 9216 force
interface mlag-port-channel 7 switchport mode hybrid
interface mlag-port-channel 7 no shutdown
interface mlag-port-channel 7 switchport hybrid allowed-vlan add 2
interface mlag-port-channel 7 switchport hybrid allowed-vlan add 4
interface mlag-port-channel 7 switchport hybrid allowed-vlan add 7
interface mlag-port-channel 7 switchport hybrid allowed-vlan add
```

Mellanox MLAG port configuration:
```
placeholder for config
Mlag, native vlan 1, allowed vlan 10
```
Mellanox port configuration:
```
placeholder
Generic, member of port-channel with speed and mtu set
```

## HPE NCN Storage Port Configuration

Aruba LAG configuration:
```
sw-leaf-003# show run int lag 6
interface lag 6 multi-chassis
    no shutdown
    description ncn-s001:ocp:1
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,6-7
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
    exit
```
Aruba port physical configuration:
```
sw-leaf-003# show run int 1/1/6
interface 1/1/6
    no shutdown
    mtu 9198
    description ncn-s001:ocp:1
    lag 6
    exit

```
Aruba Storage port lag interface configuration (future use):
These will be configured, but the ports will be shut down until needed.
```
sw-leaf-003# show run int lag 3
interface lag 3 multi-chassis
    no shutdown
    description ncn-s001:ocp:2
    no routing
    vlan trunk native 1
    vlan trunk allowed 10
    lacp mode active
    lacp fallback
    spanning-tree port-type admin-edge
    exit
```
Aruba Storage port physical interface configuration (future use):
sw-leaf-003# show run int 1/1/3
interface 1/1/3
    no shutdown
    mtu 9198
    description ncn-s001:ocp:2
    lag 3
    exit

```

# CMM Port Configuration

- This requires updated CMM firmware (version 1.4.20).
- A static LAG will be configured on the CDU switches.
- The CDU switches have two cables (10Gb RJ45) connecting to each CMM.
- This configuration offers increased throughput and redundancy.

## Aruba
Aruba CDU switch configuration.
This configuration is identical across CDU VSX pairs.
The VLANs used here are generated from CSI.

```
sw-cdu-001 & sw-cdu-002 (config)#
    interface lag 1 multi-chassis static
    no shutdown
    description CMM_CAB_9000
    no routing
    vlan trunk native 2000
    vlan trunk allowed 2000,3000,4091

sw-cdu-001 & sw-cdu-002 (config)#
    interface 1/1/1
    no shutdown
    mtu 9198
    lag 1
    exit
```

## Dell

Dell CDU switch configuration.
This configuration is identical across CDU VLT pairs.
The VLANs used here are generated from CSI.

```
sw-cdu-001 & sw-cdu-002 (config)#
    interface port-channel1
    description CMM_CAB_1000
    no shutdown
    switchport mode trunk
    switchport access vlan 2000
    switchport trunk allowed vlan 3000
    mtu 9216
    vlt-port-channel 1

sw-cdu-001 & sw-cdu-002 (config)#
    interface ethernet1/1/1
    description CMM_CAB_1000
    no shutdown
    channel-group 1 mode on
    no switchport
    mtu 9216
    flowcontrol receive on
    flowcontrol transmit on
```

# CEC Port Configuration

The VLAN used here is generated from CSI. It is the HMN_MTN VLAN that is assigned to that cabinet.

## Dell
```
interface ethernet1/1/50
    description CEC_CAB_1003_alt
    no shutdown
    switchport access vlan 3003
    flowcontrol receive off
    flowcontrol transmit off
    spanning-tree bpduguard enable
    spanning-tree port type edge
```

## Aruba
```
sw-cdu-001 & sw-cdu-002 (config)#
    interface 1/1/1
    no shutdown
    mtu 9198
    description cec1
    no routing
    vlan access 3000
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
```
