# Loopback Interface

Loopbacks are essentially internal virtual interfaces.
Loopback interfaces are not bound to a physical port and are used for device management and routing protocols.

## Configuration commands

(`switch#`)

```text
interface loopback LOOPBACK
ip address IP-ADDR/<SUBNET|PREFIX>
```

## Expected results

* Create a loopback interface.
* Give a loopback interface an IP address.
* Validate the configuration using the `show` commands.

[Back to Index](../README.md)
