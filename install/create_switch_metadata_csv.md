# Create Switch Metadata CSV

This page provides directions on constructing the `switch_metadata.csv` file.

This file is manually created to include information about all spine, leaf, CDU, and aggregation switches in the system.
None of the Slingshot switches for the HSN should be included in this file.

The file should have the following format, in ascending order by component name (xname):

```
Switch Xname,Type,Brand
d0w1,CDU,Dell
d0w2,CDU,Dell
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h34s1,Spine,Mellanox
```

The above file would lead to the following pairing between component name and hostname:

| Hostname | Component Name |
| --------- | -------------- |
| sw-spine-001 | x3000c0h33s1 |
| sw-spine-002 | x3000c0h34s1 |
| sw-leaf-001 | x3000c0w38 |
| sw-leaf-002 | x3000c0w36 |
| sw-cdu-001 | d0w1 |
| sw-cdu-002 | d0w2 |

The hostnames are automatically generated in ascending order by switch type.

The brand name of the management switches can be determined from one of two places. The Device Diagrams or River Device Diagrams tab of the SHCD has pictures and diagrams of the components of the system, including the management network switches. This will have a long name which shows the part number and the vendor name. The Rack Layout or River Rack Layout tab shows the part number in the context of its location within the cabinet.

| Part Number | Brand |
| ----------- | ----- |
| Aruba 8320 48P 1G/10GBASE-T and 6P 40G QSFP with X472 (JL481A) | Aruba |
| Aruba 8325-23C 32-port 100G QSFP+/QSFP28 (JL627A) | Aruba |
| CS-XGE40-MLNX-2100-16 | Mellanox |
| HPE Aruba 6300M - switch - 48 ports - managed - rack-mountable | Aruba |
| JL625A - Aruba 8325-48Y8C BF 6 F 2 PS Bdl | Aruba |
| XC-XGE-48P-DL2 Ethernet switch (Dell S3048-ON) | Dell |
| XC-XGT-48P-DL2 Ethernet switch (Dell S4048-ON) | Dell |

There may be other switches in a specific SHCD, but the general guidelines for any abbreviations are that MLNX or MLX is for Mellanox and DL is for Dell. All other switches are HPE Aruba switches.

#### Requirements

- The SHCD for the system
  
  Check the description for component names while mapping names between the SHCD and your `switch_metadata.csv` file.

  See [Component Names (xnames)](../operations/Component_Names_xnames.md).

#### Format

Spine and aggregation switches use the format `xXcChHsS`. Leaf switches use `xXcCwW`. CDU switches use `dDwW`.

#### Reference Diagram for Subsequent Sections

![Reference diagram of a cabinet with side-by-side switches in SHCD](../img/shcd-rack-example.png)
   
> Diagram of a cabinet with side-by-side switches in SHCD.

#### Directions

1. Identify the switches in the SHCD.
   
   Look for the following:
    - The slot number(s) for the leaf switches (usually 48-port switches)
        - In the above diagram this is x3000u22
    
    - The slot number(s) for the spine switches
        - In the above diagram this is x3000u23R and x3000u23L (two side-by-side switches)
        - Newer side-by-side switches use slot numbers of s1 and s2 instead of R and L
  
2. Each spine or aggregation switch will follow this format: `xXcChHsS`
   
    > This format also applies to CDU switches that are in a River cabinet that make connections to an adjacent Hill cabinet.
    
    - xX : where "X" is the River cabinet identification number (the figure above is "3000")
    - cC : where "C" is the chassis identification number. This should be "0".
    - hH : where "H" is the slot number in the cabinet (height)
    - sS : where "S" is the horizontal space number'

3. Each leaf switch will follow this format: `xXcCwW`:
    
    - xX : where "X" is the River cabinet identification number (the figure above is "3000")
    - cC : where "C" is the chassis identification number. This should be "0".
    - wW : where "W" is the slot number in the cabinet (height)

4. Each CDU switch will follow this format: `dDwW`:
   
   > If a CDU switch is in a River cabinet, then follow the naming convention in step 2 instead.
   
   - dD : where "D" is the Coolant Distribution Unit (CDU)
   - wW : where "W" is the management switch in a CDU
  
5. Each item in the file is either of type `Aggregation`, `CDU`, `Leaf`, or `Spine`.
6. Each line in the file must denote the Brand, either `Dell`, `Mellanox`, or `Aruba`.
7. Create the switch_metadata.csv file with this information.

```bash
linux# vi switch_metadata.csv
```

See the example files below for reference.

#### Examples

> Use case: 2 Aruba CDU Switches, 2 Aruba leaf switches, 4 Aruba aggregation switches, and 2 Aruba spine switches:

```bash
pit# cat example_switch_metadata.csv
Switch Xname,Type,Brand
d0w1,CDU,Aruba
d0w2,CDU,Aruba
x3000c0w31,Leaf,Aruba
x3000c0w32,Leaf,Aruba
x3000c0h33s1,Aggregation,Aruba
x3000c0h34s1,Aggregation,Aruba
x3000c0h35s1,Aggregation,Aruba
x3000c0h36s1,Aggregation,Aruba
x3000c0h37s1,Spine,Aruba
x3000c0h38s1,Spine,Aruba
```

> Use case: 2 Dell CDU switches, 2 Dell leaf switches, and 2 Mellanox spine switches:

```
Switch Xname,Type,Brand
d0w1,CDU,Dell
d0w2,CDU,Dell
x3000c0w36,Leaf,Dell
x3000c0w38,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h34s1,Spine,Mellanox
```

> Use case: 2 Dell leaf switches and 2 Mellanox switches in the same slot number:

```bash
pit# cat example_switch_metadata.csv
Switch Xname,Type,Brand
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h33s2,Spine,Mellanox
```

