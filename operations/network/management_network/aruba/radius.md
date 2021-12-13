
# RADIUS 

“RADIUS is designed to authenticate and log dial-up remote users to a network.” – rfc2865 

## Configuration Commands 

Configure RADIUS server: 

```bash
switch(config)# radius-server host IP-ADDR [key <plain|cipher>text KEY] [timeout VALUE] [port
PORT] [auth-type TYPE] [acct-port PORT] [retries VALUE] [vrf VRF] [tracking <enable|disable>]
```

Configure AAA:

```bash
switch(config)# aaa authentication login default group radius local 
switch(config)# aaa accounting all default start-stop group radius 
```

Show commands to validate functionality:  

```bash
switch# show radius-server [detail]
switch# show aaa <server-groups|authentication>
```

## Expected Results 

1. SSH is enabled
2. You can configure the RADIUS server (reachable from the switch)  
3. The output of the `show` commands is correct
4. You can successfully access the switch using credentials validated by the RADIUS server 

[Back to Index](index_aruba.md)