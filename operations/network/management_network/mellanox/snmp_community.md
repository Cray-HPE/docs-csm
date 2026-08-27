# `SNMPv2c` Community

The switch supports `SNMPv2c` community-based security for read-only access.

## Relevant configuration

Configure an `SNMPv2c` community name.

(`switch(config)#`) Enable SNMP:

```console
snmp-server community private rw
```

(`switch(config)#`) Configure an `SNMPv2c` trap receiver host:

```console
snmp-server host IP-ADDR <trap|inform> version v2c [community NAME]
```

## Show commands to validate functionality

(`switch#`)

```console
show snmp
```

## Expected results

* Administrators can configure the community name
* Administrators can bind the SNMP server to the default VRF
* Administrators can connect from the workstation using the community name

[Back to Index](../README.md)
