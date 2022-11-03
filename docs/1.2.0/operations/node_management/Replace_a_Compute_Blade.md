# Replace a Compute Blade

Replace an HPE Cray EX liquid-cooled compute blade.

### Shutdown software and power off the blade

1. Temporarily disable endpoint discovery service (MEDS) for the compute nodes(s) being replaced.
   This example disables MEDS for the compute node in cabinet 1000, chassis 3, slot 0 (x1000c3s0b0). If there is more than 1 node card, in the blade specify each node card (x1000c3s0b0,x1000c3s0b1).

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1000c3s0b0
   ```

2. Verify that the workload manager (WLM) is not using the affected nodes.

3. Use Boot Orchestration Services (BOS) to shut down the affected nodes. Specify the appropriate BOS template for the node type.

   ```bash
   ncn-m001# cray bos session create --template-uuid BOS_TEMPLATE \
   --operation shutdown --limit x1000c3s0b0n0,x1000c3s0b0n1,x1000c3s0b1n0,x1000c3s0b1n1
   ```

   Specify all the nodes in the blade using a comma-separated list. This example shows the command to shut down an EX425 compute blade (Windom) in cabinet 1000, chassis 3, slot 5. This blade type includes two node cards, each with two logical nodes (4 processors).

4. Disable the chassis slot in the Hardware State Manager (HSM).

   This example shows cabinet 1000, chassis 3, slot 0 (x1000c3s0).

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x1000c3s0
   ```

   Disabling the slot prevents hms-discovery from attempting to automatically power on slots. If the slot
   automatically powers on after using CAPMC to power the slot off, then temporarily suspend the hms-discovery cron job in k8s:

   1. Suspend the hms-discovery cron job to prevent slot power on.

      ```bash
      ncn-m001# kubectl -n services patch cronjobs hms-discovery \
      -p '{"spec" : {"suspend" : true }}'
      ```

   2. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

      ```bash
      ncn-m001# kubectl get cronjobs -n services hms-discovery
      ```

      Example output:

      ```
      NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
      hms-discovery */3 * * * * True 0 117s 15d
      ```

5. Use CAPMC to power off slot 0 in chassis 3.

   ```bash
   ncn-m001# cray capmc xname_off create --xnames x1000c3s0 \
   --recursive true --format json
   ```

### Delete the HSM entries

6. Delete the node Ethernet interface MAC addresses and the Redfish endpoint from the Hardware State
   Manager (HSM).

   **IMPORTANT**: The HSM stores the node's BMC NIC MAC addresses for the hardware management
   network and the node's Ethernet NIC MAC addresses for the node management network. The MAC
   addresses for the node NICs must be updated in the DHCP/DNS configuration when a liquid-cooled
   blade is replaced. Their entries must be deleted from the HSM Ethernet interfaces table and be rediscovered. The BMC NIC MAC addresses for liquid-cooled blades are assigned algorithmically
   and should not be deleted from the HSM.

   1. Delete the Node NIC MAC addresses from the HSM Ethernet interfaces table.

      Query HSM to determine the Node NIC MAC addresses associated with the blade in cabinet 1000, chassis 3, slot 0, node card 0, node 0.

      ```bash
      ncn-m001# cray hsm inventory ethernetInterfaces list \
      --component-id x1000c3s0b0n0 --format json
      ```

      Example output:

      ```
      	[
      		{
      			"ID": "b42e99be1a2b",
      			"Description": "Ethernet Interface Lan1",
      			"MACAddress": "b4:2e:99:be:1a:2b",
      			"LastUpdate": "2021-01-27T00:07:08.658927Z",
      			"ComponentID": "x1000c3s0b0n0",
      			"Type": "Node",
      			"IPAddresses": [
      			{
      				"IPAddress": "10.252.1.26"
      			}
      			]
      		},
      		{
      			"ID": "b42e99be1a2c",
      			"Description": "Ethernet Interface Lan2",
      			"MACAddress": "b4:2e:99:be:1a:2c",
      			"LastUpdate": "2021-01-26T22:43:10.593193Z",
      			"ComponentID": "x1000c3s0b0n0",
      			"Type": "Node",
      			"IPAddresses": []
      		}
      	]
      ```

      2. Delete each Node NIC MAC address the Hardware State Manager (HSM) Ethernet interfaces table.

         ```bash
         ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2b
         ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2c
         ```

      3. Delete the Redfish endpoint for the removed node.

