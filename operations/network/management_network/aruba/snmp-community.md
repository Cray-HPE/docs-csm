# SNMPv2c Community 

The switch supports SNMPv2c community-based security for read-only access. 

## Configuration Commands

Configure an SNMPv2c community name: 

```text
switch(config)# snmp-server community NAME
```

Bind the SNMP server to a VRF: 

```text
switch(config)# snmp-server vrf <default|VRF>
```

Show commands to validate functionality:  

```text
switch# show snmp community
```

## Example Output 

```text
switch(config)# snmp-server community public
switch(config)# snmp-server vrf default
switch(config)# end
switch# show snmp community
---------------------
SNMP communities
---------------------
mysnmp
switch# show snmp vrf
SNMP enabled VRF
----------------------------
default
```

## Expected Results 

1. Administrators can configure the community name
2. Administrators can bind the SNMP server to the default VRF
3. Administrators can connect from the workstation using the community name  


[Back to Index](../index.md)