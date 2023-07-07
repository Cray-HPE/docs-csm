# Prepare Compute Nodes

1. [Configure HPE Apollo 6500 XL645d Gen10 Plus compute nodes](#configure-hpe-apollo-6500-xl645d-gen10-plus-compute-nodes)
   1. [Gather information](#1-gather-information)
   1. [Configure iLO](#2-configure-ilo)
   1. [Configure switch port](#3-configure-switch-port)
   1. [Cleanup Kea](#4-cleanup-kea)
   1. [Cleanup HSM](#5-cleanup-hsm)
   1. [Update BIOS time](#6-update-bios-time)
1. [Next topic](#next-topic)

## Configure HPE Apollo 6500 XL645d Gen10 Plus compute nodes

The HPE Apollo 6500 XL645d Gen10 Plus compute node uses a NIC/shared iLO network
port. The NIC is also referred to as the Embedded LOM (LAN On Motherboard) and
is available to the booted OS. This shared port is plugged into a port on the
TOR Ethernet switch designated for the Hardware Management Network (HMN) causing
the NIC to get an IP address assigned to it from the wrong pool. To prevent this
from happening, the iLO VLAN tag needs to be configured for HMN VLAN and the
switch port the NIC/shared iLO is plugged into needs to be configured to allow
only HMN VLAN traffic. This prevents the NIC from communicating over the switch
and it will no longer DHCP an IP address.

This procedure needs to be done for each of the HPE Apollo 6500 XL645d servers
that will be managed by CSM software. River compute nodes always index their
BMCs from "1." For example, the compute BMCs in servers with more than one node
will have component names (xnames) as follows: `x3000c0s30b1`, `x3000c0s30b2`, `x3000c0s30b3`, and
so
on. The node indicator is always a "0." For example, `x3000c0s30b1n0` or
`x3000c0s30b4n0`.

### 1. Gather information

(`ncn-mw#`) The following is an example using `x3000c0s30b1n0` as the target compute node
component name (xname):

```bash
XNAME=x3000c0s30b1n0
cray hsm inventory ethernetInterfaces list --component-id \
     ${XNAME} --format json | jq '.[]|select((.IPAddresses|length)>0)'
```

Expected output may look like:

```json
{
    "ID": "6805cabbc182",
    "Description": "",
    "MACAddress": "68:05:ca:bb:c1:82",
    "LastUpdate": "2021-04-19T22:15:00.523621Z",
    "ComponentID": "x3000c0s30b1n0",
    "Type": "Node",
    "IPAddresses": [
        {
            "IPAddress": "10.252.1.21"
        }
    ]
},
{
    "ID": "9440c938f7b4",
    "Description": "",
    "MACAddress": "94:40:c9:38:f7:b4",
    "LastUpdate": "2021-05-07T18:37:59.239924Z",
    "ComponentID": "x3000c0s30b1n0",
    "Type": "Node",
    "IPAddresses": [
        {
            "IPAddress": "10.254.1.38"
        }
    ]
}
```

The second entry is the indication that the NIC is receiving incorrect IP
addresses. The `10.254.x.y` address is for the HMN and should not be associated
with the node itself (`x3000c0s30b1n0`).

Make a note of the `ID`, `MACAddress`, and `IPAddress` of the entry that has the
`10.254` address listed.

 ```bash
 ID="9440c938f7b4"
 MAC="94:40:c9:38:f7:b4"
 IPADDR="10.254.1.38"
 ```

These will be used later to clean up Kea and Hardware State Manager (HSM).
There may not be a `10.254` address associated with the node. That is OK; it
will enable skipping several steps later on.

### 2. Configure iLO

Configure the iLO to use HMN VLAN.

1. Connect to the BMC web user interface and log in with standard `root` credentials.

    1. From the administrator's own machine, create an SSH tunnel (`-L` creates
       the tunnel, and `-N` prevents a shell and stubs the connection):

       ```bash
       BMC=x3000c0s30b1
       ssh -L 9443:$BMC:443 -N root@example-ncn-m001
       ```

    1. Opening a web browser to `https://localhost:9443` will give access to
       the BMC's web interface.

    1. Login with the `root` credentials.

1. Click on **iLO Shared Network Port** on left menu.

1. (`ncn#`) Make a note of the `MAC Address` under the **Information** section;
   that will be needed later.

    ```bash
    ILOMAC="<MAC Address>"
    ```

    For example:

    ```bash
    ILOMAC="94:40:c9:38:08:c7"
    ```

1. Click on **General** on the top menu.

1. Under `NIC Settings`, move the slider to `Enable VLAN`.

1. In the `VLAN Tag` box, enter `4`.

1. Click **Apply**.

1. Click **Reset iLO** when it appears.

1. Click **Yes, Reset** when it appears on the right.

1. After accepting the BMC restart, connection to the BMC will be lost until
   the switch port reconfiguration is performed.

### 3. Configure switch port

Configure the switch port for the iLO to use HMN VLAN.

1. Find the port and the switch the iLO is plugged into using the SHCD.

1. SSH to the switch and log in with standard `admin` user credentials. Refer to
   `/etc/hosts` for the exact hostname.

1. (`sw#`) Verify the MAC address on the port.

    Example using port number 46.

    ```console
    show mac-address-table | include 1/1/46
    ```

    Example output:

    ```text
    94:40:c9:38:08:c7    4        dynamic                   1/1/46
    ```

   Make sure that the MAC address shown for that port matches the `ILOMAC` address
   noted previously from the **Information** section of the web user interface.

   > **`NOTE`** If the MAC address is not correct, double check the server cabling and
   SHCD for the correct port then start this section over. **Do not** move on
   until the `ILOMAC` address has been found on the switch at the expected
   port.

1. (`sw#`) Configure the port, if the MAC address is correct.

    Example using port number 46.

    ```console
    configure t
    int 1/1/46
    vlan trunk allowed 4
    write mem
    ```

    The above snippet should output the following:

    ```text
    Copying configuration: [Success]
    ```

    Type exit twice to leave the interface configuration, and the main configuration menu:

    ```console
    exit
    exit
    ```

1. (`sw#`) Verify the settings.

    ```console
    show running-config interface 1/1/46
    ```

    Expect output:

    ```text
    interface 1/1/46
       no shutdown
       mtu 9198
       description dl645d
       no routing
       vlan trunk native 1
       vlan trunk allowed 4
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
    ```

    After a few minutes the switch will be configured and access to the
    web user interface will be regained.

### 4. Cleanup Kea

Clear bad MAC and IP address out of Kea.

 > **`NOTE`** Skip this section if there was no bad MAC address and IP address found in step 1.

1. (`ncn-mw#`) Retrieve an API token, if not done previously.

     ```bash
     export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
         -d client_id=admin-client \
         -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
         https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
     ```

1. (`ncn-mw#`) Remove the entry from Kea that is associated with the MAC address and IP address gathered previously.

     ```bash
     curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H \
         "Content-Type: application/json" -d '{"command": "lease4-del", \
         "service": [ "dhcp4" ], "arguments": {"hw-address": "'${MAC}'", \
         "ip-address": "'${IPADDR}'"}}' https://api-gw-service-nmn.local/apis/dhcp-kea
     ```

     Expected results:

     ```json
     [ { "result": 0, "text": "IPv4 lease deleted." } ]
     ```

#### 5. Cleanup HSM

Clear bad ID out of HSM.

> **`NOTE`** Skip this section if there was no bad ID found in step 1.

(`ncn-mw#`) Tell HSM to delete the bad ID out of the Ethernet interfaces table.

```bash
cray hsm inventory ethernetInterfaces delete $ID
```

Expected results:

```json
{
   "code": 0,
   "message": "deleted 1 entry"
}
```

Everything is now configured and the CSM software will automatically discover
the node after several minutes. After it has been discovered, the node is ready
to be booted.

#### 6. Update BIOS time

The BIOS time for Gigabyte compute nodes must be synced with the rest of the system.
See [Update the Gigabyte Node BIOS Time](../operations/node_management/Update_the_Gigabyte_Node_BIOS_Time.md).

## Next topic

After completing the preparation for compute nodes, the CSM product stream
has been fully installed and configured.

See [Next topic](csm-install/README.md#installation-of-additional-hpe-cray-ex-software-products) for more information on other product
streams to be installed and configured after CSM.
