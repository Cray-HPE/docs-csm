# Create Cabinets YAML

This page provides directions on constructing the optional `cabinets.yaml` file. This file lists cabinet IDs for any systems with non-contiguous cabinet ID numbers and controls how the `csi config init` command treats cabinet IDs.

The following example file is manually created and follows this format. Each `type` of cabinet can have several fields:

- `total_number` of cabinets of this type.
- `starting_id` for this cabinet type, and a list of the IDs.
- `cabinets` to specify individual cabinet overrides, or specify non-contiguous cabinet ranges. These values are optional.
  - `id` is the cabinet number.
  - `nmn-vlan` and `hmn-vlan` specify the desired VLAN configuration of the cabinet, instead of allowing Cray Site Init (CSI) to prescribe it.

      > This is typically used for liquid-cooled cabinets, to specify the current networking information configured on a cabinet.

  - `chassis-count` is a required field for EX2500 cabinets, and has no effect on non EX2500 cabinet types.
    - `liquid-cooled` is the number of liquid-cooled chassis present. This is `1`, '2', or `3`.
    - `air-cooled` with the number of air-cooled chassis present. This is `0` or `1`.

    > EX2500 cabinets can have a variable number of liquid-cooled and air-cooled chassis within them.
    > EX2500 cabinets can come in the following configurations:
    >
    > - 1 liquid-cooled chassis
    > - 2 liquid-cooled chassis
    > - 3 liquid-cooled chassis
    > - 1 liquid-cooled chassis and 1 air-cooled chassis

```yaml
---
cabinets:
- type: river
  total_number: 4
  starting_id: 3000
- type: hill
  total_number: 2
  starting_id: 9000
- type: mountain
  total_number: 4
  starting_id: 1000
  cabinets:
    - id: 1000
      nmn-vlan: 2000
      hmn-vlan: 3000
    - id: 1001
      nmn-vlan: 2001
      hmn-vlan: 3001
    - id: 1100
    - id: 1101
- type: EX2500
  total_number: 1
  cabinets:
  - id: 8000
    nmn-vlan: 2004
    hmn-vlan: 3004
    chassis-count:
      air-cooled: 0
      liquid-cooled: 3
```

In this example file, there are:

- Four River cabinets that are contiguous from 3000 to 3004.
- Two Hill cabinets that will be automatically numbered as 9000 and 9001.
- Four mountain cabinets in two non-contiguous groupings as 1000 to 1001 and 1100 and 1101.
- One EX2500 cabinet with 3 liquid-cooled chassis.

A system with Hill cabinets can have one to four cabinet IDs. There is no limit on the number of Mountain or River cabinets.

When the above `cabinets.yaml` file is used, `csi` will ignore any command-line argument to `csi config init` for `starting-mountain-cabinet`,
`starting-river-cabinet`, `starting-hill-cabinet`, `mountain-cabinets`, `river-cabinets`, or `hill-cabinets`.
