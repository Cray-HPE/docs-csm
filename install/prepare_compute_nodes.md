# Prepare Compute nodes

Some compute nodes types need to have additional procedures performed before
they can be booted, but most compute nodes are ready to be used now.

### Topics:
   1. [Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes](#configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes)

      1. [Gather Information](#gather_information)
      2. [Configure the iLO to use VLAN 4](#configure_ilo)
      3. [Configure the switch port for the iLO to use VLAN 4](#configure_switch_port)
      4. [Clear bad MAC and IP address out of KEA](#cleanup_kea)
      5. [Clear bad ID out of HSM](#cleanup_hsm)

### Prerequisites

The time for Gigabyte compute nodes is synced with the rest of the system.
See [Update the Gigabyte Server BIOS Time](../operations/node_management/Update_the_Gigabyte_Server_BIOS_Time.md).

## Details

<a name="configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes"></a>

### 1. Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes

The HPE Apollo 6500 XL645d Gen10 Plus compute node uses a NIC/shared iLO network
port. The NIC is also referred to as the Embedded LOM (LAN On Motherboard) and
is available to the booted OS. This shared port is plugged into a port on the
TOR Ethernet switch designated for the Hardware Management Network (HMN) causing
the NIC to get an IP address assigned to it from the wrong pool. To prevent this
from happening, the iLO VLAN tag needs to be configured for VLAN 4 and the
switch port the NIC/shared iLO is plugged into needs to be configured to allow
only VLAN 4 traffic. This prevents the NIC from communicating over the switch
and it will no longer DHCP an IP address.

This procedure needs to be done for each of the HPE Apollo 6500 XL645d servers
that will be managed by CSM software. River compute nodes always index their
BMCs from 1. For example, the compute BMCs in servers with more than one node
will have xnames as follows x3000c0s30b1, x3000c0s30b2, x3000c0s30b3, etc...
The node indicator is always a 0. For example, x3000c0s30b1n0 or x3000c0s30b4n0.

   <a name="gather_information"></a>

1. Gather Information

   Example using x3000c0s30b1n0 as the target compute node xname

   ```
   ncn-m001:~ # XNAME=x3000c0s30b1n0
   ncn-m001:~ # cray hsm inventory ethernetInterfaces list --component-id \
         ${XNAME} --format json | jq '.[]|select((.IPAddresses|length)>0)'
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
   }
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
   addresses. The 10.254.x.y address is for the HMN and should not be associated
   with the node itself (x3000c0s30b1n0)

   Make a note of the ID, MACAddress, and IPAddress of the entry that has the
   10.254 address listed.
   ```
   ncn-m001:~ # ID="9440c938f7b4"
   ncn-m001:~ # MAC="94:40:c9:38:f7:b4"
   ncn-m001:~ # IPADDR="10.254.1.38"
   ```
   These will be used later to clean up KEA and Hardware State Manager (HSM).
   There may not be a 10.254 address associated with the node, that is OK, it
   will enable skipping of several steps later on.

   <a name="configure_ilo"></a>

2. Configure the iLO to use VLAN 4
   1. Connect to BMC WebUI and log in with standard root credentials
      1. From the administrators own machine create an SSH tunnel (-L creates
         the tunnel, and -N prevents a shell and stubs the connection):
         ```
         linux# BMC=x3000c0s30b1
         linux# ssh -L 9443:$BMC:443 -N root@example-ncn-m001
         ```
      1. Opening a web browser to `https://localhost:9443` will give access to
         the BMC's web interface.
      1. Login with the root credentials
   2. Click on **iLO Shared Network Port** on left menu
   2. Make a note of the **MAC Address** under the **Information** section,
        that will be needed later.
        ```
        ncn-m001:~ # ILOMAC="<MAC Address>"
        ```
        For example
        ```
        ncn-m001:~ # ILOMAC="94:40:c9:38:08:c7"
        ```
   3. Click on **General** on the top menu
   4. Under **NIC Settings** move slider to **Enable VLAN**
   5. In the **VLAN Tag** box, enter **4**
   6. Click **Apply**
   7. Click **Reset iLO** when it appears
   8.  Click **Yes, Reset** when it appears on the right
   9.  After accepting the BMC restart, connection to the BMC will be lost until
   the switch port reconfiguration is performed.

   <a name="configure_switch_port"></a>

2. Configure the switch port for the iLO to use VLAN 4
   1. Find the port and the switch the iLO is plugged into using the SHCD.
   2. ssh to the switch and log in with standard admin credentials. Refer to
   `/etc/hosts` for exact hostname.
   3. Verify the MAC on the port.

      Example using port number 46.

      ```
      sw-leaf01# show mac-address-table | include 1/1/46
      94:40:c9:38:08:c7    4        dynamic                   1/1/46
      ```

      Make sure the MAC address shown for that port matches the ILOMAC address
      noted in step 2.3 from the **Information** section of the WebUI

      **Note:** If the MAC is not correct, double check the server cabling and
      SHCD for the correct port then start this section over. **Do not** move on
      until the ILOMAC address has been found on the switch at the expected
      port.

   4. Configure the port if the MAC is correct.

      Example using port number 46.

      ```
      sw-leaf01# configure t
      sw-leaf01(config)# int 1/1/46
      sw-leaf01(config-if)# vlan trunk allowed 4
      sw-leaf01(config-if)# write mem
      Copying configuration: [Success]
      sw-leaf01(config-if)# exit
      sw-leaf01(config)# exit
      ```
   5. Verify the settings
      ```
      sw-leaf01# show running-config interface 1/1/46
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
      WebUI will be regained.

   <a name="cleanup_kea"></a>

3. Clear bad MAC and IP address out of KEA

   **Note:** Skip this step if there was no bad MAC and IPADDR found in step 1.

   Retrieve a bearer token if you have not done so already.
   ```
   export TOKEN=$(curl -s -S -d grant_type=client_credentials \
      -d client_id=admin-client \
      -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
   ```

   Remove the entry from KEA that is associated with the MAC and IPADDRESS
   gathered in section 1.1.

   ```
   ncn-m001:~ # curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H \
   "Content-Type: application/json" -d '{"command": "lease4-del", \
   "service": [ "dhcp4" ], "arguments": {"hw-address": "'${MAC}'", \
   "ip-address": "'${IPADDR}'"}}' https://api-gw-service-nmn.local/apis/dhcp-kea
   ```
   Expected results
   ```
   [ { "result": 0, "text": "IPv4 lease deleted." } ]
   ```

   <a name="cleanup_hsm"></a>

4. Clear bad ID out of HSM

   **Note:** Skip this step if there was no bad ID found in step 1.

   Tell HSM to delete the bad ID out of the Ethernet Interfaces table
   ```
   ncn-m001:~ # cray hsm inventory ethernetInterfaces delete $ID
   ```
   Expected results
   ```
   {
   "code": 0,
   "message": "deleted 1 entry"
   }
   ```
Everything is now configured and the CSM software will automatically discover
the node after several minutes. After it has been discovered, the node is ready
to be booted.

<a name="next-topic"></a>

# Next Topic

   After completing the preparation for compute nodes, the CSM product stream
   has been fully installed and configured. Check the next topic.

   See [Next Topic](index.md#next_topic)
