# SNMPv2c community

The switch supports SNMPv2c community-based security for Read-Only access.

Relevant Configuration

Configure an SNMPv2c community name

```
switch(config)# snmp-server community community-name 
```

Show Commands to Validate Functionality

```
switch# show snmp community
```

Expected Results

* Step 1: You can configure the community name
* Step 2: You can bind the SNMP server to the default VRF
* Step 3: You can connect from the workstation using the community name

[Back to Index](../index.md)
