# Link layer discovery protocol (LLDP) 

LLDP is used to advertise the device's identity and abilities and read other devices connected to the same network. Note: LLDP is enabled by default. 

Relevant Configuration 


Enable an interface to receive or transmit LLDP packets 

```
switch(config-if)# lldp <receive|transmit>
```

Show Commands to Validate Functionality 

```
switch# show lldp [local-device|neighbor-info|statistics]
```

Example Output 

```
switch# show lldp configuration
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
switch# show lldp local-device
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

Expected Results 

* Step 1: Link status between the peer devices is UP 
* Step 2: LLDP is enabled
* Step 3: Local device LLDP Information is displayed
* Step 4: Remote device LLDP information is displayed 
* Step 5: LLDP statistics are displayed 

[Back to Index](../index.md)

