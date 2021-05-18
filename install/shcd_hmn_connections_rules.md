# SHCD HMN Tab/HMN Connections Rules 
Table of contents:
1. Compute Node
    1. Dense 4 node chassis - Gigabyte or Intel chassis
    2. Single node chassis - Apollo 6500 XL675D
    3. Dual node chassis - Apollo 6500 XL645D
2. CMC
3. River HSN switch
4. PDU Controller
5. Cooling Door
6. Management Switches
7. Management Node
    1. Master
    2. Worker
    3. Storage
8. Application Nodes

## Introduction

The HMN tab of the SHCD describes the river hardware present in the system and how these devices are connected to the Hardware Management Network (HMN). This information is required by CSM to perform hardware discovery and geolocation of River hardware in the system. 

The hmn_connections.json is derived from the HMN tab of a system SHCD, and is one of the seed files required by Cray Site Init (CSI) command to generate configuration files required to install CSM. The hmn_connections.json file is almost a 1 to 1 copy of the right-hand table in the HMN tab of the SHCD. It is an array of JSON objects, and each object represents a row from the HMN tab. Any row that is not understood by CSI will be ignored.

Column mapping from SHCD to hmn_connections.json:

| SHCD Column | SHCD Column Name | hmn_connections Field |
| ----------- | ---------------- | --------------------- |
| J20         | Source           | Source                |
| K20         | Rack             | SourceRack            |
| L20         | Location         | SourceLocation        |
| M20         |                  | SourceSubLocation     |
| N20         | Parent           | SourceParent          |
| O20         |                  | `not used`            |
| P20         | Port             | `not used`            |
| Q20         | Destination      | `not used`            |
| R20         | Rack             | DestinationRack       |
| S20         | Location         | DestinationLocation   |
| T20         |                  | `not used`            |
| U20         | Port             | DestinationPort       |
> Only J20 needs to have the column name of `Source`. There are no requirements on what the other columns should be named.

Some conventions for this document:
* All Source names from the SHCD are lowercased before being processed by the CSI tool.
* Throughout this document the Field names from the hmn_connections.json file will be used to referenced values from the SHCD.


## Compute Node
The Source field needs to match these conditions to be considered a compute node:
* Has the prefix of:
  * `nid`
  * `cn`
* Source field contains ends with an integer that matches this regex: `(\d+$)`
  * This is integer is the Node ID (NID) for the node
  * Each node should have a unique NID value


The following are valid source fields for example:
  - `nid000001`
  - `cn1`
  - `cn-01`

Depending the type of compute node additional rules may apply. Compute nodes in the follow sections will use the `nid` prefix.

### Dense 4 node chassis - Gigabyte or Intel chassis
> Apollo 2000 compute nodes are not currently supported by CSM

River compute nodes are typically in a 2U chassis that contains 4 compute nodes. Each of the compute nodes in the chassis gets its own row in the HMN tab, plus a parent row.

The value of the SourceParent field is used to group together the 4 nodes that are contained withing the same chassis, and it is used to reference another row in the SHCD HMN table. The referenced SourceParent row is used to determine the rack slot that the compute nodes in occupy.
* The SourceParent row can be a Chassis Management Controller which can be used to control devices underneath it. This device typically will have a connection to the HMN. A Gigabyte CMC is an example of a CMC. If a CMC is not connected to the HMN network, this will prevent CSM services from managing that device.
* The SourceParent row can be a virtual parent that is used to symbolically group the compute nodes together into a chassis. Does not need to not have a connection to the HMN.


The rack slot that a compute node occupies is determined by the Rack Slot of the SourceParent. The SourceLocation of the parent is the bottom most U of the chassis. The xname that is given to the 4 nodes in the same chassis used by the HMS/SLS services specify that all of the computes are in the same rack U (bottommost U of the chassis)

The BMC ordinal for the nodes BMC is derived from the NID of the node, by applying a modulo of 4 plus 1.
For example, the node with NID 17 in slot 10 in cabinet 3000 will have the xname of x3000s10b2n0

