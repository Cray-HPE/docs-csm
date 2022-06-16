# Aruba SNMPv3 Users

SNMPv3 supports cryptographic security through a combination of authenticating and encrypting the SNMP protocol packets over the network. Read-only access is currently supported. The admin user can add or remove SNMPv3 users.

## Configuration Commands

Configure a new SNMPv3 user (minimum eight characters for passwords):

```text
switch(config)# snmpv3 user <USER> auth md5 auth-pass <A-PSWD> priv aes priv-pass <P-PSWD>
```

Remove an SNMPv3 user:

```text
switch(config)# no snmpv3 user <USER>
```

Show commands to validate functionality:

```text
switch# show snmpv3 users
```

## Example Output

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

## Expected Results

1. Administrators can configure the new user
2. Administrators can connect to the server from the workstation

[Back to Index](../index.md)
