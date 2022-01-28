## Verify Node Removal

Use this procedure to verify that a node has been successfully removed from the system.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   This procedure requires the xname of the removed node to be known.

### Procedure

1.  Ensure that the Redfish endpoint of the removed node's BMC has been disabled.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0s19b4
    ```

    Example output:

    ```
    Domain = ""
    MACAddr = "a4bf012b71a9"
    UUID = "61b3843b-9d33-4986-ba03-1b8acd0bfd9c"
    IPAddress = "10.254.2.13"
    RediscoverOnUpdate = true
    Hostname = "10.254.2.13"
    Enabled = false       <<-- The Redfish endpoint has been disabled
    FQDN = "10.254.2.13"
    User = "root"
    Password = ""
    Type = "NodeBMC"
    ID = "x3000c0s19b4"

    [DiscoveryInfo]
    LastDiscoveryAttempt = "2020-04-03T12:37:48.833692Z"
    RedfishVersion = "1.1.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

2.  Ensure that the nodes have been disabled.

    ```bash
    ncn-m001# cray hsm state components describe x3000c0s19b4n0
    ```

    Example output:

    ```
    ID = "x3000c0s19b4n0"
    Type = "Node"
    State = "Off"
    Flag = "OK"
    Enabled = false        <<-- The node has been disabled
    Role = "Compute"
    NID = 1164
    NetType = "Sling"
    Arch = "X86"
    Class = "River"
    ```

3.  If a River node will not be replaced, update SLS to omit it.



