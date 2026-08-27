# Aruba SNMPv3 Users

`SNMPv3` supports cryptographic security through a combination of authenticating
and encrypting the SNMP protocol packets over the network. Read-only access is
currently supported. The administrator user can add or remove `SNMPv3` users.

## Configuration commands

Configure a new `SNMPv3` user (minimum eight characters for passwords):

```text
switch(config)# snmpv3 user <USER> auth md5 auth-pass <A-PSWD> priv aes priv-pass <P-PSWD>
```

Remove an `SNMPv3` user:

```text
switch(config)# no snmpv3 user <USER>
```

Show commands to validate functionality:

```text
show snmpv3 users
```

## Example output

```text
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

## Expected results

1. Administrators can configure the new user
1. Administrators can connect to the server from the workstation

[Back to Index](../README.md)
