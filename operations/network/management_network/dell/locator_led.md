# Configure Locator LED

The Locator LED is an LED in the front of the chassis that can turn on or flash.
This is a useful feature when guiding someone to the switch during a "remote hands" situation,
such as asking an engineer to run a cable to the switch.

## Configuration commands

Enable LED:

```bash
switch# location-led system 1 on
```

Disable LED:

```bash
switch# location-led system 1 off
```

## Expected results

1. The Locator LED should be in the off state
2. The Locator LED is now flashing

[Back to Index](index.md)
