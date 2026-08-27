# Multi-Chassis Link Aggregation Group (MCLAG)

Multi-Chassis Link Aggregation Group (MCLAG) is a link aggregation technique where two or more links across two switches are aggregated together to form a trunk.

## Configuration commands

Create the MCLAG interface:

```text
switch(config)# interface lag LAG multi-chassis
switch(config-lag-if)# no shutdown
```

Associate member links with the MCLAG interface:

```text
switch(config)# interface IFACE
switch(config-if)# no shutdown switch(config-if)# lag LAG
```

Show commands to validate functionality:

```text
show mclag <brief|configuration|status>
```

## Example output

```text
switch(config)# interface lag 23 multi-chassis
switch(config-lag-if)# no shutdown
switch(config-lag-if)# exit
switch(config)# interface 1/1/10
switch(config-if)# no shutdown
switch(config-if)# lag 23
switch(config-if)# end
```

## Expected results

1. Administrators can configure MCLAG
1. Administrators can create an MCLAG interface
1. Administrators can add ports to the MCLAG interface
1. The output of the `show` commands is correct

[Back to Index](../README.md)
