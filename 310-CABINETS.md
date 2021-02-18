# Cabinets

This page provides directions on constructing the optional "cabinets.yaml" file. This file lists cabinet ids for any systems with non-contiguous cabinet id numbers and controls how the "csi config init" command treats cabinet ids. 

The `cabinets.yaml` file is particularly important for upgrades from Shasta v1.3 systems as it allows the preservation of cabinet names and network VLANs.  An audit of the existing system will be required to gather the data needed to populate `cabinets.yaml`. In the example below the VLANs for cabinets 1000 and 1001 are overridden.  This example can be used to preserve existing cabinet VLANs and prevent reconfiguring switches and CMMs.  Similar cabinet numbering and preservation of VLANs can be used for Hill and River cabinets.

Use for original cabinet data for v1.3 systems use [SLS Dump data collected from the system](068-HARVEST-13-CONFIG.md). An exerpt of the data is shown below.  Cabinet names and VLANs for `comptype_cabinet` should be collected from SLS data and used to populate `cabinets.yaml` for the system.  Failure to do this will result in needing to change switch and CMM configurations.

```
   "x9000": {
      "Parent": "s0",
      "Xname": "x9000",
      "Type": "comptype_cabinet",
      "Class": "Hill",
      "TypeString": "Cabinet",
      "ExtraProperties": {
        "Networks": {
          "cn": {
            "HMN": {
              "CIDR": "10.104.0.0/22",
              "Gateway": "10.104.0.1",
              "VLan": 999
            },
            "NMN": {
              "CIDR": "10.100.0.0/22",
              "Gateway": "10.100.0.1",
              "VLan": 666
            }
          }
        }
      }
```

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

In the above example file, there are 2 Hill cabinets that will be automatically numbereed as 9000 and 9001.   The Mountain cabainets appear in 3 groupings of four ids.  The River cabinets are non-contiguous in 4 separated ids.

A system will Hill cabinets can have 1 to 4 cabinet ids.  There is no limit on the number of Mountain or River cabinets.

When the above `cabinets.yaml` file is used, the fields for each type will take precedence over any commandline argument to "csi config init" for starting-mountain-cabinet, starting-river-cabinet, starting-hill-cabinet, mountain-cabinets, river-cabinets, or hill-cabinets.  If these command line arguments provide information which is not in the cabinets.yaml file, then the information will be merged from them with the information provided in cabinets.yaml.

