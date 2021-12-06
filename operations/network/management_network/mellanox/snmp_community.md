# SNMPv2c community 

The switch supports SNMPv2c community-based security for Read-Only access. 

Relevant Configuration 

Configure an SNMPv2c community name 

Enable SNMP 

```
switch(config)# snmp-server community private rw
```

Configure a SNMPv2c trap receiver host 

```
switch(config)# snmp-server host IP-ADDR <trap|inform> version v2c [community NAME]
```

Show commands to validate functionality:  

```
switch# show snmp 
```

Expected Results 

* Step 1: You can configure the community name
* Step 2: You can bind the SNMP server to the default VRF
* Step 3: You can connect from the workstation using the community name  

[Back to Index](./index.md)