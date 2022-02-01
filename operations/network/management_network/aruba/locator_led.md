# Locator LED 

The Locator LED is an LED in the front of the chassis that you can turn on or make flash. This is a handy feature when guiding someone to your switch during a “remote hands” situation, such as asking data center engineer to run a cable to your switch. 

Relevant Configuration 

Enable led

```
switch# led locator <flashing|off|on>
```

Show Commands to Validate Functionality 

```
switch# show environment led
```

Example Output 

```
switch# show environment led
Name           State     Status
-----------------------------------
locator        off           ok
switch# led locator flashing
switch# show system led
Name           State     Status
-----------------------------------
locator        flashing      ok
switch# led locator on
switch# show system led
Name           State     Status
-----------------------------------
locator        on            ok
switch# led locator off
switch# show system led
Name           State     Status
-----------------------------------
locator        off           ok
```

Expected Results

* Step 1: The Locator LED should be in the off state
* Step 2: The Locator LED is now flashing
* Step 3: The show command shows the LED is in the flashing state 
* Step 4: The Locator LED is lit a solid color and it does not flash
* Step 5: The show command shows the LED is in the on state
* Step 6: The LED is no longer lit
* Step 7: The show command shows the LED is in the off state

[Back to Index](../index.md)