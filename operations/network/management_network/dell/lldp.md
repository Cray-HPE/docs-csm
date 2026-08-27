# Link Layer Discovery Protocol (LLDP)

By default, LLDP is enabled for each interface and globally.
Administrators can disable LLDP on an interface or globally.
If LLDP is disabled globally, LLDP is disabled on all interfaces irrespective of whether LLDP is previously enabled or disabled on an interface.
When administrators enable LLDP globally, the LLDP configuration at the interface level takes precedence over the global LLDP configuration.

## Configuration commands

Disable the LLDPDU transmit or receive in interface mode:

```text
no lldp transmit
no lldp receive
```

Disable the LLDP `holdtime-multiplier` value in configuration mode:

```text
no lldp holdtime-multiplier
```

Disable the LLDP initialization in configuration mode:

```text
no lldp reinit
```

Disable the LLDP MED in configuration or interface mode:

```text
no lldp med
```

Disable LLDP TLV in interface mode:

```text
no lldp tlv-select
```

Disable LLDP globally in configuration mode:

```text
no lldp enable
```

## Expected results

1. Link status between the peer devices is UP
1. LLDP is enabled
1. Local device LLDP Information is displayed
1. Remote device LLDP information is displayed
1. LLDP statistics are displayed

[Back to Index](../README.md)