#### SHCD
Example 4 compute nodes in the same chassis with a CMC connected to the network

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| nid000001       | x3000 | u17      | R   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j36  |
| nid000002       | x3000 | u18      | R   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j35  |
| nid000003       | x3000 | u18      | L   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j34  |
| nid000004       | x3000 | u17      | L   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j33  |
| SubRack-001-CMC | x3000 | u17      |     |                 | -   | cmc  | sw-smn01    | x3000  | u14      | -   | j32  |

Example 4 compute nodes in the same chassis without a CMC connected to the HMN network.

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| nid000001       | x3000 | u17      | R   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j36  |
| nid000002       | x3000 | u18      | R   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j35  |
| nid000003       | x3000 | u18      | L   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j34  |
| nid000004       | x3000 | u17      | L   | SubRack-001-CMC | -   | j3   | sw-smn01    | x3000  | u14      | -   | j33  |
| SubRack-001-CMC | x3000 | u17      |     |                 | -   |      |             |        |          |     |      |


#### HMN Connections
Example 4 compute nodes in the same chassis with the a CMC connected to the network
> The SourceParent for the compute nodes `SubRack-001-CMC` is connected to the port 32 on the leaf switch x3000c0w14
```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j36"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j35"}
{"Source":"nid000003","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j34"}
{"Source":"nid000004","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j33"}
{"Source":"SubRack-001-CMC","SourceRack":"x3000","SourceLocation":"u17","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j32"}
```

Example 4 compute nodes in the same chassis without a CMC connected to the HMN network.
> The SourceParent for the compute nodes `SubRack-001-CMC` is not connected the HMN network
```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j36"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"R","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j35"}
{"Source":"nid000003","SourceRack":"x3000","SourceLocation":"u18","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j34"}
{"Source":"nid000004","SourceRack":"x3000","SourceLocation":"u17","SourceSubLocation":"L","SourceParent":"SubRack-001-CMC","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j33"}
{"Source":"SubRack-001-CMC","SourceRack":"x3000","SourceLocation":"u17","DestinationLocation":" ","DestinationPort":" "}
```

#### SLS
Compute node with NID 1:
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

* Management Switch Connector:
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

Compute node with NID 2:
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

* Management Switch Connector:
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

Compute node with NID 3:
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

* Management Switch Connector:
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


Compute node with NID 4:
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

* Management Switch Connector:
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

### Single node chassis - Apollo 6500 XL675D
> This convention applies to all compute nodes that are chassis, such as the Apollo XL675D

A single compute node chassis needs to match these additional conditions:
* No SourceParent defined
* No SourceSubLocation defined

#### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| nid000001       | x3000 | u02      |     |                 | -   | j03  | sw-smn01    | x3000  | u40      | -   | j36  |

#### HMN Connections
```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u02","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j36"}
```

#### SLS
Node:
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

Management Switch Connector:
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

### Dual node chassis - Apollo 6500 XL645D
> The Apollo 6500 XL645D supports 2 nodes in the same chassis

Additional matching conditions:
* SourceSubLocation field contains one of: `L`, `l`, `R`, `r`.


In addition to the top-level compute node naming requirements when they are 2 nodes in a single chassis the SourceSubLocation is required. The SourceSubLocation can contain one of the following values: `L`, `l`, `R`, `r`. These values are used to determine the BMC ordinal for the node.
* `L`, `l` translates into the xname having `b1`
  * Such as x3000c0s10b1b0
* `R`, `r` translates into the xname having `b2`
  * Such as x3000c0s10b1b0

#### SHCD 
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| nid000001       | x3000 | u08      | L   |                 | -   | j03  | sw-smn01    | x3000  | u40      | -   | j38  |
| nid000002       | x3000 | u08      | R   |                 |-    | j03  | sw-smn01    | x3000  | u40      | -   | j37  |

