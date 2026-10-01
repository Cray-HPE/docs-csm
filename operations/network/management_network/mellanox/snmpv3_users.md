# Mellanox `SNMPv3` Users

`SNMPv3` supports cryptographic security through a combination of authenticating
and encrypting the SNMP protocol packets over the network. Read-only access is
currently supported. The administrator user can add or remove `SNMPv3` users.

## Configuration commands

(`switch(config)#`) Configure a new `SNMPv3` user (minimum eight characters for passwords):

```console
snmp-server user testuser v3 capability admin
snmp-server user testuser v3 enable
snmp-server user testuser v3 enable sets
snmp-server user testuser v3 encrypted auth md5 xxxxxxx priv des xxxxxxx
snmp-server user testuser v3 require-privacy
```

## Show commands to validate functionality

(`switch(config)#`)

```console
show snmp user
```

[Back to Index](../README.md)
