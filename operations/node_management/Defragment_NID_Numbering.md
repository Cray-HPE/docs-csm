# Defragment NID Numbering

This procedure will rearrange NIDs for specified compute nodes to create a numerically (NID) and lexicographically (xname) contiguous block of NIDs at the specified start point.

It is recommended that the system be taken down for maintenance while performing this procedure.

This procedure should only be performed if absolutely required. Some reasons for needing to perform this procedure include:

* Compute nodes were added to SLS with incorrect NID numbering, missing node entries, and/or extra node entries.
* Compute nodes were permanently moved, removed, or re-provisioned and there is a desire to remove NID numbering gaps.

The example in this procedure removes NID gaps from 2 cabinets of compute nodes that were a result of incorrect numbering in SLS.

## Topics

* [Prerequisites](#prerequisites)
* [Defragment NID script functionality and limitations](#defragment-nid-script-functionality-and-limitations)
* [NID defragmentation procedure](#nid-defragmentation-procedure)
  * [Step 1: Run the defragmentation script](#step-1-run-the-defragmentation-script)
  * [Step 2: Perform reload of DVS/LNet service](#step-2-perform-reload-of-dvslnet-service)
* [Troubleshooting](#troubleshooting)
  * [Discovery errors](#discovery-errors)
  * [Invalid NID range](#invalid-nid-range)

## Prerequisites

* Hardware State Manager's (HSM) inventory data is up to date (Hardware has not changed since the previous discovery).
* Chassis-level entries exist in the System Layout Service (SLS) and are correct for all Mountain and Hill chassis.
* All compute nodes are powered off.

## Defragment NID script functionality and limitations

In the process of defragmenting NIDs, the `defragment_nids.py` script will:

* Update the NID numbers for compute node entries in HSM.
* Update/create SLS compute node entries with correct NID numbering and aliases.
* Remove node entries from HSM that were not previously removed due to missed blade swap procedure steps. This includes associated entries
  under `/State/Components`, `/Inventory/ComponentEndpoints`, `/Inventory/Hardware`, and `/Inventory/EthernetInterfaces`.
* Remove SLS node entries with conflicting NIDs that are not in HSM.
* Correct the _Class_ designation of compute nodes in HSM.

Limitations of the `defragment_nids.py` script:

* Only affects compute nodes.
* HSM node entries are only removed if the "leftover" nodes are of a different model than the existing nodes in the same slot.
* SLS node entries that do not exist in HSM are only removed if their NID falls within the specified NID block.

## NID defragmentation procedure

### Step 1: Run the defragmentation script

1. (`ncn-mw#`) Choose the starting NID for the NID block (e.g., 1000).

    ```bash
    export NID_START=1000
    ```

1. (`ncn-mw#`) Choose the components to include in the NID block (e.g., `x1000`,`x3000`).

    This can be specified at cabinet (`x#`), chassis (`x#c#`), slot (`x#c#s#`), or even node level (`x#c#s#b#n#`).
    This list always gets expanded to include all compute nodes contained by the specified parent components.

    ```bash
    export INCLUDE_LIST=x1000,x3000
    ```

1. Run `defragment_nids.py`.

    **NOTE:** Administrators can do a dryrun of `defragment_nids.py` to print out a report of what will happen without affecting the system's NID numbering
    by specifying `--dryrun`.

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/defragment_nids.py --start ${NID_START} --include ${INCLUDE_LIST} | jq .
    ```

    Example (summarized) output:

    ```json
    {
      "Description": "NID Defragmentation Report",
      "StartingNID": 1000,
      "Include": [
        "x1000",
        "x3000"
      ],
      "HSMChanges": [
        {
          "ID": "x1000c0s0b0n0",
          "OldNID": 1000,
          "NewNID": 1000
        },
        {
          "ID": "x1000c0s0b0n1",
          "OldNID": 1001,
          "NewNID": 1001
        },
        {
          "ID": "x1000c0s0b1n0",
          "OldNID": 1002,
          "NewNID": 1002
        },
        ...
        {
          "ID": "x1000c0s2b1n0",
          "OldNID": 1010,
          "NewNID": 1009
        },
        {
          "ID": "x1000c0s3b0n0",
          "OldNID": 1012,
          "NewNID": 1010
        },
        {
          "ID": "x1000c0s3b0n1",
          "OldNID": 1013,
          "NewNID": 1011
        },
        {
          "ID": "x3001c0s1b1n0",
          "OldNID": 1,
          "NewNID": 1012
        },
        ...
        {
          "ID": "x3000c0s6b0n0",
          "OldNID": 20,
          "NewNID": 1020
        }
      ],
      "SLSEntries": [
        {
          "Xname": "x1000c0s0b0n0",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001000"
            ],
            "NID": 1000,
            "Role": "Compute"
          }
        },
        {
          "Xname": "x1000c0s0b0n1",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001001"
            ],
            "NID": 1001,
            "Role": "Compute"
          }
        },
        {
          "Xname": "x1000c0s0b1n0",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001002"
            ],
            "NID": 1002,
            "Role": "Compute"
          }
        },
        ...
        {
          "Xname": "x1000c0s2b1n0",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001009"
            ],
            "NID": 1009,
            "Role": "Compute"
          }
        },
        {
          "Xname": "x1000c0s3b0n0",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001010"
            ],
            "NID": 1010,
            "Role": "Compute"
          }
        },
        {
          "Xname": "x1000c0s3b0n1",
          "Class": "Hill",
          "ExtraProperties": {
            "Aliases": [
              "nid001011"
            ],
            "NID": 1011,
            "Role": "Compute"
          }
        },
        {
          "Xname": "x3000c0s1b1n0",
          "Class": "River",
          "ExtraProperties": {
            "Aliases": [
              "nid001012"
            ],
            "NID": 1012,
            "Role": "Compute"
          }
        },
        ...
        {
          "Xname": "x3000c0s6b0n0",
          "Class": "River",
          "ExtraProperties": {
            "Aliases": [
              "nid001020"
            ],
            "NID": 1020,
            "Role": "Compute"
          }
        }
      ],
      "NodesRemovedFromHSM": [],
      "NodesRemovedFromSLS": [
        "x1000c0s2b0n1",
        "x1000c0s2b1n1"
      ],
      "Errors": []
    }
    ```

    Example output if `--output text` is specified:

    ```text
    NID Defragmentation Report
    =================
    Starting NID: 1000
    Include: ['x1000', 'x3000']
    =================
    HSM Changes:
    x1000c0s0b0n0 1000 -> 1000
    x1000c0s0b0n1 1001 -> 1001
    x1000c0s0b1n0 1002 -> 1002
    x1000c0s0b1n1 1003 -> 1003
    x1000c0s1b0n0 1004 -> 1004
    x1000c0s1b0n1 1005 -> 1005
    x1000c0s1b1n0 1006 -> 1006
    x1000c0s1b1n1 1007 -> 1007
    x1000c0s2b0n0 1008 -> 1008
    x1000c0s2b1n0 1010 -> 1009
    x1000c0s3b0n0 1012 -> 1010
    x1000c0s3b0n1 1013 -> 1011
    x3000c0s1b1n0 1 -> 1012
    x3000c0s1b2n0 2 -> 1013
    x3000c0s1b3n0 3 -> 1014
    x3000c0s1b4n0 4 -> 1015
    x3000c0s3b1n0 11 -> 1016
    x3000c0s3b2n0 12 -> 1017
    x3000c0s3b3n0 13 -> 1018
    x3000c0s3b4n0 14 -> 1019
    x3000c0s6b0n0 20 -> 1020

    SLS Entries:
    {"Xname": "x1000c0s0b0n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001000"], "NID": 1000, "Role": "Compute"}}
    {"Xname": "x1000c0s0b0n1", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001001"], "NID": 1001, "Role": "Compute"}}
    {"Xname": "x1000c0s0b1n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001002"], "NID": 1002, "Role": "Compute"}}
    {"Xname": "x1000c0s0b1n1", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001003"], "NID": 1003, "Role": "Compute"}}
    {"Xname": "x1000c0s1b0n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001004"], "NID": 1004, "Role": "Compute"}}
    {"Xname": "x1000c0s1b0n1", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001005"], "NID": 1005, "Role": "Compute"}}
    {"Xname": "x1000c0s1b1n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001006"], "NID": 1006, "Role": "Compute"}}
    {"Xname": "x1000c0s1b1n1", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001007"], "NID": 1007, "Role": "Compute"}}
    {"Xname": "x1000c0s2b0n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001008"], "NID": 1008, "Role": "Compute"}}
    {"Xname": "x1000c0s2b1n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001009"], "NID": 1009, "Role": "Compute"}}
    {"Xname": "x1000c0s3b0n0", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001010"], "NID": 1010, "Role": "Compute"}}
    {"Xname": "x1000c0s3b0n1", "Class": "Hill", "ExtraProperties": {"Aliases": ["nid001011"], "NID": 1011, "Role": "Compute"}}
    {"Xname": "x3000c0s1b1n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001012"], "NID": 1012, "Role": "Compute"}}
    {"Xname": "x3000c0s1b2n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001013"], "NID": 1013, "Role": "Compute"}}
    {"Xname": "x3000c0s1b3n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001014"], "NID": 1014, "Role": "Compute"}}
    {"Xname": "x3000c0s1b4n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001015"], "NID": 1015, "Role": "Compute"}}
    {"Xname": "x3000c0s3b1n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001016"], "NID": 1016, "Role": "Compute"}}
    {"Xname": "x3000c0s3b2n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001017"], "NID": 1017, "Role": "Compute"}}
    {"Xname": "x3000c0s3b3n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001018"], "NID": 1018, "Role": "Compute"}}
    {"Xname": "x3000c0s3b4n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001019"], "NID": 1019, "Role": "Compute"}}
    {"Xname": "x3000c0s6b0n0", "Class": "River", "ExtraProperties": {"Aliases": ["nid001020"], "NID": 1020, "Role": "Compute"}}

    Nodes Removed From SLS:
        x1000c0s2b0n1,x1000c0s2b1n1
    ```

### Step 2: Perform reload of DVS/LNet service

DVS node maps on NCN worker nodes and gateway nodes have entries of compute nodes that include their NIDs. Because of that, the
NID defragmentation process will impact the NCN worker and gateway nodes.

Carry out the _Procedure To Perform After CSM Defragmentation of Compute Node Identifiers_ documented in publication
_HPE Cray Operating System Administration Guide: CSM on HPE Cray EX Systems_.

## Troubleshooting

### Discovery errors

The `defragment_nids.py` script checks for HSM discovery errors on the specified nodes before proceeding. It will return an error if any are found. For example:

```json
{
    "Message": "Discovery errors detected.",
    "Severity": "Error",
    "IDs": ["x1000c0s1b1", "x3000c0s6b0"]
}
```

To continue with the NID defragmentation an administrator must first debug any discovery errors such that all specified components have a discovery status of `DiscoverOK` in HSM.

See [Troubleshoot Issues with Redfish Endpoint Discovery](Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md) for debugging discovery issues.

Alternately, if these issues are known and will not affect the desired resulting NID numbering, the `--ignore-discovery-errors` option may be specified with `defragment_nids.py` to continue through these errors.

**Warning:** Continuing through discovery errors may result in incorrect NID numbering if HSM's inventory data for those nodes is missing or incorrect.

### Invalid NID range

The `defragment_nids.py` script checks for nodes with NIDs that fall within the specified NID block that are not specified in the include list. An example of this error is:

```json
{
    "Message": "There is an unexpected node NID in the requested NID range, 1000-1100",
    "Severity": "Error",
    "IDs": ["x3001c0s0b0n0", "x3001c0s0b0n1"]
}
```

These might be NCNs and UANs or compute nodes that were not covered by the specified include list. Here are some scenarios and how to fix them:

* Computes nodes in cabinets `x1000` and `x1002` were specified in the include list, so the new NID block is 1000-1100, but the compute nodes in cabinet `x1001` have NIDs 1090-1140.
  This would create a conflict so `defragment_nids.py` will return an error. This can be fixed by:

  * Change the starting NID for the new NID block (e.g., 1200).
  * Include `x1001` in the include list to include it in the new NID block.
  * Run `defragment_nids.py` to first move the computes nodes in `x1001` to another NID block then rerun `defragment_nids.py` for the compute nodes in cabinets `x1000` and `x1002`.

* Computes nodes in cabinet `x1000` were specified in the include list, so the new NID block is 1000-1100, but `x1000c1b0n0` is a UAN that was given the NID 1000.
  This would create a conflict so `defragment_nids.py` will return an error. This can be fixed by:

  * Change the starting NID for the new NID block (e.g., 1001).
  * Manually change the NID of the UAN in HSM and SLS then rerun `defragment_nids.py` for the nodes in `x1000`.

* Computes nodes in cabinet `x1000` were specified in the include list, so the new NID block is 1000-1100, but `x3000c0b0n0` is an NCN that was given the NID 1000.
  This would create a conflict so `defragment_nids.py` will return an error. It is not recommended to try and change the NID of an NCN. The best course of action is to
  change the starting NID for the new NID block.
