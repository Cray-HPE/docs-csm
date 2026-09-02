# IP Filter

There are two types of malicious traffic that can be received from external sources to the data center:

* Traffic that targets the switch's CPU, either inband or out of band (e.g. via `mgmt0`), targeted at one of the IP interfaces of the switch (loopback, router IP).
    * To protect or filter those traffic threats, use the `ip filter` set of commands.
* Traffic that targets the data center servers transferred via the switch.
    * To protect or filter this traffic, use the switch's ACL set of commands.

## Configuration commands

(`switch (config) #`) Enable IP filter globally.

```console
ip filter enable
```

Set the default input or output policy rule. The default is to accept all.
The default rule will be applied if no other rule will match.

(`switch (config) #`) For example, drop all traffic other than a specific set of flows, or accept all traffic except a specific set of flows:

```console
ip filter chain input policy drop
ip filter chain output policy accept
```

(`switch (config) #`) Set IP filtering rules for input or output traffic. For example, block (drop) UDP source port 100:

```console
ip filter chain input rule set 2 target drop protocol udp source-port 100
```

## Show commands to validate functionality

```console
show ip filter
```

[Back to Index](../README.md)
