# Prepare Compute nodes

Some compute nodes types have special preparation steps, but most compute nodes are ready to be used now
These nodes have an additional procedure before they can be booted.

### Topics:
   1. [Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes](#configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes)

### Prerequisites

The time for Gigabyte compute nodes is synced with the rest of the system.
See [Update the Gigabyte Server BIOS Time](../operations/node_management/Update_the_Gigabyte_Server_BIOS_Time.md).

## Details

<a name="configure-hpe-apollo-6500-x645d-gen10-plus-compute-nodes"></a>
### 1. Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes

The HPE Apollo 6500 XL645d Gen10 Plus compute node uses a NIC/shared iLO network port. The NIC is
also referred to as the Embedded LOM (LAN On Motherboard) and is available to the booted OS. This
shared port is plugged into a port on the TOR Ethernet switch designated for the
Hardware Management Network (HMN) causing the NIC to get an IP address assigned
to it from the wrong pool. To prevent this from happening, the iLO VLAN tag
needs to be configured for VLAN 4 and the switch port the NIC/shared iLO is
plugged into needs to be configured to allow only VLAN 4 traffic. This prevents
the NIC from communicating over the switch, and it will no longer DHCP an IP
address.

This procedure needs to be done for each HPE Apollo 6500 XL645d node managed by CSM software.

1. Gather Information

   Example using x3000c0s30b0n0 as the target component xname

   ```
   ncn-m001:~ # cray hsm inventory ethernetInterfaces list --component-id \
           x3000c0s30b0n0 | jq '.[]|select((.IPAddresses|length)>0)'
   {
   "ID": "6805cabbc182",
   "Description": "",
   "MACAddress": "68:05:ca:bb:c1:82",
   "LastUpdate": "2021-04-19T22:15:00.523621Z",
   "ComponentID": "x3000c0s30b0n0",
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
   "ComponentID": "x3000c0s30b0n0",
   "Type": "Node",
   "IPAddresses": [
       {
       "IPAddress": "10.254.1.38"
       }
   ]
   }
   ```

   Make a note of the ID, MACAddress, and IPAddress of the entry that has the
   10.254 address listed. Those will be used later to clean up kea and
   Hardware State Manager (HSM). There may not be a 10.254 address list, that
   is fine, continue on to the next step.

   <a name="configure_ilo"></a>

1. Configure the iLO to use VLAN 4
   1. Connect to BMC WebUI and log in with standard root credentials
   1. Click on **iLO Shared Network Port** on left menu
   1. Make a note of the **MAC Address** under the **Information** section,
        that will be needed later.
   1. Click on **General** on the top menu
   1. Under **NIC Settings** move slider to **Enable VLAN**
   1. In the **VLAN Tag** box, enter **4**
   1. Click **Apply**
   1. Click **Reset iLO** when it appears
   1. Click **Yes, Reset** when it appears on the right
   1. After accepting the BMC restart, connection to the BMC will be lost
        until the switch port reconfiguration is performed.

1. Configure the switch port for the iLO to use VLAN 4
   1. Find the port and the switch the iLO is plugged into using the SHCD.
   1. ssh to the switch and log in with standard admin credentials. Refer to
        /etc/hosts for exact hostname.
   1. Verify the MAC on the port.

      Example using port number 46.

      ```
      sw-leaf01# show mac-address-table | include 1/1/46
      94:40:c9:38:08:c7    4        dynamic                   1/1/46
      ```

      Make sure MAC address returned for that port matches the MAC address
      noted in step 2.3 from the **Information** section of the WebUI

      If the MAC is not correct, double check the server cabling and SHCD
      then start this section over.

   1. Configure the port if the MAC is correct.

      Example using port number 46.

      ```
      sw-leaf01# configure t
      sw-leaf01(config)# int 1/1/46
      sw-leaf01(config-if)# vlan trunk allowed 4
      sw-leaf01(config-if)# write mem
      Copying configuration: [Success]
      sw-leaf01(config-if)# exit
      sw-leaf01(config)# exit
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

1. Clear bad MAC and IP address out of kea

   Skip this step if there was no MAC and IP address found in step 1.

   Example using the MAC and IP address from step 1.

   ```
   ncn-m001:~ # curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H \
   "Content-Type: application/json" -d '{"command": "lease4-del", \
   "service": [ "dhcp4" ], "arguments": {"hw-address": "94:40:c9:38:f7:b4", \
   "ip-address": "10.254.1.38"}}' https://api-gw-service-nmn.local/apis/dhcp-kea

   [ { "result": 0, "text": "IPv4 lease deleted." } ]
   ```

1. Clear bad ID out of HSM

   Skip this step if there was no ID found in step 1.

   Example using the ID from step 1.

   ```
   ncn-m001:~ # cray hsm inventory ethernetInterfaces delete 9440c938f7b4
   {
   "code": 0,
   "message": "deleted 1 entry"
   }
   ```

   Everything is now configured and the node is ready to be rebooted.

<a name="next-topic"></a>
# Next Topic

   After completing the preparation for compute management nodes, the CSM product stream has
   been fully installed and configured. Check the next topic.

   See [Next Topic](index.md#next_topic)
