# Application Node Config

This page provides directions on constructing the `application_node_config.yaml` file. This file controls how the `csi config init` command finds and treats applications nodes discovered the `hmn_connections.json` file when building the SLS Input file. 

The following `hmn_connections.json` file contains 4 application nodes. When the `csi config init` command is used without a `application_node_config.yaml` file, only the application node `uan01` will be included the generated SLS input file. The other 3 application nodes will be ignored as they have unknown prefixes and will not be present in the SLS Input file.
```json
[
  {"Source":"uan01",     "SourceRack":"x3000", "SourceLocation":"u23", "DestinationRack":"x3000", "DestinationLocation":"u13", "DestinationPort":"j37"},
  {"Source":"gateway01", "SourceRack":"x3113", "SourceLocation":"u23", "DestinationRack":"x3113", "DestinationLocation":"u13", "DestinationPort":"j37"},
  {"Source":"vn02",      "SourceRack":"x3114", "SourceLocation":"u23", "DestinationRack":"x3114", "DestinationLocation":"u13", "DestinationPort":"j37"},
  {"Source":"login02",   "SourceRack":"x3115", "SourceLocation":"u23", "DestinationRack":"x3115", "DestinationLocation":"u13", "DestinationPort":"j37"}
]
```

This file is manually created and follows this format. The 3 fields `prefixes`, `prefix_hsm_subroles`, and `aliases` are optional and do not need to be specified if not needed.
```yaml
---
# Additional application node prefixes to match on the Source field in the hmn_connections.json file
# See step 1 for additional information
prefixes:
  - gateway
  - vn

# Additional HSM SubRole mappings
# If a prefix does not have an HSM SubRole defined, the application node will not have a SubRole. 
# See step 2 for additional information
prefix_hsm_subroles:
  gateway: Gateway
  vn: Visualization

# Application Node aliases
# One or more aliases can be specified for an application node
# If an application does not have entry in this map, then it will not have any aliases defined in SLS 
# See step 3 for additional information
aliases:  
  x3113c0s23b0n0: ["gateway-01"]
  x3114c0s23b0n0: ["visualization-02", "vn-02"]
```

When the above `application_node_config.yaml` file is used 3 application nodes (`uan01`, `gateway01`, and `vn02`) will included in the generated SLS input file. The `login02` application node will be ignored.

The following application node configuration does not add any additional prefixes, HSM subroles, or aliases: 
```yaml
# Additional application node prefixes to match in the hmn_connections.json file
prefixes: [] 

# Additional HSM SubRoles
prefix_hsm_subroles: {}

# Application Node aliases
aliases: {}  
```

#### Requirements
For this you will need:
- The `hmn_connections.json` file for your system

#### Background
__What is a source name?__

Example entry from the `hmn_connections.json` file. The source name is the `Source` field, and this name of the device that is being connected to the HMN network. From this source name the `csi config init` command can infer the type of hardware that is connected to the HMN network (Node, PDU, HSN Switch, etc...).
```json
{
    "Source": "uan01",
    "SourceRack": "x3000",
    "SourceLocation": "u19",
    "DestinationRack": "x3000",
    "DestinationLocation": "u14",
    "DestinationPort": "j37"
}
```

#### Directions
1. __Add additional Application node Prefixes__

    The `prefixes` field is an array of strings, that augments the list of source name prefixes that are treated as application nodes. By default `csi config init` only looks for application nodes that have source names that start with `uan`, `gn`, and `ln`. If your system contains application nodes that fall outside of those source name prefixes you will need to add additional prefixes to `application_node_config.yaml`. These additional prefixes will used in addition to the default prefixes. 

    Note: When `csi config init` is case insensitive check when checking if a source name contains an application node prefix. 

    To add an additional prefix append a new string element to the `prefixes` array:
    ```yaml
    ---
    prefixes: # Additional application node prefixes
      - gateway
      - vn
      - login # New prefix. Match source names that start with "login", such as login02
    ```

2. __Add HSM SubRoles for Application node prefixes__

    The `prefix_hsm_subroles` field mapping application node prefix (string) to the applicable Hardware State Manager (HSM) SubRole (string) for the application nodes. All applications nodes have the HSM Role of `Application`, and the SubRole value can be used to label what type of the application node it is (such as UAN, Gateway, etc...).

    By default, the `csi config init` command will use the following SubRoles for application nodes:

     Prefix | HSM Subrole 
     ------ | ----------- 
     uan    | UAN         
     ln     | UAN       
     gn     | Gateway     

    To add additional HSM SubRole for a given prefix add a new mapping under the `prefix_hsm_subroles` field. Where the key is the application node prefix and the value is the HSM SubRole.
    ```yaml
    ---
    prefix_hsm_subroles:
      gateway: Gateway
      vn: Visualization
      login: UAN # Application nodes that have the non-default prefix "login" are assigned the HSM SubRole "UAN"
    ```

3. __Add Application node aliases__
    The `aliases` field is an map of xnames (strings) to an array of aliases (strings).

    By default, the `csi config init` command does not set the `ExtraProperties.Alias` field for application nodes in the SLS input file. 

    Instead of manually adding the application node alias as described after the system is installed [in this procedure](306-SLS-ADD-UAN-ALIAS.md) the application node aliases can be included when the SLS Input file is built.

    To add additional application node aliases, add a new mapping under the `aliases` field. Where the key is the xname of the application node, and the value is an array of aliases (strings) which allows for one or more aliases to be specified for an application node. 
    ```yaml
    ---
    aliases: # Application Node alias 
      x3113c0s23b0n0: ["gateway-01"]
      x3114c0s23b0n0: ["visualization-02", "vn-02"]
      x3115c0s23b0n0: ["uan-02"] # Added alias for the application node with the xname x3115c0s23b0n0
    ```
