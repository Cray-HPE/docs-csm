# Create Cabinets YAML

This page provides directions on constructing the optional "cabinets.yaml" file. This file lists cabinet ids for any systems with non-contiguous cabinet id numbers and controls how the `csi config init` command treats cabinet ids.

This file is manually created and follows this format. For each "type" of cabinet can have several fields: total_number of cabinets of this type, starting_id for this cabinet type, and a list of the ids.

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
    - id: 1002
    - id: 1003
- type: river
  total_number: 4
  starting_id: 3000
```

In the above example file, there are 2 Hill cabinets that will be automatically numbered as 9000 and 9001. The Mountain cabinets appear in 3 groupings of four ids. The River cabinets are non-contiguous in 4 separated ids.

A system will Hill cabinets can have 1 to 4 cabinet ids. There is no limit on the number of Mountain or River cabinets.

When the above `cabinets.yaml` file is used, `csi` will ignore any command-line argument to `csi config init` for starting-mountain-cabinet, starting-river-cabinet, starting-hill-cabinet, mountain-cabinets, river-cabinets, or hill-cabinets.
