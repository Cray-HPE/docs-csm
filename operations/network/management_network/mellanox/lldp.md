# Link layer discovery protocol (LLDP) 

LLDP is used to advertise the device’s identity and abilities and read other devices connected to the same network. Note: LLDP is enabled by default. 

Relevant Configuration 

Enable lldp  

```
switch(config)# lldp 
```

Enable lldp on interface

```
switch (config interface ethernet 1/1) # lldp receive
switch (config interface ethernet 1/1) # lldp transmit
```

Show Commands to Validate Functionality 

```
switch# show lldp local
```

Expected Results 

* Step 1: Link status between the peer devices is UP 
* Step 2: LLDP is enabled
* Step 3: Local device LLDP Information is displayed
* Step 4: Remote device LLDP information is displayed 
* Step 5: LLDP statistics are displayed 


[Back to Index](../index.md)