# RADIUS 

"RADIUS is designed to authenticate and log dial-up remote users to a network." – rfc2865 

Relevant Configuration 

Configure RADIUS server 

```
switch(config)# radius-server host IP-ADDR [key <plain|cipher>text KEY] [timeout VALUE] [port
PORT] [auth-type TYPE] [acct-port PORT] [retries VALUE] [vrf VRF] [tracking <enable|disable>]
```

Configure AAA

```
switch(config)# aaa authentication login default group radius local 
switch(config)# aaa accounting all default start-stop group radius 
```

Show Commands to Validate Functionality 

```
switch# show radius-server [detail]
switch# show aaa <server-groups|authentication>
```

Expected Results 

* Step 0: SSH is enabled
* Step 1: You can configure the RADIUS server (reachable from the switch)  
* Step 2: The output of the show commands is correct
* Step 3: You can successfully access the switch using credentials validated by the RADIUS server 

[Back to Index](../index.md)