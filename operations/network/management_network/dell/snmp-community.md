# Configure SNMPv2c Community

The switch supports SNMPv2c community-based security for read-only access.

## Configuration Commands

Configure an SNMPv2c community name:

```
switch(config)# snmp-server community community-name
```

Show commands to validate functionality:

```
switch# show snmp community
```

## Expected Results

1. Administrators can configure the community name
2. Administrators can bind the SNMP server to the default VRF
3. Administrators can connect from the workstation using the community name

[Back to Index](index.md)
