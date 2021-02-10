# Switch Metadata

This page provides directions on constructing the `switch_metadata.csv` file.

This file is manually created to include information about all spine, leaf, CDU, and aggregation switches in the system.
The file follows this format in ascending order for the switches of each type:

```
Switch Xname,Type,Brand
d0w1,CDU,Dell
d0w2,CDU,Dell
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h34s1,Spine,Mellanox
```

The above file would lead to this pairing between component name and hostname:

| hostname | component name |
| --------- | -------------- |
| sw-spine-001 | x3000c0h33s1 |
| sw-spine-002 | x3000c0h34s1 |
| sw-leaf-001 | x3000c0w38 |
| sw-leaf-002 | x3000c0w36 |
| sw-cdu-001 | d0w1 |
| sw-cdu-002 | d0w2 |

#### Requirements

For this you will need:

- The SHCD for your system

It is worthwhile to review the topic about component names from the HPE Cray EX Hardware Management Administration Guide 1.4 S-8015
while mapping names between the SHCD and your `switch_metadata.csv` file.

**`INTERNAL USE`**
[HSS Naming Convention](https://connect.us.cray.com/confluence/display/HSOS/Shasta+HSS+Component+Naming+Convention)

#### Format

Spine and aggregation switches use the format `xXcChHsS`. Leaf switches use `xXcCwW`.  CDU switches use `dDwW`.

#### Directions

1. In your SHCD, identify your switches. Look for:
    - The slot number(s) for the leaf switches (usually 48-port switches)
        - In the below example this is x3000u22
    - The slot number(s) for the spine switches
        - In the below example this is x3000u23R and x3000u23L (two side-by-side switches)
        - Newer side-by-side switches use slot numbers of s1 and s2 instead of R and L
    >   ![Layered Images Diagram](./img/shcd-rack-example.png)
2. Each spine or aggregation switch will follow this format: `xXcChHsS`
    - xX : where "X" is the river cabinet identification number (the figure above is "3000")
    - cC : where "C" is the cabinet identification number (the figure above is "0")
    - hH : where "H" is the slot number in the cabinet (height)
    - sS : where "S" is the horizontal space number'
    >
3. Each leaf switch will follow this format: `xXcCwW`:
    - xX : where "X" is the river cabinet identification number (the figure above is "3000")
    - cC : where "C" is the cabinet identification number (the figure above is "0")
    - wW : where "W" is the slot number in the cabinet (height)
4. Each CDU switch will follow this format: `dDwW`:
    - dD : where "D" is the Coolant Distribution Unit (CDU)
    - wW : where "W" is the management switch in a CDU
5. Each item in the file is either of type `Aggregation`, `CDU`, `Leaf`, or `Spine`.
6. Each line in the file must denote the Brand, either `Dell`, `Mellanox`, or `Aruba`.
7. Create the switch_metadata.csv file with this information.

linux# vi switch_metadata.csv

See the example files below for reference.

#### Examples

> An example with Dell leaf switches and 2 Mellanox switches in the same slot number:
```
pit:~ # cat example_switch_metadata.csv
Switch Xname,Type,Brand
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h33s2,Spine,Mellanox
```

> An example with Aruba switches:
```
pit:~ # cat example_switch_metadata.csv
Switch Xname,Type,Brand
x3000c0w14,Leaf,Aruba
x3000c0h12s1,Spine,Aruba
x3000c0h13s1,Spine,Aruba
```

> An example with Dell leaf and CDU switches and Mellanox spine switches:

```
Switch Xname,Type,Brand
d0w1,CDU,Dell
d0w2,CDU,Dell
x3000c0w36,Leaf,Dell
x3000c0w38,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h34s1,Spine,Mellanox
```
