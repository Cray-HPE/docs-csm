# Aruba SNMPv3 Users

`SNMPv3` supports cryptographic security through a combination of authenticating
and encrypting the SNMP protocol packets over the network. Read-only access is
currently supported. The administrator user can add or remove `SNMPv3` users.

## Configuration commands

(`switch(config)#`) Configure a new `SNMPv3` user (minimum eight characters for passwords):

```text
snmpv3 user <USER> auth md5 auth-pass <A-PSWD> priv aes priv-pass <P-PSWD>
```

(`switch(config)#`) Remove an `SNMPv3` user:

```text
no snmpv3 user <USER>
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show snmpv3 users
```

(`switch(config)#`)

```text
snmp-server community public
snmpv3 context public vrf default community public
show snmpv3 context
```

Example output:

```text
--------------------------------------------------------------------------
Name                            vrf                             Community
--------------------------------------------------------------------------
public                          mgmt.                           public
```

(`switch(config)#`)

```text
show snmp vrf
```

Example output:

```text
SNMP enabled VRF
----------------------------
default
```

(`switch(config)#`)

```text
show snmpv3 users
```

Example output:

```text
--------------------------------------------------------------------------
User                            AuthMode  PrivMode  Context        Enabled
--------------------------------------------------------------------------
Snmpv3user                        md5       aes       none           True
```

## Expected results

* Administrators can configure the new user.
* Administrators can connect to the server from the workstation.

[Back to Index](../README.md)
