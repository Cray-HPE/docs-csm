# `SNMPv2c` Community

The switch supports `SNMPv2c` community-based security for read-only access.

## Configuration commands

(`switch(config)#`) Configure an `SNMPv2c` community name:

```text
snmp-server community NAME
```

(`switch(config)#`) Bind the SNMP server to a VRF:

```text
snmp-server vrf <default|VRF>
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show snmp community
```

(`switch(config)#`)

```text
snmp-server community public
snmp-server vrf default
end
show snmp community
```

Example output:

```text
---------------------
SNMP communities
---------------------
mysnmp
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

## Expected results

* Administrators can configure the community name.
* Administrators can bind the SNMP server to the default VRF.
* Administrators can connect from the workstation using the community name.

[Back to Index](../README.md)
