# SNMP traps 

The SNMP agent can send trap notifications to a receiver. The receiver’s host IP address and port number can be defined along with the notification type, version, and community string. 

Relevant Configuration 

Configure a SNMPv2c trap receiver host 

```
switch(config)# snmp-server host IP-ADDR trap version v2c community xxx
```

Show commands to validate functionality:  

```
switch# show snmp trap
```

Example Output 

```
switch# show snmp trap
------------------------------------------------------------------------------------------
Host                     Port  Type      Version SecName                         vrf
------------------------------------------------------------------------------------------
1.2.3.4                  162   trap      v1      public
1.2.3.4                  162   trap      v2c     public
1.2.3.4                  162   inform    v2c     public
default
default
default
```

Expected Results 

* Step 1: You can configure a trap host for your SNMP Manager
* Step 2: You can log trap events
* Step 3: You can successfully trigger a trap event

[Back to Index](./index.md)
