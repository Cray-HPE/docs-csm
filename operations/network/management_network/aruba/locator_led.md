# Locator LED

The Locator LED is an LED in the front of the chassis that can turn on or flash.
This is a useful feature when guiding someone to the switch during a "remote hands" situation,
such as asking an engineer to run a cable to the switch.

## Configuration commands

(`switch#`) Enable LED:

```text
led locator <flashing|off|on>
```

## Show commands to validate functionality

(`switch#`)

```text
show environment led
```

(`switch#`)

```text
show environment led
```

Example output:

```text
Name           State     Status
-----------------------------------
locator        off           ok
```

(`switch#`)

```text
led locator flashing
show system led
```

Example output:

```text
Name           State     Status
-----------------------------------
locator        flashing      ok
```

(`switch#`)

```text
led locator on
show system led
```

Example output:

```text
Name           State     Status
-----------------------------------
locator        on            ok
```

(`switch#`)

```text
led locator off
show system led
```

Example output:

```text
Name           State     Status
-----------------------------------
locator        off           ok
```

[Back to Index](../README.md)
