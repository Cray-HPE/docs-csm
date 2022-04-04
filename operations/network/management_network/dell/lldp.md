# Link layer discovery protocol (LLDP)

By default, LLDP is enabled for each interface and globally. You can disable LLDP on an interface or globally. If you disable LLDP globally,
LLDP is disabled on all interfaces irrespective of whether LLDP is previously enabled or disabled on an interface. When you enable LLDP
globally, the LLDP configuration at the interface level takes precedence over the global LLDP configuration.


Relevant configuration

Disable the LLDPDU transmit or receive in INTERFACE mode.

```
no lldp transmit
no lldp receive
```

Disable the LLDP holdtime multiplier value in CONFIGURATION mode.

```
no lldp holdtime-multiplier
```

Disable the LLDP initialization in CONFIGURATION mode.

```
no lldp reinit
```

Disable the LLDP MED in CONFIGURATION or INTERFACE mode.

```
no lldp med
```

Disable LLDP TLV in INTERFACE mode.

```
no lldp tlv-select
```

Disable LLDP globally in CONFIGURATION mode.

```
no lldp enable
```

Expected Results

* Step 1: Link status between the peer devices is UP
* Step 2: LLDP is enabled
* Step 3: Local device LLDP Information is displayed
* Step 4: Remote device LLDP information is displayed
* Step 5: LLDP statistics are displayed

[Back to Index](../index.md)

