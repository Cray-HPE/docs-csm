# Link Layer Discovery Protocol (LLDP)

LLDP is used to advertise the device's identity and abilities and read other devices connected to the same network.

> Note: LLDP is enabled by default.

## Relevant configuration

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

```console
show lldp local
```

## Expected results

* Link status between the peer devices is `UP`
* LLDP is enabled
* Local device LLDP Information is displayed
* Remote device LLDP information is displayed
* LLDP statistics are displayed

[Back to Index](../README.md)
