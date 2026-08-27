# Locator LED

The Locator LED is an LED in the front of the chassis that can be turned on or made to flash.
This is a handy feature when guiding someone to the switch during a "remote hands" situation,
such as asking an engineer to run a cable to the switch.

## Configuration commands

Enable LED:

```text
led locator <flashing|off|on>
```

Show commands to validate functionality:

```text
show environment led
```

## Example output

```text
show environment led
Name           State     Status
-----------------------------------
locator        off           ok
led locator flashing
show system led
Name           State     Status
-----------------------------------
locator        flashing      ok
led locator on
show system led
Name           State     Status
-----------------------------------
locator        on            ok
led locator off
show system led
Name           State     Status
-----------------------------------
locator        off           ok
```

## Expected results

1. The Locator LED should be in the off state
1. The Locator LED is now flashing
1. The `show` command shows the LED is in the flashing state
1. The Locator LED is lit a solid color and it does not flash
1. The `show` command shows the LED is in the on state
1. The LED is no longer lit
1. The `show` command shows the LED is in the off state

[Back to Index](../README.md)
