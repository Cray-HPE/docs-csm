# Link Layer Discovery Protocol (LLDP)

LLDP is used to advertise the device's identity and abilities and read other devices connected to the same network.

> **NOTE** LLDP is enabled by default.

## Configuration commands

(`switch(config)#`) Enable LLDP.

```console
lldp
```

(`switch (config interface ethernet 1/1) #`) Enable LLDP on interface.

```console
lldp receive
lldp transmit
```

## Show commands to validate functionality

(`switch#`)

```console
show lldp local
```

[Back to Index](../README.md)
