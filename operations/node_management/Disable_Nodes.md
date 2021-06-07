## Disable Nodes

Use the Hardware State Manager \(HSM\) Cray CLI commands to disable nodes on the system.

Disabling nodes that are not configured correctly allows the system to successfully boot.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Disable individual nodes with HSM.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled false XNAME
    ```

2.  Verify the desired nodes are disabled.

    ```bash
    ncn-m001# cray hsm state components describe XNAME
    Type = "Node"
    Enabled = false 
    State = "On"
    NID = 1003
    Flag = "OK"
    Role = "Compute"
    NetType = "Sling"
    Arch = "X86"
    ID = "x5000c1s0b1n1"
    
    ```


After changing the state of nodes, be cautious when powering them on/off. The preferred method for safely powering them on/off is via the Boot Orchestration Service \(BOS\). The Cray Advanced Platform Monitoring and Control \(CAPMC\) service is used to directly control the power for nodes, regardless of the state in HSM. CAPMC does not check if a node is disabled in HSM.


