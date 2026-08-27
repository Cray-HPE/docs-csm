# Static Routing

"Static routing is manually performed by the network administrator. The administrator is responsible for discovering and propagating routes through the network.
These definitions are manually programmed in every routing device in the environment. After a device has been configured, it simply forwards packets out the
predetermined ports. There is no communication between routers regarding the current topology of the network." –IBM Redbook, TCP/IP

## Relevant configuration

(`switch(config)#`)

```console
ip route vrf default 0.0.0.0/0 null0
```

## Show commands to validate functionality

(`switch#`)

```console
show ip route
```

## Expected results

* Administrators can configure a static route on the DUT
* Administrators can validate using the show command above
* Administrators can ping the connected device

[Back to Index](../README.md)