7. Replace the blade hardware.

   Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions (https://internal.support.hpe.com/).

   **CAUTION**: Always power off the chassis slot or device before removal. The best practice is to unlatch
   and unseat the device while the coolant hoses are still connected, then disconnect the coolant hoses.
   If this is not possible, disconnect the coolant hoses, then quickly unlatch/unseat the device (within 10
   seconds). Failure to do so may damage the equipment.

### Power on and boot the compute nodes

8. Un-suspend the hms-discovery cronjob in k8s.

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'

   ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
   NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE
   hms-discovery */3 * * * * False 1 41s 33d

   ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d hms-discovery | grep "Mountain discovery finished" | jq '.discoveredXnames'
   [
   "x1000c3s0b0"
   ]
   ```

9. Enable MEDS for the compute node(s) in the blade.

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled true --rediscover-on-update true
   ```

   The updated component name(s) (xnames) will be returned.

10. Wait for 3-5 minutes for the blade to power on and the node BMCs to be discovered.

11. Verify that the affected nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components describe x1000c3s0b0n0
    ```

    Example output:

    ```
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

12. To verify the BMC(s) has been discovered by the HSM.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1000c3s0b0 --format json
    ```

    Example output:

    ```
    	{
    		"ID": "x1000c3s0b0",
    		"Type": "NodeBMC",
    		"Hostname": "x1000c3s0b0",
    		"Domain": "",
    		"FQDN": "x1000c3s0b0",
    		"Enabled": true,
    		"UUID": "e005dd6e-debf-0010-e803-b42e99be1a2d",
    		"User": "root",
    		"Password": "",
    		"MACAddr": "b42e99be1a2d",
    		"RediscoverOnUpdate": true,
    		"DiscoveryInfo": {
    			"LastDiscoveryAttempt": "2021-01-29T16:15:37.643327Z",
    			"LastDiscoveryStatus": "DiscoverOK",
    			"RedfishVersion": "1.7.0"
    		}
    	}
    ```

    - When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    - If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    - If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

13. Enable each node individually in the HSM database (in this example, the nodes are `x1000c3s0b0n0-n3`).

14. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1000, chassis 3).

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x1000c3
    ```

15. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1000c3
    ```

    Example output:

    ```
    Type = "ChassisBMC"
    Domain = ""
    MACAddr = "02:13:88:03:00:00"
    Enabled = true
    Hostname = "x1000c3"
    RediscoverOnUpdate = true
    FQDN = "x1000c3"
    User = "root"
    Password = ""
    IPAddress = "10.104.0.76"
    ID = "x1000c3b0"
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2020-09-03T19:03:47.989621Z"
    RedfishVersion = "1.2.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

16. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

17. Optional: If necessary, update the firmware. Review the [Firmware Action Service (FAS)](../firmware/FAS_Admin_Procedures.md) documentation.

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

18. Update the System Layout Service (SLS).

    1. Dump the existing SLS configuration.

       ```bash
       ncn-m001# cray sls networks describe HSN --format=json > existingHSN.json
       ```

    2. Copy `existingHSN.json` to a `newHSN.json`, edit `newHSN.json` with the changes, then run

       ```bash
       ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://API_SYSTEM/apis/sls/v1/networks/HSN \
       -X PUT -d @newHSN.json
       ```

19. Reload DVS on NCNs.

20. Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos session create --template-uuid BOS_TEMPLATE --operation reboot \
    --limit x1000c3s0b0n0,x1000c3s0b0n1,x1000c3s0b1n0,x1000c3s0b1n1
    ```

