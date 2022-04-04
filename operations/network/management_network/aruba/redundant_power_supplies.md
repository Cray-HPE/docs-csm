# Redundant Power Supplies

There are no configuration commands for switch power supply functionality.

> **NOTE:** HA will be covered in HA section.

Show commands to validate functionality:

```bash
switch# show environment power-supply
```

## Expected Results

1. Validate the switch recognizes the additional power supplies
2. Validate system remains powered after removing power from all but one power supply
3. Validate all power supplies are operational

## Example Output

```bash
switch# show environment power-supply
         Product  Serial           PSU
Wattage
Mbr/PSU  Number   Number           Status
---------------------------------------------------------
1/1      JL372A   M031SS004TAPC    OK            2701
1/2      JL372A   M031SS004UAPC    OK            2430
1/3       N/A      N/A              Absent        0
1/4       N/A      N/A              Absent        0
```

[Back to Index](../index.md)
