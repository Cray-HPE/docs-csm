# Cable Diagnostics

Use the cable-diagnostic feature to test cables in the event where there might be a bad copper cable.

> **`NOTE`** This feature is only available on non-SFP copper ports.

## Procedure

Enter `diagnostics` to open up the diagnostics menu:

```
diagnostics
```

Once done, the diagnostics command set is now available for use, and the cable-diagnostics command can be executed:

```
diag cable-diagnostic <IFACE>
```

## Example output

```
diagnostics <CR>
diag ?
  asic                        ASIC diagnostics
  audit-failure-notification  Configure audit failure notification
  bgp                         IP information
  cable-diagnostic            Cable diagnostic test
...snip for brevity
diag cable-diagnostic ?
IFNAME
```

## Expected Results

1. Administrators can enter diagnostics mode successfully
1. Administrators can test the cable and see the results in the CLI output

[Back to Index](README.md)
