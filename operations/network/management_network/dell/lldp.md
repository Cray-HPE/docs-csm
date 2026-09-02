# Link Layer Discovery Protocol (LLDP)

LLDP is used to advertise the device's identity and abilities and read other devices connected to the same network.
By default, LLDP is enabled for each interface and globally.
Administrators can disable LLDP on an interface or globally.
If LLDP is disabled globally, LLDP is disabled on all interfaces irrespective of whether LLDP is previously enabled or disabled on an interface.
When administrators enable LLDP globally, the LLDP configuration at the interface level takes precedence over the global LLDP configuration.

## Configuration commands

(`switch#`) Disable the LLDPDU transmit or receive in interface mode:

```text
no lldp transmit
no lldp receive
```

(`switch#`) Disable the LLDP `holdtime-multiplier` value in configuration mode:

```text
no lldp holdtime-multiplier
```

(`switch#`) Disable the LLDP initialization in configuration mode:

```text
no lldp reinit
```

(`switch#`) Disable the LLDP MED in configuration or interface mode:

```text
no lldp med
```

(`switch#`) Disable LLDP TLV in interface mode:

```text
no lldp tlv-select
```

(`switch#`) Disable LLDP globally in configuration mode:

```text
no lldp enable
```

[Back to Index](../README.md)
