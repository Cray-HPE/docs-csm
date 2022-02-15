# Dell SNMPv3 Users 

SNMPv3 supports cryptographic security by a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-Only access is currently supported. The admin user can add or remove SNMPv3 users.

## Configuration Commands

Configure a new SNMPv3 user (minimum 8 characters for passwords):

```
switch(config)# snmp-server user <USER> cray-reds-group 3 auth md5 <A-PASS> priv des <P-PASS>
```

> **NOTE:** Removal an SNMPv3 user us not possible on Dell equipment.

Show commands to validate functionality: 

```
switch# show snmp user
```

## Example Output 

```
switch(config)# show snmp vrf
SNMP enabled VRF
----------------------------
default
switch(config)# show snmp user
User name                 : testuser
Group                     : cray-reds-group
Version                   : 3
Authentication Protocol   : MD5
Privacy Protocol          : DES
```

## Expected Results 

1. Administrators can configure the new user
2. Administrators can connect to the server from the workstation  


[Back to Index](index.md)

