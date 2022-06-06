# SHCD HMN Tab/HMN Connections Rules

## Table of Contents

  1. [Introduction](#introduction)
  2. [Compute node](#compute-node)
      1. [Dense four node chassis - Gigabyte or Intel chassis](#compute-node-dense)
      2. [Single node chassis - Apollo 6500 XL675D](#compute-node-single)
      3. [Dual node chassis - Apollo 6500 XL645D](#compute-node-dual)
  3. [Chassis Management Controller (CMC)](#chassis-management-controller)
  4. [Management node](#management-node)
      1. [Master](#management-node-master)
      2. [Worker](#management-node-worker)
      3. [Storage](#management-node-storage)
  5. [Application node](#application-node)
      1. [Single node chassis](#application-node-single-node-chassis)
          1. [Building component names (xnames) for nodes in a single application node chassis](#application-node-single-node-chassis-xname)
      2. [Dual node chassis](#application-node-dual-node-chassis)
          1. [Building component names (xnames) for nodes in a dual application node chassis](#application-node-dual-node-chassis-xname)
  6. [Columbia Slingshot switch](#columbia-slingshot-switch)
  7. [PDU cabinet controller](#pdu-cabinet-controller)
  8. [Cooling door](#cooling-door)
  9. [Management switches](#management-switches)

<a name="introduction"></a>

## Introduction

The `HMN` tab of the SHCD describes the air-cooled hardware present in the system and how these devices are connected to the Hardware Management Network (HMN).
This information is required by CSM to perform hardware discovery and geolocation of air-cooled hardware in the system. The `HMN` tab may contain other hardware
that is not managed by CSM, but is connected to the HMN.

The `hmn_connections.json` file is derived from the `HMN` tab of a system SHCD, and is one of the seed files required by the `Cray Site Init` (CSI) tool to generate
configuration files required to install CSM. The `hmn_connections.json` file is almost a one-to-one copy of the right-hand table in the `HMN` tab of the SHCD. It is an
array of JSON objects, and each object represents a row from the `HMN` tab. Any row that is not understood by CSI will be ignored; this includes any additional
devices connected to the HMN that are not managed by CSM.

The System Layout Service (SLS) contains data about what hardware is in the system and how it is connected to the HMN network. This data is generated when the CSI
tool generates configurations files for system. For air-cooled hardware, SLS will contain the SLS representation of the device and a Management Switch Connector
object that describes what device is plugged into a particular management switch port.

Column mapping from SHCD to `hmn_connections.json`:

| SHCD Column   | SHCD Column Name   | `hmn_connections` Field | Description                                     |
| ------------- | ------------------ | ----------------------- | ----------------------------------------------- |
| `J20`         | `Source`           | `Source`                | Name of the device connected to the HMN network |
| `K20`         | `Rack`             | `SourceRack`            | Source rack; matches regular expression `x\d+`  |
| `L20`         | `Location`         | `SourceLocation`        | For nodes (management, compute, application), this is bottom rack slot that the node occupies, and can be extracted by `[a-zA-Z]*(\d+)([a-zA-Z]*)`. For other device types, this is ignored. |
| `M20`         |                    | `SourceSubLocation`     | For compute nodes, this can be `L`, `l`, `R`, `r`, or blank. For other device types, this is ignored. |
| `N20`         | `Parent`           | `SourceParent`          |                                                 |
| `O20`         |                    | `not used`              |                                                 |
| `P20`         | `Port`             | `not used`              |                                                 |
| `Q20`         | `Destination`      | `not used`              |                                                 |
| `R20`         | `Rack`             | `DestinationRack`       | Rack of the management switch                   |
| `S20`         | `Location`         | `DestinationLocation`   | Rack slot of the management switch              |
| `T20`         |                    | `not used`              |                                                 |
| `U20`         | `Port`             | `DestinationPort`       | Switch port on the management switch            |

> Only `J20` needs to have the column name of `Source`. There are no requirements on what the other columns should be named.

Some conventions for this document:

* All `Source` names from the SHCD are converted to lowercase before being processed by the CSI tool.
* Throughout this document, the field names from the `hmn_connections.json` file will be used to referenced values from the SHCD.
* Each device type has an example of how it is represented in the `HMN` tab of the SHCD, the `hmn_connections.json` file, and in SLS.

<a name="compute-node"></a>

## Compute node

The `Source` field needs to match these conditions in order to be considered a compute node:

* Has one of the following prefixes:

  * `nid`
  * `cn`

* Ends with an integer that matches this regular expression: `(\d+$)`

  * This integer is the Node ID (NID) for the node
  * Each node should have a unique NID value

For example, the following are valid `Source` field values for compute nodes:

* `nid000001`
* `cn1`
* `cn-01`

Depending on the type of compute node, additional rules may apply. Compute nodes in the follow sections will use the `nid` prefix.

<a name="compute-node-dense"></a>

### Dense four node chassis - Gigabyte or Intel chassis

> Apollo 2000 compute nodes are not currently supported by CSM.

Air-cooled compute nodes are typically in a `2U` chassis that contains four compute nodes. Each of the compute nodes in the chassis gets its own row in the `HMN` tab,
plus a parent row.

* The value of the `SourceParent` field is used to group together the 4 nodes that are contained within the same chassis, and it is used to reference another row in
  the SHCD `HMN` tab. The referenced `SourceParent` row is used to determine the rack slot that the compute nodes occupy.
* The `SourceParent` row can be a Chassis Management Controller, which can be used to control devices underneath it. This device typically will have a connection to
  the HMN. A Gigabyte CMC is an example of a CMC. If a CMC is not connected to the HMN network, this will prevent CSM services from managing that device.
* The `SourceParent` row can be a virtual parent that is used to group the compute nodes together symbolically into a chassis. It does not need to not have a
  connection to the HMN.

The rack slot that a compute node occupies is determined by the rack slot of the `SourceParent`. The `SourceLocation` of the parent is the bottom unit number of the
chassis. All four nodes in the same chassis receive a component name (xname) with the bottom unit number of the chassis.

The BMC ordinal for a node's BMC is derived from the NID of the node by applying a modulo of four and then adding one.
For example, a node with NID 17 will have a BMC ordinal of `(17 modulo 4) + 1 == 1 + 1 == 2`. Therefore a node with NID 17 in slot 10 in cabinet 3000 will have the
component name (xname) of `x3000s10b2n0`.

#### Compute: Four node chassis: SHCD

Example: Four compute nodes in the same chassis with a CMC connected to the network. The compute node chassis is located in slot 17 of cabinet 3000, and the compute
node BMCs are connected to ports 33-36 in the management `leaf-bmc-bmc` switch in slot 14 of cabinet 3000. Port 32 on the `leaf-bmc-bmc` switch is for the CMC in
the chassis. Refer to [Chassis Management Controller](#chassis-management-controller) section for additional details.

| `Source`          | `Rack`  | `Location` |       | `Parent`          |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | ----------------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `nid000001`       | `x3000` | `u17`      | `R`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j36`  |
| `nid000002`       | `x3000` | `u18`      | `R`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j35`  |
| `nid000003`       | `x3000` | `u18`      | `L`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j34`  |
| `nid000004`       | `x3000` | `u17`      | `L`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j33`  |
| `SubRack-001-CMC` | `x3000` | `u17`      |       |                   | `-`   | `cmc`  | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j32`  |

> Note: `Source` names like `cn1` and `cn-01` are equivalent to the value `nid000001`.

Example: Four compute nodes in the same chassis without a CMC connected to the HMN network.

| `Source`          | `Rack`  | `Location` |       | `Parent`          |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | ----------------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `nid000001`       | `x3000` | `u17`      | `R`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j36`  |
| `nid000002`       | `x3000` | `u18`      | `R`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j35`  |
| `nid000003`       | `x3000` | `u18`      | `L`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j34`  |
| `nid000004`       | `x3000` | `u17`      | `L`   | `SubRack-001-CMC` | `-`   | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j33`  |
| `SubRack-001-CMC` | `x3000` | `u17`      |       |                   | `-`   |        |               |          |            |       |        |

> Note: `Source` names like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Four node chassis: HMN connections

Example Four compute nodes in the same chassis with the a CMC connected to the network. The compute node chassis is located in slot 17 of cabinet 3000, and the
compute node BMCs are connected to ports 33-36 in the management `leaf-bmc-bmc` switch in slot 14 of cabinet 3000. The `SourceParent` for the compute nodes
`SubRack-001-CMC` is connected to the port 32 on the `leaf-bmc-bmc` switch.

```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j36"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j35"}
{"Source":"nid000003","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j34"}
{"Source":"nid000004","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j33"}
{"Source":"SubRack-001-CMC","SourceRack":"x3000","SourceLocation":"u17","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j32"}
```

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

Example: Four compute nodes in the same chassis without a CMC connected to the HMN network.

> The `SourceParent` for the compute nodes `SubRack-001-CMC` is not connected the HMN network.

```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j36"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j35"}
{"Source":"nid000003","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j34"}
{"Source":"nid000004","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j33"}
{"Source":"SubRack-001-CMC","SourceRack":"x3000","SourceLocation":"u17","DestinationLocation":" ","DestinationPort":" "}
```

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Four node chassis: SLS

The CSI tool will generate the following SLS representations for compute nodes and their BMC connections to the HMN network.

##### Compute: Four node chassis: SLS: Compute node with NID 1

* Node

    ```json
    {
      "Parent": "x3000c0s17b1",
      "Xname": "x3000c0s17b1n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 1,
        "Role": "Compute",
        "Aliases": [
          "nid000001"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w14",
      "Xname": "x3000c0w14j36",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s17b1"
        ],
        "VendorName": "1/1/36"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/36`. Dell `leaf-bmc` switches will have value `ethernet1/1/36`.

##### Compute: Four node chassis: SLS: Compute node with NID 2

* Node:

    ```json
    {
      "Parent": "x3000c0s17b2",
      "Xname": "x3000c0s17b2n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 2,
        "Role": "Compute",
        "Aliases": [
          "nid000002"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w14",
      "Xname": "x3000c0w14j35",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s17b2"
        ],
        "VendorName": "1/1/35"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/35`. Dell `leaf-bmc` switches will have value `ethernet1/1/35`.

##### Compute: Four node chassis: SLS: Compute node with NID 3

* Node

    ```json
    {
      "Parent": "x3000c0s17b3",
      "Xname": "x3000c0s17b3n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 3,
        "Role": "Compute",
        "Aliases": [
          "nid000003"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w14",
      "Xname": "x3000c0w14j34",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s17b3"
        ],
        "VendorName": "1/1/34"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/34`. Dell `leaf-bmc` switches will have value `ethernet1/1/34`.

##### Compute: Four node chassis: SLS: Compute node with NID 4

* Node

    ```json
    {
      "Parent": "x3000c0s17b4",
      "Xname": "x3000c0s17b4n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 4,
        "Role": "Compute",
        "Aliases": [
          "nid000004"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w14",
      "Xname": "x3000c0w14j33",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s17b4"
        ],
        "VendorName": "1/1/33"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/33`. Dell `leaf-bmc` switches will have value `ethernet1/1/33`.

<a name="compute-node-single"></a>

### Single node chassis - Apollo 6500 XL675D

A single compute node chassis needs to match these additional conditions:

* No `SourceParent` defined
* No `SourceSubLocation` defined

This convention applies to all compute nodes that have a single node in a chassis, such as the Apollo XL675D.

#### Compute: Single node chassis: SHCD

Example: A single chassis node with NID 1 located in slot 2 of cabinet 3000. The node's BMC is connected to port 36 of the management `leaf-bmc` switch in
slot 40 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `nid000001`       | `x3000` | `u02`      |       |          | `-`   | `j03`  | `sw-smn01`    | `x3000`  | `u40`      | `-`   | `j36`  |

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Single node chassis: HMN connections

The HMN connections representation for the two SHCD table rows above:

```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u02","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j36"}
```

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Single node chassis: SLS

Compute node:

```json
{
  "Parent": "x3000c0s2b0",
  "Xname": "x3000c0s2b0n0",
  "Type": "comptype_node",
  "Class": "River",
  "TypeString": "Node",
  "ExtraProperties": {
    "NID": 1,
    "Role": "Compute",
    "Aliases": [
      "nid000001"
    ]
  }
}
```

Management switch connector

```json
{
  "Parent": "x3000c0w40",
  "Xname": "x3000c0w40j36",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0s2b0"
    ],
    "VendorName": "1/1/36"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/36`. Dell `leaf-bmc` switches will have value `ethernet1/1/36`.

<a name="compute-node-dual"></a>

### Dual node chassis - Apollo 6500 XL645D

Additional matching conditions:

* `SourceSubLocation` field contains one of: `L`, `l`, `R`, `r`.

In addition to the top-level compute node naming requirements, when there are two nodes in a single chassis, the `SourceSubLocation` is required. The
`SourceSubLocation` can contain one of the following values: `L`, `l`, `R`, `r`. These values are used to determine the BMC ordinal for the node.

* `L` or `l` translates into the component name (xname) having `b1`.
  * For example, `x3000c0s10b1b0`
* `R` or `r` translates into the component name (xname) having `b2`.
  * For example, `x3000c0s10b1b0`

This convention applies to all compute nodes that have two nodes in a chassis, such as the Apollo XL645D.

#### Compute: Dual node chassis: SHCD

Example: A compute node chassis with 2 nodes located in slot 8 of cabinet 3000. NID 1 is on the left side of the chassis, and NID 2 is on the right side.
The two node BMCs are connected to ports 37 and 38 of the management `leaf-bmc` switch in slot 40 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `nid000001`       | `x3000` | `u08`      | `L`   |          | `-`   | `j03`  | `sw-smn01`    | `x3000`  | `u40`      | `-`   | `j38`  |
| `nid000002`       | `x3000` | `u08`      | `R`   |          | `-`   | `j03`  | `sw-smn01`    | `x3000`  | `u40`      | `-`   | `j37`  |

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Dual node chassis: HMN connections

The HMN connections representation for the two SHCD table rows above:

```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"L","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j37"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"R","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j38"}
```

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Compute: Dual node chassis: SLS

##### Compute: Dual node chassis: SLS: Compute node with NID 1

* Node:

    ```json
    {
      "Parent": "x3000c0s8b1",
      "Xname": "x3000c0s8b1n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 3,
        "Role": "Compute",
        "Aliases": [
          "nid000003"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w40",
      "Xname": "x3000c0w40j38",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s8b1"
        ],
        "VendorName": "1/1/38"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/38`. Dell `leaf-bmc` switches will have value `ethernet1/1/38`.

##### Compute: Dual node chassis: SLS: Compute node with NID 2

* Node

    ```json
    {
      "Parent": "x3000c0s8b2",
      "Xname": "x3000c0s8b2n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "ExtraProperties": {
        "NID": 2,
        "Role": "Compute",
        "Aliases": [
          "nid000002"
        ]
      }
    }
    ```

* Management switch connector

    ```json
    {
      "Parent": "x3000c0w40",
      "Xname": "x3000c0w40j37",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s8b2"
        ],
        "VendorName": "1/1/37"
      }
    }
    ```

    > For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/37`. Dell `leaf-bmc` switches will have value `ethernet1/1/37`.

<a name="chassis-management-controller"></a>

## Chassis Management Controller (CMC)

> Note: This is not the same as an RCM (Rack Consolidation Module) that is present in Apollo 2000 chassis.

Matching conditions:

* This row is referenced as a `SourceParent` of another row
* `Source` field contains `cmc` or `CMC`

A Chassis Management Controller (CMC) is a device which can be used to control the BMCs underneath it. This device typically has a connection to the HMN.
A Gigabyte CMC is an example of a CMC. If a CMC is not connected to the HMN network, this will prevent CSM services from managing that device.

These devices will have the BMC ordinal of 999 for their component names (xnames). For example, `x3000c0s10b999`.

### CMC: SHCD

Example: The CMC for the chassis in slot 28 of cabinet 3000 is connected to port 32 of the management `leaf-bmc` switch in slot 22 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `SubRack-002-cmc` | `x3000` | `u28`      |       |          | `-`   | `cmc`  | `sw-smn01`    | `x3000`  | `u22`      | `-`   | `j42`  |

### CMC: HMN Connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"SubRack-002-cmc","SourceRack":"x3000","SourceLocation":"u28","DestinationRack":"x3000","DestinationLocation":"u22","DestinationPort":"j42"}
```

### CMC: SLS

Chassis Management Controller:

```json
{
  "Parent": "x3000",
  "Xname": "x3000c0s17b999",
  "Type": "comptype_chassis_bmc",
  "Class": "River",
  "TypeString": "ChassisBMC"
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w14",
  "Xname": "x3000c0w14j32",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0s17b999"
    ],
    "VendorName": "1/1/32"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/32`. Dell `leaf-bmc` switches will have value `ethernet1/1/32`.

<a name="management-node"></a>

## Management node

<a name="management-node-master"></a>

### Master

The `Source` field needs to match both of the following conditions:

* `mn` prefix
* Integer immediately after the prefix; can be padded with `0` characters

The integer after the prefix is used to determine the hostname of the master node. For example, `mn02` corresponds to hostname `ncn-m002`.

Typically, the BMC of the first master node is not connected to the HMN, as its BMC is connected to the site network.

#### Master: SHCD

Example: master node where its BMC is connected to the HMN. The master node is in slot 2 in cabinet 3000, and its BMC is connected to port 25 in the management
`leaf-bmc` switch in slot 14 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `mn02`            | `x3000` | `u02`      | `-`   |          |       | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j25`  |

Example: master node where its BMC is connected to the site network.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `mn01`            | `x3000` | `u01`      | `-`   |          |       | `j3`   |               |          |            |       |        |

#### Master: HMN Connections

Example: master node where its BMC is connected to the HMN

```json
{"Source":"mn02","SourceRack":"x3000","SourceLocation":"u02","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j25"}
```

Example: master node where its BMC is connected to the site network, and no connection to the HMN

```json
{"Source":"mn01","SourceRack":"x3000","SourceLocation":"u01"}
```

> The following is also equivalent to a master node with not connection to the HMN. The values `DestinationRack`, `DestinationLocation`, and
> `DestinationPort` can all contain whitespace and it is still considered to have no connection the HMN.
>
> ```json
> {"Source":"mn01","SourceRack":"x3000","SourceLocation":"u01","DestinationRack":" ","DestinationLocation":" ","DestinationPort":" "}
> ```

#### Master: SLS

Management master node:

```json
{
  "Parent": "x3000c0s2b0",
  "Xname": "x3000c0s2b0n0",
  "Type": "comptype_node",
  "Class": "River",
  "TypeString": "Node",
  "ExtraProperties": {
    "NID": 100008,
    "Role": "Management",
    "SubRole": "Master",
    "Aliases": [
      "ncn-m002"
    ]
  }
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w14",
  "Xname": "x3000c0w14j25",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0s2b0"
    ],
    "VendorName": "1/1/25"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/25`. Dell `leaf-bmc` switches will have value `ethernet1/1/25`.

<a name="management-node-worker"></a>

### Worker

The `Source` field needs to match both of the following conditions:

* `wn` prefix
* Integer immediately after the prefix; can be padded with `0` characters

The integer after the prefix is used to determine the hostname of the worker node. For example, `wn01` corresponds to hostname `ncn-w001`.

#### Worker: SHCD

Example: The worker node is in slot 4 of cabinet 3000, and its BMC is connected to port 48 of management `leaf-bmc` switch in slot 14 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `wn01`            | `x3000` | `u04`      | `-`   |          |       | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j48`  |

#### Worker: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"wn01","SourceRack":"x3000","SourceLocation":"u04","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j48"}
```

#### Worker: SLS

Management worker node:

```json
{
  "Parent": "x3000c0s4b0",
  "Xname": "x3000c0s4b0n0",
  "Type": "comptype_node",
  "Class": "River",
  "TypeString": "Node",
  "ExtraProperties": {
    "NID": 100006,
    "Role": "Management",
    "SubRole": "Worker",
    "Aliases": [
      "ncn-w001"
    ]
  }
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w14",
  "Xname": "x3000c0w14j48",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0s4b0"
    ],
    "VendorName": "1/1/48"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/48`. Dell `leaf-bmc` switches will have value `ethernet1/1/48`.

<a name="management-node-storage"></a>

### Storage

The `Source` field needs to match both of the following conditions:

* `sn` prefix
* Integer immediately after the prefix; can be padded with `0` characters

The integer after the prefix is used to determine the hostname of the storage node. For example, `sn01` corresponds to hostname `ncn-s001`.

#### Storage: SHCD

Example: The storage node is in slot 4 of cabinet 3000, and its BMC is connected to port 29 of management `leaf-bmc` switch in slot 14 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `sn01`            | `x3000` | `u07`      | `-`   |          |       | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j29`  |

#### Storage: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"sn01","SourceRack":"x3000","SourceLocation":"u07","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j29"}
```

#### Storage: SLS

Management storage node:

```json
{
  "Parent": "x3000c0s7b0",
  "Xname": "x3000c0s7b0n0",
  "Type": "comptype_node",
  "Class": "River",
  "TypeString": "Node",
  "ExtraProperties": {
    "NID": 100003,
    "Role": "Management",
    "SubRole": "Storage",
    "Aliases": [
      "ncn-s001"
    ]
  }
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w14",
  "Xname": "x3000c0w14j29",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0s7b0"
    ],
    "VendorName": "1/1/29"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/29`. Dell `leaf-bmc` switches will have value `ethernet1/1/29`.

<a name="application-node"></a>

## Application node

The `Source` field needs to match these conditions to be considered an application node:

* Has one of the following prefixes:
  * `uan`
  * `gn`
  * `ln`

> Note: The naming conventions for application nodes can be unique to a system. Refer to the
> [Create Application Node Configuration YAML](create_application_node_config_yaml.md)
> procedure for the process to add additional `Source` name prefixes for application nodes.

<a name="application-node-single-node-chassis"></a>

### Single node chassis

A single application node chassis needs to match these additional conditions:

* No `SourceParent` defined
* No `SourceSubLocation` defined

This convention applies to all application nodes that have a single node in a chassis.

#### Application node: Single node chassis: SHCD

Example: application node is in slot 4 of cabinet 3000, and its BMC is connected to port 25 of management `leaf-bmc` switch in slot 14 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `uan01`           | `x3000` | `u04`      | `-`   |          |       | `j3`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j25`  |

#### Application node: Single node chassis: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"uan01","SourceRack":"x3000","SourceLocation":"u04","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j25"}
```

<a name="application-node-single-node-chassis-xname"></a>

#### Building component names (xnames) for nodes in a single application node chassis

The component name (xname) format for nodes takes the form of `xXcCsSbBnN`:

* `xX`: where `X` is the cabinet or rack identification number.
* `cC`: where `C` is the chassis identification number. This should be `0`.
* `sS`: where `S` is the lowest slot the node chassis occupies.
* `bB`: where `B` is the ordinal of the node BMC. This should be `0`.
* `nN`: where `N` is the ordinal of the node This should be `0`.

For example, if an application node is in slot 4 of cabinet 3000, then it would have `x3000c0s4b0n0` as its component name (xname).

<a name="application-node-dual-node-chassis"></a>

### Dual node chassis

Additional matching conditions:

* `SourceSubLocation` field contains one of: `L`, `l`, `R`, `r`.

In addition to the top-level compute node naming requirements, when there are two nodes in a single chassis, the `SourceSubLocation` is required. The
`SourceSubLocation` can contain one of the following values: `L`, `l`, `R`, `r`. These values are used to determine the BMC ordinal for the node.

* `L` or `l` translates into the component name (xname) having `b1`

  * For example, `x3000c0s10b1b0`

* `R` or `r` translates into the component name (xname) having `b2`

  * For example, `x3000c0s10b1b0`

This convention applies to all application nodes that have two nodes in a single chassis.

#### Application node: Dual node chassis: SHCD

Example: An application node chassis with 2 nodes located in slot 8 of cabinet 3000. `uan01` is on the left side of the chassis, and `uan02` is on the right side. The two
node BMCs are connected to ports 37 and 38 of the management `leaf-bmc` switch in slot 40 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `uan01`           | `x3000` | `u08`      | `L`   |          | `-`   | `j03`  | `sw-smn01`    | `x3000`  | `u40`      | `-`   | `j38`  |
| `uan02`           | `x3000` | `u08`      | `R`   |          | `-`   | `j03`  | `sw-smn01`    | `x3000`  | `u40`      | `-`   | `j37`  |

> Note: `Source` values like `cn1` and `cn-01` are equivalent to the value `nid000001`.

#### Application node: Dual node chassis: HMN connections

The HMN connections representation for the two SHCD table rows above:

```json
{"Source":"uan01","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"L","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j37"}
{"Source":"uan02","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"R","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j38"}
```

<a name="application-node-dual-node-chassis-xname"></a>

#### Building component names (xnames) for nodes in a dual application node chassis

The component name (xname) format for nodes takes the form of `xXcCsSbBnN`:

* `xX`: where `X` is the Cabinet or Rack identification number.
* `cC`: where `C` is the chassis identification number. This should be `0`.
* `sS`: where `S` is the lowest slot the node chassis occupies.
* `bB`: where `B` is the ordinal of the node BMC.

  * If the `SourceSubLocation` is `L` or `l`, then this should be `1`.
  * If the `SourceSubLocation` is `R` or `r`, then this should be `2`.

* `nN`: where `N` is the ordinal of the node This should be `0`.

For example:

* If an application node is in slot 8 of cabinet 3000 with a `SourceSubLocation` of `L`, then it would have `x3000c0s8b1n0` as its component name (xname).
* If an application node is in slot 8 of cabinet 3000 with a `SourceSubLocation` of `R`, then it would have `x3000c0s8b2n0` as its component name (xname).

<a name="columbia-slingshot-switch"></a>

## Columbia Slingshot switch

The `Source` field needs to matching one of the following conditions:

* Prefixed with `sw-hsn`
* Equal to `columbia` or `Columbia`

The following are examples of valid matches:

* `sw-hsn01`
* `Columbia`
* `columbia`

### Columbia Slingshot switch: SHCD

Example: A Columbia Slingshot switch in slot 42 of cabinet 3000. Its BMC is connected to port 45 of the `leaf-bmc` switch in slot 38 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `sw-hsn01`        | `x3000` | `u42`      | `-`   |          |       | `j3`   | `sw-smn01`    | `x3000`  | `u38`      | `-`   | `j45`  |

> Note: `Source` values like `Columbia` or `columbia` are also valid.

### Columbia Slingshot switch: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"sw-hsn01","SourceRack":"x3000","SourceLocation":"u42","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j45"}
```

### Columbia Slingshot switch: SLS

Router BMC:

```json
{
  "Parent": "x3000",
  "Xname": "x3000c0r42b0",
  "Type": "comptype_rtr_bmc",
  "Class": "River",
  "TypeString": "RouterBMC",
  "ExtraProperties": {
    "Username": "vault://hms-creds/x3000c0r42b0",
    "Password": "vault://hms-creds/x3000c0r42b0"
  }
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w38",
  "Xname": "x3000c0w38j45",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000c0r42b0"
    ],
    "VendorName": "1/1/45"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/45`. Dell `leaf-bmc` switches will have value `ethernet1/1/45`.

<a name="pdu-cabinet-controller"></a>

## PDU cabinet controller

A PDU cabinet controller is the device that is connected to the HMN network and manages PDU underneath it.

The `Source` field for a PDU Cabinet Controller needs to match the following regular expression: `(x\d+p|pdu)(\d+)`. This regular expression matches the following 2 patterns:

* `xXpP` where `X` is the cabinet number and `P` is the ordinal of the PDU controller in the cabinet
* `pduP` where `P` is the ordinal of the PDU controller in the cabinet

The following are examples of valid matches:

* `x3000p0`
* `pdu0`

### PDU cabinet controller: SHCD

Example: PDU controller for cabinet 3000 is connected port 41 of the `leaf-bmc` switch in slot 38 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `x3000p0`         | `x3000` |            | `-`   |          |       | `i0`   | `sw-smn01`    | `x3000`  | `u38`      | `-`   | `j41`  |

Alternative naming convention for the same HMN connection.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `pdu0`            | `x3000` | `pdu0`     | `-`   |          |       | `i0`   | `sw-smn01`    | `x3000`  | `u38`      | `-`   | `j41`  |

### PDU cabinet controller: HMN connections

The HMN connections representation for the first SHCD table above.

```json
{"Source":"x3000p0","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j41"}
```

The HMN connections representation for alternative naming convention.

```json
{"Source":"pdu0","SourceRack":"x3000","SourceLocation":"pdu0","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j41"}
```

### PDU cabinet controller: SLS

Cabinet PDU controller:

```json
{
  "Parent": "x3000",
  "Xname": "x3000m0",
  "Type": "comptype_cab_pdu_controller",
  "Class": "River",
  "TypeString": "CabinetPDUController"
}
```

Management switch connector:

```json
{
  "Parent": "x3000c0w38",
  "Xname": "x3000c0w38j41",
  "Type": "comptype_mgmt_switch_connector",
  "Class": "River",
  "TypeString": "MgmtSwitchConnector",
  "ExtraProperties": {
    "NodeNics": [
      "x3000m0"
    ],
    "VendorName": "1/1/41"
  }
}
```

> For Aruba `leaf-bmc` switches, the `VendorName` value will be `1/1/41`. Dell `leaf-bmc` switches will have value `ethernet1/1/41`.

<a name="cooling-door"></a>

## Cooling door

The `Source` field for a cooling door contains `door`.

Cooling doors in an air-cooled cabinet are not currently supported by CSM software and are ignored.

### Cooling door: SHCD

Example: Cooling door for cabinet 3000 is connected to port 27 of the `leaf-bmc` switch in slot 36 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `x3000door-Motiv` | `x3000` |            | `-`   |          |       | `j1`   | `sw-smn04`    | `x3000`  | `u36`      | `-`   | `j27`  |

### Cooling door: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}
```

### Cooling door: SLS

Cooling doors are not currently supported by HMS services, and are not present in SLS.

<a name="management-switches"></a>

## Management switches

The `Source` field has one of the following prefixes:

* `sw-agg`
* `sw-25g`
* `sw-40g`
* `sw-100g`
* `sw-smn`

Any management switch that is found in the `HMN` tab of the SHCD will be ignored by CSI.

### Management switches: SHCD

Example: Management switch in slot 12 of cabinet 3000, its management port is connected to port 41 of the `leaf-bmc` management switch in slot 14 of cabinet 3000.

| `Source`          | `Rack`  | `Location` |       | `Parent` |       | `Port` | `Destination` | `Rack`   | `Location` |       | `Port` |
| ----------------- | ------- | ---------- | ----- | -------- | ----- | ------ | ------------- | -------- | ---------- | ----- | ------ |
| `sw-25g01`        | `x3000` | `u12`      | `-`   |          |       | `j1`   | `sw-smn01`    | `x3000`  | `u14`      | `-`   | `j41`  |

### Management switches: HMN connections

The HMN connections representation for the SHCD table row above:

```json
{"Source":"sw-25g01","SourceRack":"x3000","SourceLocation":"u12","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j41"}
```

### Management switches: SLS

The management switches in SLS are not populated by `hmn_connections.json`, but instead from `switch_metadata.csv`.
