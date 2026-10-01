# Cable Diagnostics

Use the cable diagnostic feature to test cables in the event where there might be a bad copper cable.

> **NOTE** This feature is only available on non-SFP copper ports.

## Procedure

(`switch#`) Enter `diagnostics` to open the diagnostics menu:

```console
diagnostics
```

(`switch#`) The diagnostics command set is now available for use, and the cable-diagnostics command can be executed:

```console
diag cable-diagnostic <IFACE>
```

(`switch#`)

```console
diagnostics <CR>
```

Example output (truncated for brevity):

```text
diag ?
  asic                        ASIC diagnostics
  audit-failure-notification  Configure audit failure notification
  bgp                         IP information
  cable-diagnostic            Cable diagnostic test
```

(`switch#`)

```text
diag cable-diagnostic ?
```

Example output:

```text
IFNAME
```

## Expected results

* Administrators can enter diagnostics mode successfully.
* Administrators can test the cable and see the results in the CLI output.

[Back to Index](README.md)
