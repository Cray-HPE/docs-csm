# Switch Metadata

This page provides directions on constructing the `switch_metadata.csv` file.

This file is manually created right now and follows this format:

```
Switch Xname,Type,Brand
x3000c0w18,Leaf,Dell
x3000c0h19s1,Spine,Mellanox
x3000c0h19s2,Spine,Mellanox
```

#### Requirements

For this you will need:

- The SHCD for your system

It is worthwhile to have the [HSS Naming Convention](https://connect.us.cray.com/confluence/display/HSOS/Shasta+HSS+Component+Naming+Convention)
guide handy, or bookmarked for later, while mapping names between the SHCD and your `switch_metadata.csv` file.

#### Format

Spine and aggregation switches use the format `xXcChHsS` (`comptype_hl_switch`). Leaf switches use `xXcCwW` (`comptype_mgmt_switch`).

> More info: [HSS Naming Convention](https://connect.us.cray.com/confluence/display/HSOS/Shasta+HSS+Component+Naming+Convention)).

#### Directions

1. In your SHCD, identify your switches. Look for:
    - The slot number(s) for the leaf switches (usually 48-port switches)
        - In the below example this is x3000u22
    - The slot number(s) for the spine switches
        - In the below example this is x3000u23R and x3000u23L (two side-by-side switches)
        - Newer side-by-sides use slot numbers instead of R and L
    >   ![Layered Images Diagram](./img/shcd-rack-example.png)
2. Each spine/aggregation switch will follow this format: `xXcChHsS`
    - xX : where "X" is the river rack identification number (the figure above is "3000")
    - cC : where "C" is the cabinet identification number (the figure above is "0")
    - hH : where "H" is the slot number in the rack (height)
    - sS : where "S" is the horizontal space number'
    >
3. Each leaf switch will follow this format: `xXcCwW`:
    - xX : where "X" is the river rack identification number (the figure above is "3000")
    - cC : where "C" is the cabinet identification number (the figure above is "0")
    - wW : where "W" is the slot number in the rack (height)
4. Each item in the file is either of type `Aggregate`, `CDU`, `Leaf`, or `Spine`.
5. Each line in the file must denote the Brand, either `Dell`, `Mellanox`, or `Aruba`.

See the example files below for references.

##### Tips

You can find the Model by logging into the switch and running one of the following commands.

- On Dell:   `show system`
- On Mellanox:  `show inventory`
- On Aruba: `show system`

#### Examples

> An example with Dell and Mellanox switches:
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
