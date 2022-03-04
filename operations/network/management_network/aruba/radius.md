# RADIUS 

RADIUS servers provide a method for remote users to access the switch. The following commands show how to configure a RADIUS server, and how remote users can authenticate and access the switch.

## Configuration Commands 

Configure RADIUS server: 

```text
switch(config)# radius-server host IP-ADDR [key <plain|cipher>text KEY] [timeout VALUE] [port
PORT] [auth-type TYPE] [acct-port PORT] [retries VALUE] [vrf VRF] [tracking <enable|disable>]
```

Configure AAA:

```text
switch(config)# aaa authentication login default group radius local 
switch(config)# aaa accounting all default start-stop group radius 
```

Show commands to validate functionality:  

```text
switch# show radius-server [detail]
switch# show aaa <server-groups|authentication>
```

## Expected Results 

1. SSH is enabled
2. Administrators can configure the RADIUS server (reachable from the switch)  
3. The output of the `show` commands is correct
4. Administrators can successfully access the switch using credentials validated by the RADIUS server 
   
[Back to Index](../index.md)