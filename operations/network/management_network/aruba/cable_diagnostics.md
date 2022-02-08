# Cable Diagnostics 

Use the cable-diagnostic feature to test cables in the event where there might be a bad copper cable.

> **NOTE:** This feature is only available on non-SFP copper ports. 

## Procedure 

Enter `diagnostics` to open up the diagnostics menu: 

```
switch# diagnostics
```

Once done, the diagnostics command set is now available for use, and the cable-diagnostics command can be executed: 

```
switch# diag cable-diagnostic <IFACE>
```

## Example output

```
6300# diagnostics <CR>
6300# diag ?
  asic                        ASIC diagnostics
  audit-failure-notification  Configure audit failure notification
  bgp                         IP information
  cable-diagnostic            Cable diagnostic test
...snip for brevity
6300# diag cable-diagnostic ?
IFNAME  
```

## Expected Results 

1. You can enter diagnostics mode successfully
1. You can test the cable and see the results in the CLI output 

[Back to Index](index_aruba.md)