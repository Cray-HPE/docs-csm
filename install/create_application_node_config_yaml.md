# Create Application Node Config YAML

This topic provides directions on constructing the `application_node_config.yaml` file. This file controls how the `csi config init` command finds and treats application nodes discovered in the `hmn_connections.json` file when generating configuration files for the system.

* [Prerequisites](#prerequisites)
* [Background](#background)
* [Directions](#directions)

<a name="prerequisites"></a>
## Prerequisites

The `application_node_config.yaml` file can be constructed from information from one of the following sources:

- The SHCD Excel spreadsheet for the system
- The `hmn_connections.json` file generated from the system's SHCD

<a name="background"></a>
## Background

### SHCD and hmn_connections.json

The HMN tab of the SHCD describes the air-cooled hardware present in the system and how these devices are connected to the Hardware Management Network (HMN). This information is required by CSM to perform hardware discovery and geolocation of air-cooled hardware in the system. The HMN tab may contain other hardware that is not managed by CSM, but is connected to the HMN.

The `hmn_connections.json` file is derived from the HMN tab of a system SHCD, and is one of the seed files required by Cray Site Init (CSI) command to generate configuration files required to install CSM. The `hmn_connections.json` file is almost a one-to-one copy of the right-hand table in the HMN tab of the SHCD. It is an array of JSON objects, and each object represents a row from the HMN tab. Any row that is not understood by CSI will be ignored, this includes any additional devices connected to the HMN that are not managed by CSM.

For a detailed mapping between the data in the SHCD and the equivalent information in the `hmn_connections.json` file, see [Introduction to SHCD HMN Connections Rules](shcd_hmn_connections_rules.md#introduction) and [Application Nodes in SHCD HMN Connections Rules](shcd_hmn_connections_rules.md#application-node).

### What is a Source Name?

The source name is the name of the device that is being connected to the HMN network.  In the SHCD HMN tab, this is in a column with the header `Source` or the `Source` field in the element of the `hmn_connections.json` for this device. From this source name, the `csi config init` command can infer the type of hardware that is connected to the HMN network (Node BMC, PDU, HSN Switch, BMC, and more).

Example SHCD row from HMN tab with column headers representing an application node with SourceName `uan01` in cabinet `x3000` in slot 19. Its BMC is connected to port 37 of the management leaf switch in x3000 in slot 14.

| Source (J20) | Rack (K20) | Location (L20) | (M20) | Parent (N20) | (O20) | Port (P20) | Destination (Q20) | Rack (R20) | Location (S20) | (T20) | Port (U20) |
| ------------ | ---------- | -------------- | ----- | ------------ | ----- | ---------- | ----------------- | ---------- | -------------- | ----- | ---------- |
| uan01    | x3000      | u19            |       |              | -     | j3         | sw-smn01          | x3000      | u14            | -     | j37        |

Example `hmn_connections.json` row representing an application node with SourceName `uan01` in cabinet `x3000` in slot 19. Its BMC is connected to port 37 of the management leaf switch in x3000 in slot 14.

```json
{ "Source": "uan01", "SourceRack": "x3000", "SourceLocation": "u19", "DestinationRack": "x3000", "DestinationLocation": "u14", "DestinationPort": "j37" }
```

<a name="directions"></a>
## Directions

1. Create a file called `application_node_config.yaml` with the following contents.

   This is a base application node config file for CSI that does not add any additional prefixes, HSM SubRole mappings, or aliases.

   ```yaml
   ---
   # Additional application node prefixes to match in the hmn_connections.json file
   prefixes: []

   # Additional HSM SubRoles
   prefix_hsm_subroles: {}

   # Application Node aliases
   aliases: {}
   ```

2. Identify application nodes present in `hmn_connections.json` or the HMN tab of the system's SHCD. In general, everything in the HMN tab of the SHCD or `hmn_connections.json` file that starts with uan, gn, or ln, are considered application nodes and any node that does not follow the [SHCD/HMN Connections Rules](shcd_hmn_connections_rules.md) should also be considered an [application node](../glossary.md#application-node), unless it is a `KVM`.

    If the `hmn_connections.json` file is not available, then use the HMN tab of SHCD spreadsheet. This table is equivalent to the [example hmn_connections.json output](#hmn-connections-example-output) below.

    | Source (J20) | Rack (K20) | Location (L20) | (M20) | Parent (N20) | (O20) | Port (P20) | Destination (Q20) | Rack (R20) | Location (S20) | (T20) | Port (U20) |
    | ------------ | ---------- | -------------- | ----- | ------------ | ----- | ---------- | ----------------- | ---------- | -------------- | ----- | ---------- |
    | gateway01    | x3000      | u29            |       |              | -     | j3         | sw-smn01          | x3000      | u32            | -     | j42        |
    | login02      | x3000      | u28            |       |              | -     | j3         | sw-smn01          | x3000      | u32            | -     | j43        |
    | lnet01       | x3000      | u27            |       |              | -     | j3         | sw-smn01          | x3000      | u32            | -     | j41        |
    | vn01         | x3000      | u25            |       |              | -     | j3         | sw-smn01          | x3000      | u32            | -     | j40        |
    | uan01        | x3000      | u23            |       |              | -     | j3         | sw-smn01          | x3000      | u32            | -     | j39        |

    If the `hmn_connections.json` file is available, then the following command can be used to show the HMN rows that are application nodes.

    ```bash
    linux# cat hmn_connections.json | jq -rc '.[] | select(.Source |
      test("^((mn|wn|sn|nid|cn|cn\\-|pdu)\\d+|.*(cmc|rcm|kvm|door).*|x\\d+p\\d*|sw-.+|columbia$)"; "i") | not)'
    ```

    <a name="hmn-connections-example-output"></a>
    Example `hmn_connections.json` output:

    ```json
    {"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u29","DestinationRack":"x3000","DestinationLocation":"u32","DestinationPort":"j42"},
    {"Source":"login02","SourceRack":"x3000","SourceLocation":"u28","DestinationRack":"x3000","DestinationLocation":"u32","DestinationPort":"j43"}
    {"Source":"lnet01","SourceRack":"x3000","SourceLocation":"u27","DestinationRack":"x3000","DestinationLocation":"u32","DestinationPort":"j41"}
    {"Source":"vn01","SourceRack":"x3000","SourceLocation":"u25","DestinationRack":"x3000","DestinationLocation":"u32","DestinationPort":"j40"},
    {"Source":"uan01","SourceRack":"x3000","SourceLocation":"u23","DestinationRack":"x3000","DestinationLocation":"u32","DestinationPort":"j39"},
    ```

3. Add additional application node prefixes.

    The `prefixes` field is an array of strings, that augments the list of source name prefixes that are treated as application nodes. By default, `csi config init` only looks for application nodes that have source names that start with `uan`, `gn`, and `ln`. If the system contains application nodes that fall outside of those source name prefixes, then additional prefixes must be added to `application_node_config.yaml`. These additional prefixes will be used in addition to the default prefixes.

    To add an additional prefix, append a new string element to the `prefixes` array.

    > **NOTE:** The command `csi config init` does a case insensitive check for whether a source name contains an application node prefix. For example, the prefix `uan` will match `uan`, `Uan`, and `UAN`.

    From the HMN example above, the following additional prefixes are required:

    ```yaml
    # Additional application node prefixes to match in the hmn_connections.json file
    prefixes:
      - gateway
      - login
      - lnet
      - vn
    ```

4. Add HSM SubRoles for application node prefixes.

    The `prefix_hsm_subroles` field mapping application node prefix (string) to the applicable Hardware State Manager (HSM) SubRole (string) for the application nodes. All applications nodes have the HSM Role of Application, and the SubRole value can be used to label what type of the application node it is (such as UAN, Gateway, LNETRouter, and more).

    By default, the `csi config init` command will use the following SubRoles for application nodes:

    Prefix | HSM SubRole
    ------ | -----------
    uan    | UAN
    ln     | UAN
    gn     | Gateway

    If there are no additional prefixes in the SHCD or no desire to use a different HSM SubRole than the default, then this `prefix_hsm_subroles` field does not need any data populated.

    To add additional HSM SubRole for a given prefix, add a new mapping under the `prefix_hsm_subroles` field. Where the key is the application node prefix and the value is the HSM SubRole.

    Valid HSM SubRoles values are: `Worker`, `Master`, `Storage`, `UAN`, `Gateway`, `LNETRouter`, `Visualization`, and `UserDefined`.

    From the HMN example above, the following additional prefix HSM SubRole mappings are required:

    ```yaml
    # Additional HSM SubRoles
    prefix_hsm_subroles:
      login: UAN
      lnet: LNETRouter
      gateway: Gateway
      vn: Visualization
    ```

5. Add application node aliases.

    The `aliases` field is an map of component name (xname) strings to an array of alias strings.
    > For guidance on building application node component names (xnames), follow one of the following:
    > * [Building component names (xnames) for nodes in a single application node chassis](shcd_hmn_connections_rules.md#application-node-single-node-chassis-xname)
    > * [Building component names (xnames) for nodes in a dual application node chassis](shcd_hmn_connections_rules.md#application-node-dual-node-chassis-xname)

    By default, the `csi config init` command does not set the `ExtraProperties.Alias` field for application nodes in the SLS input file.

    For each application node, add its alias mapping under the `aliases` field. Where the key is the component name (xname) of the application node, and the value is an array of aliases (strings) which allows for one or more aliases to be specified for an application node.

    From the HMN example above, the following application node aliases are required:

    ```yaml
    # Application Node aliases
    aliases:
      x3113c0s29b0n0: ["gateway01"]
      x3113c0s28b0n0: ["login02"]
      x3113c0s27b0n0: ["lnet01"]
      x3113c0s25b0n0: ["visualization01", "vn02"]
      x3113c0s23b0n0: ["uan01"]
    ```
    > The ordering of component names (xnames) under `aliases` does not matter.

6. Final information in the example `application_node_config.yaml` built from the HMN example above.

    ```yaml
    ---
    # Additional application node prefixes to match in the hmn_connections.json file
    prefixes:
      - gateway
      - login
      - lnet
      - vn

    # Additional HSM SubRoles
    prefix_hsm_subroles:
      login: UAN
      lnet: LNETRouter
      gateway: Gateway
      vn: Visualization

    # Application Node aliases
    aliases:
      x3113c0s29b0n0: ["gateway01"]
      x3113c0s28b0n0: ["login02"]
      x3113c0s27b0n0: ["lnet01"]
      x3113c0s25b0n0: ["visualization01", "vn02"]
      x3113c0s23b0n0: ["uan01"]
    ```