#### HMN Connections
```json
{"Source":"nid000001","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"R","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j37"}
{"Source":"nid000002","SourceRack":"x3000","SourceLocation":"u08","SourceSubLocation":"L","DestinationRack":"x3000","DestinationLocation":"u40","DestinationPort":"j38"}
```

#### SLS
Compute node with NID 1:
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
* Management Switch Connector
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

Compute node with NID 2:
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

* Management Switch Connectors:
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

## CMC
> This is not the same as an RCM (Rack Consolidation Module) that is present in Apollo 2000 chassis.

Matching conditions:
* This row is referenced as a SourceParent of another row
* Source field contains `cmc` or `CMC`
* Has a connection to the HMN network
  * In CSM 1.X and later a row that is referenced as a SourceParent will need a connection to the HMN network to be considered a CMC.
    > Pending [CASMINST-2243](https://connect.us.cray.com/jira/browse/CASMINST-2243)
  * In CSM 0.9 and before any row referenced as a SourceParent will be treated as CMC regardless if it is connected to the HMN.

A Chassis Management Controller is a device which can be used to BMCs underneath it. This device will typically have a connection to the HMN. A Gigabyte CMC is an example of a CMC. If a CMC is not connected to the HMN network, this will prevent CSM services from managing that device.

These devices will have the BMC ordinal of 999 for their xnames. Such as x3000c0s10b999.

### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| SubRack-002-cmc | x3000 | u28      |     |                 | -   | cmc  | sw-smn01    | x3000  | u22      | -   | j42  |

### HMN Connections
```json
{"Source":"SubRack-002-cmc","SourceRack":"x3000","SourceLocation":"u28","DestinationRack":"x3000","DestinationLocation":"u22","DestinationPort":"j42"}
```

### SLS
CMC:
```json
{
  "Parent": "x3000",
  "Xname": "x3000c0s17b999",
  "Type": "comptype_chassis_bmc",
  "Class": "River",
  "TypeString": "ChassisBMC"
}
```

Management Switch Connector
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

## River HSN Switch
Matching conditions
* Source field:
  * Prefixed with: `sw-hsn`
  * Equal to `columbia` or `Columbia`

The following are examples of valid matches:
* `sw-hsn01`
* `Columbia`
* `columbia`


### SHCD
Example with `sw-hsn` prefix:

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| sw-hsn01        | x3000 | u42      | -   |                 |     | j3   | sw-smn01    | x3000  | u38      | -   | j45  |

Example with `Columbia` source name:

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| Columbia        | x3000 | u42      | -   |                 |     | j3   | sw-smn01    | x3000  | u38      | -   | j45  |

### HMN Connections
Example with `sw-hsn` prefix:
```json
{"Source":"sw-hsn01","SourceRack":"x3000","SourceLocation":"u42","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j45"}
```

Example with `Columbia` source name:
```json
{"Source":"Columbia","SourceRack":"x3000","SourceLocation":"u42","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j45"}
```

### SLS
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

Management Switch Connector:
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
    "VendorName": "ethernet1/1/45"
  }
}
```


## PDU Controller
The Source field for a PDU Controller needs to match the following:
* Source field matches regex: `(x\d+p|pdu)(\d+)`

The following are examples of valid matches:
* `x3000p0`
* `pdu0`

A PDU Controller is the device that is connected to the HMN network and manages PDU underneath it.

### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| x3000p0         | x3000 |          | -   |                 |     | i0   | sw-smn01    | x3000  | u38      | -   | j41  |

### HMN Connections
```json
{"Source":"x3000p0","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u38","DestinationPort":"j41"}
```

### SLS
Cabinet PDU Controller:
```json
{
  "Parent": "x3000",
  "Xname": "x3000m0",
  "Type": "comptype_cab_pdu_controller",
  "Class": "River",
  "TypeString": "CabinetPDUController"
}
```

Management Switch Connector:
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

## Cooling Door
The Source field for a Cooling door must match the following:
* Contains `door`

Cooling doors for River cabinets are not currently supported by CSM software and are ignored 

### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| x3000door-Motiv | x3000 |          | -   |                 |     | j1   | sw-smn04    | x3000  | u36      | -   | j27  |

### HMN Connections
```json
{"Source":"x3000door-Motiv","SourceRack":"x3000","SourceLocation":" ","DestinationRack":"x3000","DestinationLocation":"u36","DestinationPort":"j27"}
```

### SLS
Cooling doors are not currently supported by HMS services, and are not present in SLS 

## Management Switches
Matching conditions:
* Source Field has one of the following prefixes:
    * `sw-agg`
    * `sw-25g`
    * `sw-40g`
    * `sw-smn`

Any management switch that is found in the HMN tab of the SHCD will be ignored by CSI. 
### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| sw-25g01        | x3000 | u12      | -   |                 |     | j1   | sw-smn01    | x3000  | u14      | -   | j41  |

### HMN Connections
```JSON
{"Source":"sw-25g01","SourceRack":"x3000","SourceLocation":"u12","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j41"}
```
### SLS
The Management switches in SLS are not populated by hmn_connections.json, instead from switch_metadata.csv.

## Management Node
### Master
Match conditions:
* Source Field
  * `mn` prefix
  * Integer number immediately after the prefix

The integer number after the prefix is used to determine the hostname of the master node. For example, `mn02` corresponds to host name `ncn-m002`.

Typically, the first master node BMC is not connected to the HMN network, as its BMC is connected to the site network.

#### SHCD
Example master node where its BMC is connected to the HMN:

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| mn02            | x3000 | u02      | -   |                 |     | j3   | sw-smn01    | x3000  | u14      | -   | j25  |

Example master node where its BMC is connected to the site network:

| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| mn01            | x3000 | u01      | -   |                 |     | j3   |             |        |          |     |      |	 	 	 	 	 

#### HMN Connections
Example master node where its BMC is connected to the HMN:
```json
{"Source":"mn02","SourceRack":"x3000","SourceLocation":"u02","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j25"}
```

Example master node where its BMC is connected to the site network:
```json
{"Source":"mn01","SourceRack":"x3000","SourceLocation":"u01","DestinationRack":" ","DestinationLocation":" ","DestinationPort":" "}
```

#### SLS
Node:
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

Management Switch Connector:
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

### Worker
Match conditions:
* Source Field
  * `wn` prefix
  * Integer number immediately after the prefix

The integer number after the prefix is used to determine the hostname of the master node. For example, `wn01` corresponds to host name `ncn-w001`.

#### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| wn01            | x3000 | u04      | -   |                 |     | j3   | sw-smn01    | x3000  | u14      | -   | j48  |

#### HMN Connections
```json
{"Source":"wn01","SourceRack":"x3000","SourceLocation":"u04","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j48"}
```

#### SLS
Node:
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

Management Switch Connector:
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

### Storage
Match conditions:
* Source Field
  * `sn` prefix
  * Integer number immediately after the prefix

The integer number after the prefix is used to determine the hostname of the master node. For example, `sn01` corresponds to host name `ncn-s001`.

#### SHCD
| Source          | Rack  | Location |     | Parent          |     | Port | Destination | Rack   | Location |     | Port |
| --------------- | ----- | -------- | --- | --------------- | --- | ---- | ----------- | ------ | -------- | --- | ---- | 
| sn01            | x3000 | u07      | -   |                 |     | j3   | sw-smn01    |x3000   | u14      | -   | j29  |

#### HMN Connections
```json
{"Source":"sn01","SourceRack":"x3000","SourceLocation":"u07","DestinationRack":"x3000","DestinationLocation":"u14","DestinationPort":"j29"}
```
#### SLS
Node:
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

Management Switch Connector:
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

## Application Node
Refer [application node config procedure](https://stash.us.cray.com/projects/CSM/repos/docs-csm/browse/install/308-APPLICATION-NODE-CONFIG.md) for the rules related to application nodes.