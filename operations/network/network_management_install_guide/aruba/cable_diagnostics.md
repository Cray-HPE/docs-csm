# Cable diagnostics 

In a situation where you believe you might have a bad copper cable, you can use the cable-diagnostic feature to test the cable. Note: This feature is only available on non-SFP copper ports. 

Relevant Configuration 

Enter “diagnostics” to open up the diagnostics menu 

```
switch# diagnostics
```

Once done, the diagnostics command set is now available for use, and the cable-diagnostics command can be executed 

```
switch# diag cable-diagnostic <IFACE>
```

Example Output 

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

Expected Results 

* Step 1: You can enter diagnostics mode successfully
* Step 2: You can test the cable and see the results in the CLI output 

[Back to Index](./index.md)