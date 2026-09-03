# Multi-Chassis Link Aggregation Group (MCLAG)

Multi-Chassis Link Aggregation Group (MCLAG) is a link aggregation technique where two or more links across
two switches are aggregated together to form a trunk.

## Configuration commands

(`switch(config)#`) Create the MCLAG interface:

```text
interface lag LAG multi-chassis
no shutdown
```

(`switch(config)#`) Associate member links with the MCLAG interface:

```text
interface IFACE
no shutdown
lag LAG
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show mclag <brief|configuration|status>
```

(`switch(config)#`)

```text
interface lag 23 multi-chassis
no shutdown
exit
interface 1/1/10
no shutdown
lag 23
end
```

## Expected results

* Administrators can configure MCLAG.
* Administrators can create an MCLAG interface.
* Administrators can add ports to the MCLAG interface.
* The output of the `show` commands is correct.

[Back to Index](../README.md)
