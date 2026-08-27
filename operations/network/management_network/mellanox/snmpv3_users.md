# Mellanox `SNMPv3` Users

`SNMPv3` supports cryptographic security by a combination of authenticating and encrypting
the SNMP protocol packets over the network. Read-Only access is currently supported. The
administrator user can add or remove `SNMPv3` users.

## Relevant configuration

Configure a new `SNMPv3` user (Minimum 8 characters for passwords)

```console
switch(config)# snmp-server user testuser v3 capability admin
switch(config)# snmp-server user testuser v3 enable
switch(config)# snmp-server user testuser v3 enable sets
switch(config)# snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
switch(config)# snmp-server user testuser v3 require-privacy
```

## Show commands to validate functionality

```console
show snmp user
```

[Back to Index](../README.md)
