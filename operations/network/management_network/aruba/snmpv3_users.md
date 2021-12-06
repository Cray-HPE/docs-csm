# Aruba SNMPv3 users 

SNMPv3 supports cryptographic security by a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-Only access is currently supported. The admin user can add or remove SNMPv3 users. 

Relevant Configuration 

Configure a new SNMPv3 user (Minimum 8 characters for passwords) 

```
switch(config)# snmpv3 user <USER> auth md5 auth-pass <A-PSWD> priv aes priv-pass <P-PSWD>
```

Remove an SNMPv3 user

```
switch(config)# no snmpv3 user <USER>
```

Show commands to validate functionality:  

```
switch# show snmpv3 users
```

Example Output 

```
switch(config)# snmp-server community public
switch(config)# snmpv3 context public vrf default community public
switch(config)# show snmpv3 context
--------------------------------------------------------------------------
Name                            vrf                             Community
--------------------------------------------------------------------------
public                          mgmt.                           public

switch(config)# show snmp vrf
SNMP enabled VRF
----------------------------
default
switch(config)# show snmpv3 users
--------------------------------------------------------------------------
User                            AuthMode  PrivMode  Context        Enabled
--------------------------------------------------------------------------
Snmpv3user                        md5       aes       none           True
```

Expected Results 

* Step 1: You can configure the new user
* Step 2: You can connect to the server from the workstation  


[Back to Index](./index.md)
