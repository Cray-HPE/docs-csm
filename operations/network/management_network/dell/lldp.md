# Link layer discovery protocol (LLDP)

By default, LLDP is enabled for each interface and globally.
Administrators can disable LLDP on an interface or globally.
If LLDP is disabled globally, LLDP is disabled on all interfaces irrespective of whether LLDP is previously enabled or disabled on an interface.
When administrators enable LLDP globally, the LLDP configuration at the interface level takes precedence over the global LLDP configuration.

## Configuration Commands

Disable the LLDPDU transmit or receive in INTERFACE mode:

```text
no lldp transmit
no lldp receive
```

Disable the LLDP `holdtime-multiplier` value in CONFIGURATION mode:

```text
no lldp holdtime-multiplier
```

Disable the LLDP initialization in CONFIGURATION mode:

```text
no lldp reinit
```

Disable the LLDP MED in CONFIGURATION or INTERFACE mode:

```text
no lldp med
```

Disable LLDP TLV in INTERFACE mode:

```text
no lldp tlv-select
```

Disable LLDP globally in CONFIGURATION mode:

```text
no lldp enable
```

## Expected Results

1. Link status between the peer devices is UP
2. LLDP is enabled
3. Local device LLDP Information is displayed
4. Remote device LLDP information is displayed
5. LLDP statistics are displayed

[Back to Index](../README.md)
