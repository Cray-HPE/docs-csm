# Loopback interface

You can think of loopbacks as internal virtual interfaces. Loopback interfaces are not bound to a physical port and are used for device management and routing protocols.

Relevant Configuration

```
switch(config)# interface loopback LOOPBACK
switch(config-loopback-if)# ip address IP-ADDR/<SUBNET|PREFIX>
```

Expected Results

* Step 1: You can create a loopback interface
* Step 2: You can give a loopback interface an IP address
* Step 3: You can validate the configuration using the show commands.

[Back to Index](index.md)
