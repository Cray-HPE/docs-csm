# Link Layer Discovery Protocol (LLDP)

LLDP is used to advertise the device's identity and abilities and read other devices connected to the same network.

> **NOTE** LLDP is enabled by default.

## Configuration commands

(`switch(config-if)#`) Enable an interface to receive or transmit LLDP packets:

```text
lldp <receive|transmit>
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show lldp [local-device|neighbor-info|statistics]
```

(`switch(config)#`)

```text
show lldp configuration
```

Example output:

```text
LLDP Global Configuration:
LLDP Enabled :Yes
LLDP Transmit Interval :30
LLDP Hold time Multiplier :4
LLDP Transmit Delay Interval:2
LLDP Reinit time Interval :2
Optional TLVs configured:
Management Address
Port description
Port VLAN-ID
System capabilities
System description
System name
LLDP Port Configuration:
Port           Tx-Enabled          Rx-Enabled
1/1/1          Yes                 Yes
...
```

(`switch(config)#`)

```text
show lldp local-device
```

Example output:

```text
Global Data
---------------
Chassis-id
60
Total Packets transmitted : 198
Total Packets received : 170
Total Packet received and discarded : 0
Total TLVs unrecognized : 0
LLDP Port Statistics:
Port-ID        Tx-Packets     Rx-packets     Rx-discarded   TLVs-Unknown
1/1/1          70             43             0              0
1/1/3          70             70             0              0
```

[Back to Index](../README.md)
