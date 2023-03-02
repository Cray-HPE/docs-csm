# Mellanox SNMPv3 users

SNMPv3 supports cryptographic security by a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-Only access is currently supported. The admin user can add or remove SNMPv3 users.

## Relevant Configuration

Configure a new SNMPv3 user (Minimum 8 characters for passwords)

```console
switch(config)# snmp-server user testuser v3 capability admin
switch(config)# snmp-server user testuser v3 enable
switch(config)# snmp-server user testuser v3 enable sets
switch(config)# snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
switch(config)# snmp-server user testuser v3 require-privacy
```

Show Commands to Validate Functionality

```console
show snmp users
```

[Back to Index](../README.md)
