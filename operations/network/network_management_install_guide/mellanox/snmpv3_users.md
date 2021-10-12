# SNMPv3 users 

SNMPv3 supports cryptographic security by a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-Only access is currently supported. The admin user can add or remove SNMPv3 users. 

Relevant Configuration 

Configure a new SNMPv3 user (Minimum 8 characters for passwords) 

```
switch(config)# snmp-server user admin v3 enable
```

Show Commands to Validate Functionality 

```
switch# show snmp users
```

[Back to Index](./index.md)