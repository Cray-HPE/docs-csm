# Enable Nodes

Use the Hardware State Manager \(HSM\) Cray CLI commands to enable nodes on the system.

Enabling nodes that are available provides an accurate system configuration and node map.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Enable one or more nodes with HSM.

    ```bash
    ncn-m001# cray hsm state components bulkEnabled update --enabled true --component-ids XNAME_LIST
    ```

2.  Verify the desired nodes are enabled.

    ```bash
    ncn-m001# cray hsm state components query create --component-ids XNAME_LIST
    ```

    Example output:

    ```
    [[Components]]
    Type = "Node"
    Enabled = true
    State = "On"
    NID = 1003
    Flag = "OK"
    Role = "Compute"
    NetType = "Sling"
    Arch = "X86"
    ID = "x5000c1s0b1n1"

    [[Components]]
    Type = "Node"
    Enabled = true
    State = "On"
    NID = 1004
    Flag = "OK"
    Role = "Compute"
    NetType = "Sling"
    Arch = "X86"
    ID = "x5000c1s0b1n2"
    ```

