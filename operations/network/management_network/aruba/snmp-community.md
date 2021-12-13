# SNMPv2c Community 

The switch supports SNMPv2c community-based security for read-only access. 

## Configuration Commands

Configure an SNMPv2c community name: 

```bash
switch(config)# snmp-server community NAME
```

Bind the SNMP server to a VRF: 

```bash
switch(config)# snmp-server vrf <default|VRF>
```

Show commands to validate functionality:  

```bash
switch# show snmp community
```

## Example Output 

```bash
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

1. You can configure the community name
2. You can bind the SNMP server to the default VRF
3. You can connect from the workstation using the community name  


[Back to Index](index_aruba.md)