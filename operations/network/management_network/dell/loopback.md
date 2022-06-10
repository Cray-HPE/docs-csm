# Configure Loopback Interface

Loopbacks can be thought of as internal virtual interfaces. Loopback interfaces are not bound to a physical port
and are used for device management and routing protocols.

## Configuration Commands

```text
interface loopback LOOPBACK
ip address IP-ADDR/<SUBNET|PREFIX>
```

## Expected Results

1. Create a loopback interface.
1. Give a loopback interface an IP address.
1. Validate the configuration using the `show` commands.

[Back to Index](../README.md)
