# SNMP Traps

The SNMP agent can send trap notifications to a receiver. The receiver's host IP address
and port number can be defined along with the notification type, version, and community string.

## Configuration commands

Configure a SNMPv2c trap receiver host:

```console
switch(config)# snmp-server host IP-ADDR trap version v2c community xxx
```

Show commands to validate functionality:

```console
show snmp trap
```

## Example output

```console
show snmp trap
```

```text
------------------------------------------------------------------------------------------
Host                     Port  Type      Version SecName                         vrf
------------------------------------------------------------------------------------------
1.2.3.4                  162   trap      v1      public
1.2.3.4                  162   trap      v2c     public
1.2.3.4                  162   inform    v2c     public
default
default
default
```

## Expected results

* Administrators can configure a trap host for their SNMP Manager
* Administrators can log trap events
* Administrators can successfully trigger a trap event

[Back to Index](../README.md)
