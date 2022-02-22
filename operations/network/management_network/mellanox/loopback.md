# Loopback interface 

You can think of loopbacks as internal virtual interfaces. Loopback interfaces are not bound to a physical port and are used for device management and routing protocols. 

Relevant Configuration 

Create a loopback interface. Run:

```
switch (config)# interface loopback 2
switch (config interface loopback 2)#
```

Configure an IP address on the loopback interface. Run:

```
switch (config interface loopback 2)# ip address 20.20.20.20 /32
```

Show Commands to Validate Functionality 

```
switch# show interfaces loopback 2
```

Expected Results 

* Step 1: You can create a loopback interface
* Step 2: You can give a loopback interface an IP address
* Step 3: You can validate the configuration using the show commands.

[Back to Index](../index.md)

