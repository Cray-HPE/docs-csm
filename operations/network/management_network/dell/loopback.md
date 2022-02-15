# Configure Loopback Interface

Loopbacks are essentially internal virtual interfaces. Loopback interfaces are not bound to a physical port and are used for device management and routing protocols.

## Configuration Commands

```
switch(config)# interface loopback LOOPBACK
switch(config-loopback-if)# ip address IP-ADDR/<SUBNET|PREFIX>
```

## Expected Results

1. Administrators can create a loopback interface
2. Administrators can give a loopback interface an IP address
3. Administrators can validate the configuration using the `show` commands

[Back to Index](index.md)
