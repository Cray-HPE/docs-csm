# Redundant Power Supplies

There are no configuration commands for switch power supply functionality.

Show commands to validate functionality:

```bash
show environment power-supply
```

## Expected results

1. Validate the switch recognizes the additional power supplies
1. Validate system remains powered after removing power from all but one power supply
1. Validate all power supplies are operational

## Example output

```console
show environment power-supply
```

```text
         Product  Serial           PSU
Wattage
Mbr/PSU  Number   Number           Status
---------------------------------------------------------
1/1      JL372A   M031SS004TAPC    OK            2701
1/2      JL372A   M031SS004UAPC    OK            2430
1/3       N/A      N/A              Absent        0
1/4       N/A      N/A              Absent        0
```

[Back to Index](../README.md)
