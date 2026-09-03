# Loopback Interface

Loopbacks are essentially internal virtual interfaces.
Loopback interfaces are not bound to a physical port and are used for device management and routing protocols.

## Configuration commands

(`switch(config)#`)

```text
interface loopback LOOPBACK
ip address IP-ADDR/<SUBNET|PREFIX>
```

(`switch(config)#`)

```text
interface loopback 1
ip address 99.99.99.1/32
end
show run interface loopback1
```

Example output:

```text
interface loopback1
   no shutdown
   ip address 99.99.99.1/32
   exit
```

(`switch(config)#`)

```text
show ip interface loopback1
```

Example output:

```text
Interface loopback1 is up
 Admin state is up
 Hardware: Loopback
 IPv4 address 99.99.99.1/32
```

## Expected results

* Administrators can create a loopback interface.
* Administrators can give a loopback interface an IP address.
* Administrators can validate the configuration using the `show` commands.

[Back to Index](../README.md)
