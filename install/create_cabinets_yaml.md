# Create Cabinets YAML

This page provides directions on constructing the `cabinets.yaml` file. This file lists cabinet IDs for any systems with non-contiguous cabinet ID numbers, as well as VLAN overrides, and controls how the `csi config init` command treats cabinet IDs.

The following example file is manually created and follows this format. Each "type" of cabinet can have several fields: `total_number` of cabinets of this type, `starting_id` for this cabinet type, and a list of the IDs.

```yaml
---
cabinets:
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
      nmn-vlan: 2100
      hmn-vlan: 3100
    - id: 1101
      nmn-vlan: 2101
      hmn-vlan: 3101
- type: river
  total_number: 4
  starting_id: 3000
```

In this example file, there are two Hill cabinets that will be automatically numbered as 9000 and 9001. The Mountain cabinets appear in two groups as 1000 and 1001, and then another area in 1100 and 1101, with VLAN IDs related to the cabinet number. This is one way to provide space in the cabinet IDs to allow for future expansion of the system or to identify location of a row of cabinets. The River cabinets are contiguous in four separated IDs as 3000, 3001, 3002, and 3003.

A system with Hill cabinets can have one to four cabinet IDs. There is no limit on the number of Mountain or River cabinets.

When the example `cabinets.yaml` file is used, `csi` will ignore any command-line argument to `csi config init` for `starting-mountain-cabinet`, `starting-river-cabinet`, `starting-hill-cabinet`, `mountain-cabinets`, `river-cabinets`, or `hill-cabinets`.
