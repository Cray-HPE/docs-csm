# Static routing 

“Static routing is manually performed by the network administrator. The administrator is responsible for discovering and propagating routes through the network. These definitions are manually programmed in every routing device in the environment. After a device has been configured, it simply forwards packets out the predetermined ports. There is no communication between routers regarding the current topology of the network.” –IBM Redbook, TCP/IP 

Relevant Configuration 

```
switch(config)# ip route vrf default 0.0.0.0/0 null0
```

Show Commands to Validate Functionality 

```
switch# show ip route
```

Expected Results 

* Step 1: You can configure a static route on the DUT
* Step 2: You can validate using the show command(s) above 
* Step 3: You can ping the connected device

[Back to Index](../index.md)