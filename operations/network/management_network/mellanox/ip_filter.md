# Ip filter

There are two types of malicious traffic that can be received from external sources to the data center:

1. Traffic that target the switch's CPU, either inband or out of band (e.g. via mgmt0) targeted one of the IP interfaces of the switch (loopback, router IP). To protect or filter those traffic threats use the ip filter set of commands.
2. Traffic that target the data center servers transferred via the switch. To protect or filter this traffic use the switch's ACL set of commands.

Relevant Configuration 

Enable IP filter globally.

```
switch (config) # ip filter enable 
```

Set the default input or output policy rule. The default is to accept all. The default rule will be applied if no other rule will match.

For example, drop all traffic other than a specific set of flows, or accept all traffic except a specific set of flows.

```
switch (config) # ip filter chain input policy drop
switch (config) # ip filter chain output policy accept
```

Set IP filtering rules for input or output traffic. For example, block (drop) UDP source port 100.

```
switch (config) # ip filter chain input rule set 2 target drop protocol udp source-port 100
```

Show Commands to Validate Functionality 

```
switch (config) # show ip filter
```

[Back to Index](../index.md)
