# HMS Discovery Job Not Creating RedfishEndpoints In Hardware State Manager

It is a known issue with the HMS Discovery cronjob that when a BMC does not respond by its IP address,
the discovery job will not create a `RedfishEndpoint` for the BMC in Hardware State Manager (HSM). However,
it does update the BMC MAC address in HSM with its component name (xname). The discovery job only creates a
new `RedfishEndpoints` when it encounters an unknown MAC address without a component name (xname) associated with it.

This troubleshooting procedure is only applicable for air-cooled NodeBMCs and RouterBMCs.

## Prerequisites

- Only applicable to an air-cooled NodeBMC or RouterBMC.

## Symptoms

- The MAC address for the BMC in HSM has an IP address and component ID.
- The BMC is pingable.
- There is no `RedfishEndpoint` for the BMC in HSM.

## Check For Symptoms

1. Setup an environment variable with to store the xname of the BMC.

    > This should be either the component name (xname) for a NodeBMC (`xXcCsSbB`) or RouterBMC (`xXcCrRbB`).

    ```console
    ncn# export BMC=x3000c0s18b0
    ```

1. Check to see in HSM if the component ID for a BMC has a MAC address and IP associated with it.

    ```console
    ncn# cray hsm inventory ethernetInterfaces list --component-id $BMC
    ```

    Example output:

    ```text
    [[results]]
    ID = "54802852b706"
    Description = ""
    MACAddress = "54:80:28:52:b7:06"
    LastUpdate = "2021-06-15T14:30:21.195015Z"
    ComponentID = "x3000c0s18b0"
    Type = "NodeBMC"
    [[results.IPAddresses]]
    IPAddress = "10.254.1.27"
    
    
    [[results]]
    ID = "54802852b707"
    Description = "Configuration of this Manager Network Interface"
    MACAddress = "54:80:28:52:b7:07"
    LastUpdate = "2021-06-15T14:37:52.078528Z"
    ComponentID = "x3000c0s18b0"
    Type = "NodeBMC"
    IPAddresses = []
    ```

1. Set an environment variable to store the MAC address of the BMC that has an IP address:

    > Make sure to use the normalized MAC address from the `ID` field.

    ```console
    ncn# export BMC_MAC=54802852b706
    ```

1. Verify that the IP address associated with the MAC address is pingable.

    ```console
    ncn# ping $BMC
    ```

    If it is pingable, then output will look similar to the following:

    ```text
    PING x3000c0s18b0 (10.254.1.27) 56(84) bytes of data.
    64 bytes from x3000c0s18b0 (10.254.1.27): icmp_seq=1 ttl=255 time=0.342 ms
    64 bytes from x3000c0s18b0 (10.254.1.27): icmp_seq=2 ttl=255 time=0.152 ms
    64 bytes from x3000c0s18b0 (10.254.1.27): icmp_seq=3 ttl=255 time=0.205 ms
    64 bytes from x3000c0s18b0 (10.254.1.27): icmp_seq=4 ttl=255 time=0.291 ms
    ^C
    --- x3000c0s18b0 ping statistics ---
    4 packets transmitted, 4 received, 0% packet loss, time 3067ms
    rtt min/avg/max/mdev = 0.152/0.247/0.342/0.075 ms
    ```

1. Verify that no Redfish endpoint for the NodeBMC or RouterBMC is present in HSM.

    ```console
    ncn# cray hsm inventory redfishEndpoints describe $BMC
    ```

    If the endpoint is missing from HMC, then output will look similar to the following:

    ```text
    Usage: cray hsm inventory redfishEndpoints describe [OPTIONS] XNAME
    Try 'cray hsm inventory redfishEndpoints describe --help' for help.
    
    Error: Missing argument 'XNAME'.
    ```

1. If the BMC has a MAC Address with a component ID and does not have a `RedfishEndpoint` in HSM, then proceed to the next section.

## Solution

Correcting this River Redfish endpoint discovery issue can be done by running the `river_rf_endpoint_discovery_fixup.py` script:

```console
ncn# /opt/cray/csm/scripts/hms_verification/river_rf_endpoint_discovery_fixup.py
```

The return value of the script is 0 if the correction was successful or if no correction was needed. A non-zero return value means
that manual intervention may be needed to correct the issue. Continue to the next section if there were failures.

### Script Debugging Steps

1. Check that the `hms-discovery` cronjob has run to completion since running the script.

    ```console
    ncn# kubectl -n services get pods -l app=hms-discovery
    ```

    Example output:

    ```text
    NAME                             READY   STATUS      RESTARTS   AGE
    hms-discovery-1624901400-wsfxv   0/2     Completed   0          28m
    hms-discovery-1624901580-xpsj7   0/2     Completed   0          25m
    hms-discovery-1624901760-tbw6t   0/2     Completed   0          22m
    hms-discovery-1624901940-rxwjk   0/2     Completed   0          19m
    hms-discovery-1624902120-4njrx   0/2     Completed   0          16m
    hms-discovery-1624902300-jcgd8   0/2     Completed   0          13m
    hms-discovery-1624902480-468sx   0/2     Completed   0          10m
    hms-discovery-1624902660-gdkmh   0/2     Completed   0          7m52s
    hms-discovery-1624902840-nlzw2   0/2     Completed   0          4m50s
    hms-discovery-1624903020-qk6ww   0/2     Completed   0          109s
    ```

    If not, wait until it has and then continue to the next step.

1. Verify that the MAC address has a component ID associated with it.

    ```console
    ncn# cray hsm inventory ethernetInterfaces describe $BMC_MAC
    ```

    Example output:

    ```text
    ID = "54802852b706"
    Description = ""
    MACAddress = "54:80:28:52:b7:06"
    LastUpdate = "2021-06-28T18:18:15.960235Z"
    ComponentID = "x3000c0s18b0"
    Type = "NodeBMC"
    [[IPAddresses]]
    IPAddress = "10.254.1.27"
    ```

    If `ComponentID` remains empty, then check the `hms-discovery` logs for errors. Otherwise, move on to the next step.

1. Verify that a `RedfishEndpoint` now exists for the BMC.

    > The BMC when first added to HSM may not be `DiscoverOK` right away. It may take up 5 minutes for BMC hostname
    > to start resolving in DNS. The HMS Discovery cronjob should automatically trigger a discovery for any `RedfishEndpoints`
    > that are not in the `DiscoveryOk` or `DiscoveryStarted` states, such as `HTTPsGetFailed`.

    ```console
    ncn# cray hsm inventory redfishEndpoints describe $BMC
    ```

    Example output:

    ```text
    ID = "x3000c0s18b0"
    Type = "NodeBMC"
    Hostname = "x3000c0s18b0"
    Domain = ""
    FQDN = "x3000c0s18b0"
    Enabled = true
    UUID = "9a856688-e286-54ff-989f-1f8475430231"
    User = "root"
    Password = ""
    MACAddr = "54802852b706"
    RediscoverOnUpdate = true
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2021-06-28T18:26:05.902976Z"
    LastDiscoveryStatus = "DiscoverOK"
    RedfishVersion = "1.6.0"
    ```
