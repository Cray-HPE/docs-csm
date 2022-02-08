# SNMPv2c community 

The switch supports SNMPv2c community-based security for Read-Only access. 

Relevant Configuration 

Configure an SNMPv2c community name 

```
switch(config)# snmp-server community NAME
```

Bind the SNMP server to a VRF 

```
switch(config)# snmp-server vrf <default|VRF>
```

Show Commands to Validate Functionality 

```
switch# show snmp community
```

Example Output 

```
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

Expected Results 

* Step 1: You can configure the community name
* Step 2: You can bind the SNMP server to the default VRF
* Step 3: You can connect from the workstation using the community name  


[Back to Index](../index.md)