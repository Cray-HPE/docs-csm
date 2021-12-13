# Aruba SNMPv3 Users 

SNMPv3 supports cryptographic security through a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-only access is currently supported. The admin user can add or remove SNMPv3 users. 

## Configuration Commands

Configure a new SNMPv3 user (minimum 8 characters for passwords): 

```bash
switch(config)# snmpv3 user <USER> auth md5 auth-pass <A-PSWD> priv aes priv-pass <P-PSWD>
```

Remove an SNMPv3 user:

```bash
switch(config)# no snmpv3 user <USER>
```

Show commands to validate functionality:  

```bash
switch# show snmpv3 users
```

## Example Output 

```bash
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

## Expected Results 

1. You can configure the new user
2. You can connect to the server from the workstation  


[Back to Index](index_aruba.md)
