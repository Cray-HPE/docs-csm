# HMS Discovery job not creating RedfishEndpoints in Hardware State Manager

There is a known issue with the HMS Discovery cronjob when a BMC does not respond by its IP address for some reason the discovery job will not create a RedfishEndpoint for the BMC in Hardware State Manager (HSM). However, it does update the BMC MAC address in HSM with its xname. The discovery job only creates a new RedfishEndpoints when it encounters an unknown MAC address without a xname associated with it.

This troubleshooting procedure is only applicable for Air Cooled NodeBMCs and RouterBMCs.

## Prerequisites

- Only applicable to an Air Cooled NodeBMC or RouterBMC.

## Symptoms
- The MAC address for the BMC in HSM has an IP and component id.
- The BMC is pingable.
- There is no RedfishEndpoint for the BMC in HSM.

## Check for symptoms
1. Setup an environment variable with to store the xname of the BMC.
    > This should be either the xname for a NodeBMC (`xXcCsSbB`) or RouterBMC (`xXcCrRbB`).
    ```bash
    ncn# export BMC=x3000c0s18b0
    ```

2. Check to see if HSM if the component ID for a BMC has a MAC address and IP associated with it.
    ```bash
    ncn# cray hsm inventory ethernetInterfaces list --component-id $BMC
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

    Now set an environment variable to store the MAC address of the BMC that has an IP address:
    > Make sure to use the normalized MAC address from the `ID` field.
    ```bash
    ncn# export BMC_MAC=54802852b706
    ```

3. Verify that the IP address associated with the MAC address is pingable.
    ```bash
    ncn# ping $BMC
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

4. Verify that No Redfish endpoint for the NodeBMC or RouterBMC is present in HSM.
    ```bash
    ncn# cray hsm inventory redfishEndpoints describe $BMC
    Usage: cray hsm inventory redfishEndpoints describe [OPTIONS] XNAME
    Try 'cray hsm inventory redfishEndpoints describe --help' for help.

    Error: Missing argument 'XNAME'.
    ```

5. If the BMC has a MAC Address with a component ID and does not have a RedfishEndpoint in HSM, then proceed to the next section.

## Solution

Correcting this river redfish endpoint discovery issue can be done by running the `river_rf_endpoint_discovery_fixup.py` script:

```
ncn# /opt/cray/csm/scripts/hms_verification/river_rf_endpoint_discovery_fixup.py
```

The return value of the script is 0 if fixup was successful or no fixup was needed. Otherwise, a non-zero return means that manual intervention may be needed to correct the issue. Continue to the next section if there were failures.

### Script Debugging Steps

1. Check that the hms-discovery cronjob has run to completion since running the script.
    ```bash
    ncn# kubectl -n services get pods -l app=hms-discovery
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

2. Verify that the MAC address has a component ID associated with it.
    ```bash
    ncn# cray hsm inventory ethernetInterfaces describe $BMC_MAC
    ID = "54802852b706"
    Description = ""
    MACAddress = "54:80:28:52:b7:06"
    LastUpdate = "2021-06-28T18:18:15.960235Z"
    ComponentID = "x3000c0s18b0"
    Type = "NodeBMC"
    [[IPAddresses]]
    IPAddress = "10.254.1.27"
    ```

    If `ComponentID` remains empty check the hms-discovery logs for errors. Otherwise, move on to the next step.

3. Verify that a RedfishEndpoint now exists for the BMC.
    > The BMC when first added to HSM may not be DiscoverOK right away. It may take up 5 minutes for BMC hostname to start resolving in DNS. The HMS Discovery cronjob should automatically trigger a discovery for any RedfishEndpoints that are not in the DiscoveryOk or DiscoveryStated states, such as HTTPsGetFailed.
    ```bash
    ncn# cray hsm inventory redfishEndpoints describe $BMC
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
