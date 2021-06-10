## Verify Node Removal

Use this procedure to verify that a node has been successfully removed from the system.

### Prerequisites 

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system. 
-   This procedure requires the xname of the removed node to be known.

### Limitations

The REDS mapping file is not automatically updated when the system is changed. It must be manually updated.

### Procedure

1.  Ensure that the Redfish endpoint of the removed node's BMC has been disabled.

    -   View the list of Redfish endpoints to verify the removed node's BMC Redfish endpoint has been disabled:

        ```bash
        ncn-m001# cray hsm inventory redfishEndpoints list
        [[RedfishEndpoints]]
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
         
        [RedfishEndpoints.DiscoveryInfo]
        LastDiscoveryAttempt = "2020-04-03T12:37:48.833692Z"
        RedfishVersion = "1.1.0"
        LastDiscoveryStatus = "DiscoverOK"
        ...
        ```

    -   Search the list of Redfish endpoints using the xname of the node's BMC that it was disabled:

        ```bash
        ncn-m001# cray hsm inventory redfishEndpoints list --id NODE_BMC_XNAME
        [[RedfishEndpoints]]
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
         
        [RedfishEndpoints.DiscoveryInfo]
        LastDiscoveryAttempt = "2020-04-03T12:37:48.833692Z"
        RedfishVersion = "1.1.0"
        LastDiscoveryStatus = "DiscoverOK"
        ```

2.  If a River node will not be replaced, update the REDS mapping file. If the System Layout Service \(SLS\) is enabled, update the SLS input file to omit it.



