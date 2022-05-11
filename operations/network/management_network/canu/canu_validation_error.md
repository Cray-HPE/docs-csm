# Troubleshoot CANU Validation Errors

Typical CANU validation errors and how to fix them.

## Example 1

```text
validate_shcd - CRITICAL: A port number must be specified. Please correct the SHCD for HMN:V36 with an empty value
```

**SOLUTION:** Blank cell. Minimally the Source or Destination and Port needs to be specified.

## Example 2

```text
Tab PDU not found in ./HPE System Hela CCD.revA27.xlsx

Available tabs: ['Config. Summary', 'HPE Cables', 'RiverRackLayout ', 'Arista', 'River Device Diagrams', 'HPE Devices', 'SCT pt_pt', 'yaml', 'Mountain-TDS-Management', 'MTN Rack Layout', '10G_25G_40G_100G', 'NMN', 'HMN', 'PDU ']
```

**SOLUTION:** `PDU` has an extra space in the tab name.

## Example 3

```text
validate_shcd - ERROR:  On tab PDU, header column Slot not found.
```

**SOLUTION:** Make sure the header descriptions include the name `Slot`.

## Example 4

```text
validate_shcd - CRITICAL:

On tab PDU, the header is formatted incorrectly.

Columns must exist in the following order, but may have other columns in between:

[0, 1, 2, 'Slot', 'Port', 'Destination', 'Rack', 'Location', 'Port']
```

**SOLUTION:** Fix the header naming to match the expected output.

## Example 5

```text
network_modeling.NetworkNode: No available ports found for slot bmc and speed 25 in node sw-leaf-002
validate_shcd - CRITICAL: None
Failed to connect sw-leaf-002 to sw-leaf-bmc-002 bi-directionally while working on sheet HMN, row 25.
validate_shcd - CRITICAL: None
```

**SOLUTION:** Remove the connections going from `sw-leaf-002` to `sw-leaf-bmc-002`, because at this time CSM does not utilize these ports.
