# Troubleshoot Issues with Redfish Endpoint Discovery

If a Redfish endpoint is in the `HTTPsGetFailed` status, then the endpoint does not need to be fully rediscovered. The error indicates
an issue in the inventory process done by the Hardware State Manager \(HSM\). Restart the inventory process to fix this issue.

Update the HSM inventory to resolve issues with discovering Redfish endpoints.

## Error Symptom

The following is an example of the HSM error:

```bash
ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0s15b0
```

Example output:

```text
Domain = ""
MACAddr = "b42e993b70ac"
Enabled = true
Hostname = "10.254.2.100"
RediscoverOnUpdate = true
FQDN = "10.254.2.100"
User = "root"
Password = ""
Type = "NodeBMC"
ID = "x3000c0s15b0"

[DiscoveryInfo]
LastDiscoveryAttempt = "2019-11-18T21:34:29.990441Z"
RedfishVersion = "1.1.0"
LastDiscoveryStatus = "HTTPsGetFailed"
```

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.

## Procedure

1. Restart the HSM inventory process.

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames XNAME
    ```

1. Verify that the Redfish endpoint has been rediscovered by HSM.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe XNAME
    ```

    Example output:

    ```text
    Domain = ""
    MACAddr = "b42e993b70ac"
    Enabled = true
    Hostname = "10.254.2.100"
    RediscoverOnUpdate = true
    FQDN = "10.254.2.100"
    User = "root"
    Password = ""
    Type = "NodeBMC"
    ID = "x3000c0s15b0"
    
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2019-11-18T21:34:29.990441Z"
    RedfishVersion = "1.1.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

    Troubleshooting can stop if the discovery status is `DiscoverOK`. Otherwise, proceed to the next step.

1. Re-enable the `RedfishEndpoint` by setting both the `Enabled` and `RediscoverOnUpdate` fields to `true`.

    If `Enabled = false` for the `RedfishEndpoint`, then it may indicate a network or firmware issue with the BMC.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints update BMC_XNAME \
                --enabled true --rediscover-on-update true
    ```

1. Verify that the Redfish endpoint has been rediscovered by HSM.

    Re-enabling the `RedfishEndpoint` will cause a rediscovery to start. Troubleshooting can stop if the discovery status is `DiscoverOK`.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe BMC_XNAME
    ```

    **Troubleshooting:** If discovery is still failing, then use the `curl` command to manually contact the BMC using Redfish.

    ```bash
    ncn-m001# curl -k -u USERNAME:PASSWORD https://BMC_XNAME/redfish/v1/
    ```

    If there is no response from `/redfish/v1/`, then the BMC is either not powered or there is a network issue.

1. Contact other Redfish URLs on the BMC.

    If the response is one of the following, then there is a firmware issue and a BMC restart or update may be needed:

    * An empty response:

        ```bash
        ncn-m001# curl -ku USERNAME:PASSWORD https://BMC_XNAME/redfish/v1/Systems/Node0 | jq .
        ```

        Example output:

        ```text
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
        100  1330  100  1330    0     0   5708      0 --:--:-- --:--:-- --:--:--  5708
        {}
        ```

    * A garbled response:

        ```bash
        ncn-m001# curl -ku USERNAME:PASSWORD https://BMC_XNAME/redfish/v1/Managers/Self
        ```

        Example output:

        ```text
        <pre style="font-size:12px; font-family:monospace; color:#8B0000;">[web.lua] Error in RequestHandler, thread: 0xb60670d8 is dead.
        ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
        .&#47;redfish-handler.lua:0: attempt to index a nil value
        stack traceback:
            .&#47;turbo&#47;httpserver.lua:251: in function &lt;.&#47;turbo&#47;httpserver.lua:212&gt;
            [C]: in function &#39;xpcall&#39;
            .&#47;turbo&#47;iostream.lua:553: in function &lt;.&#47;turbo&#47;iostream.lua:544&gt;
            [C]: in function &#39;xpcall&#39;
            .&#47;turbo&#47;ioloop.lua:573: in function &lt;.&#47;turbo&#47;ioloop.lua:572&gt;
        ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲</pre>
        ```

    * The URLs listed for the Systems do not include `/Systems/` in the URL:

        ```bash
        ncn-m001# curl -ku USERNAME:PASSWORD https://BMC_XNAME/redfish/v1/Systems | jq .
        ```

        Example output:

        ```text
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
        100   421  100   421    0     0   1427      0 --:--:-- --:--:-- --:--:--  1422
        {
          "@odata.context": "/redfish/v1/$metadata#ComputerSystemCollection.ComputerSystemCollection",
          "@odata.etag": "W/\"1604517759\"",
          "@odata.id": "/redfish/v1/Systems",
          "@odata.type": "#ComputerSystemCollection.ComputerSystemCollection",
          "Description": "Collection of Computer Systems",
          "Members": [
            {
              "@odata.id": "/redfish/v1/Node0"
            },
            {
              "@odata.id": "/redfish/v1/Node1"
            }
          ],
          "Members@odata.count": 2,
          "Name": "Systems Collection"
        }
        ```

    * The URL for a system is missing the `SystemID`:

        ```bash
        ncn-m001# curl -ku USERNAME:PASSWORD https://BMC_XNAME/redfish/v1/Systems | jq .
        ```

        Example output:

        ```text
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
        100   421  100   421    0     0   1427      0 --:--:-- --:--:-- --:--:--  1422
        {
          "@odata.context": "/redfish/v1/$metadata#ComputerSystemCollection.ComputerSystemCollection",
          "@odata.etag": "W/\"1604517759\"",
          "@odata.id": "/redfish/v1/Systems",
          "@odata.type": "#ComputerSystemCollection.ComputerSystemCollection",
          "Description": "Collection of Computer Systems",
          "Members": [
            {
              "@odata.id": "/redfish/v1/Systems/"
            }
          ],
          "Members@odata.count": 1,
          "Name": "Systems Collection"
        }
        ```

    **Troubleshooting:** If there was no indication of a firmware issue, then there may be an issue with Vault or the credentials stored in Vault.
