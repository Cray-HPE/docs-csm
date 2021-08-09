## Move a Compute Blade to a Different System

Move an HPE Cray EX liquid-cooled compute blade from one system to another system.

### Prerequisites

- **If the the system in operation**, perform the following tasks on the donor system:
  - Use WLM remove jobs from the affected blade.
  - Determine if the nodes exist in the "in memory" version of the DVS node map.
     *----Dat Le is working on these questions----*
      - If Yes:
         - Add the MAC address of the node that you are installing in the destination system for the DVS node map.
        - Remove the node MAC address from the DVS node map on the donor system. 
     - If No, then ... ? 
    - Are there tasks to manage the Lustre mounts?
  
### Procedure

  This procedure assumes the system is down for maintenance.

#### On the donor system, shutdown software on the nodes

1. Use Boot Orchestration Services (BOS) to shut down the affected nodes on the blade. Specify the appropriate BOS template for the node type.
   
   ```bash
   ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation shutdown --limit x1000c3s0b0n0,x1000c3s0b0n1,x1000c3s0b1n0,x1000c3s0b1n1
   ```
   Specify all the nodes in the blade using a comma separated list. This example shows the command to shut down an EX425 compute blade (Windom) in cabinet 1000, chassis 3, slot 0. This blade type includes two node cards, each with two logical nodes (4 processors).
#### Disable Redfish endpoints for the nodes

2. Temporarily disable endpoint discovery service (MEDS) for the compute nodes(s) being replaced.
   This example disables MEDS for the compute nodes in cabinet 1000, chassis 3, slot 0 (x1000c3s0b0 and x1000c3s0b1). 

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1000c3s0b1
   ```

   Disabling the slot prevents hms-discovery from attempting to automatically power on slots. 

#### Use CAPMC to power off the slot

3. The example uses CAPMC to power off slot 0 in chassis 3.

   ```bash
   ncn-m001# cray capmc xname_off create --xnames x1000c3s0 --recursive true --format json
   ```

   a. If the slot powers off, proceed to step 4.

   b. If the slot automatically powers back on, then suspend the hms-discovery cron job:

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
   ```

   c. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

   ```bash
   ncn-m001# kubectl get cronjobs -n services hms-discovery
   NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
   hms-discovery */3 * * * * True 0 117s 15d
   ```

   d. Repeat the `capmc xname_off` command to power off slot 0 in chassis 3.

#### Disable the slot in the HSM

4. This example disables slot 0 (x1000c3s0) in cabinet 1000, chassis 3.

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x1000c3s0
   ```

#### Delete the Ethernet MAC and Redfish endpoint from donor system HSM

**IMPORTANT**: The HSM stores the node's BMC NIC MAC addresses for the hardware management
network and the node's Ethernet NIC MAC addresses for the node management network. The MAC
addresses for the node NICs must be updated in the DHCP/DNS configuration when a liquid-cooled
blade is replaced. Their entries must be deleted from the HSM Ethernet interfaces table and be rediscovered. The BMC NIC MAC addresses for liquid-cooled blades are assigned algorithmically
and should not be deleted from the HSM.

5. Query HSM to determine the Node NIC MAC addresses associated with the blade in cabinet 1000, chassis 3, slot 0, node card 0, node 0.

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x1000c3s0b0n0 --format json
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
	
   a. Delete each node NIC MAC address from the HSM Ethernet interfaces table.

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2b
   ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2c
   ```

   b. Delete the Redfish endpoint for the removed node.

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints delete x1000c3s0b0
   ```

#### Prepare the destination system

7. Query HSM to determine the if there is an existing node NIC MAC addresses associated with the slot in destination cabinet. For the examples below, the destination is cabinet 1005, chassis 3, slot 0.

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x1005c3s0b0n0 --format json
   ```

   a. Delete each node NIC MAC address the HSM Ethernet interfaces table associated with the destination cabinet slot.

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces delete MAC_ADDRESS
   ncn-m001# cray hsm inventory ethernetInterfaces delete MAC_ADDRESS
   ```

   b. Delete the Redfish endpoint associated with the destination cabinet slot.

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b0
   ```

   Deleting the Redfish endpoint triggers MEDS to act on the blade as if it is new hardware.

#### Replace the hardware

6. Remove the blade hardware from the donor system.  Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

   **CAUTION**: Always power off the chassis slot or device before removal. The best practice is to unlatch and unseat the device while the coolant hoses are still connected, then disconnect the coolant hoses.
   If this is not possible, disconnect the coolant hoses, then quickly unlatch/unseat the device (within 10
   seconds). Failure to do so may damage the equipment.

7. Install the blade hardware in the destination system. Review the *Install a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173*.

#### Power on and boot the compute nodes

8. Verify the the hms-discovery is cronjob not suspended in k8s.

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
   
   ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
   NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE
   hms-discovery */3 * * * * False 1 41s 33d
   
   ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d hms-discovery | grep 
   "Mountain discovery finished" | jq '.discoveredXnames'
   [
   "x1000c3s0b0"
   ]
   ```

9. Wait for 3-5 minutes for the blade to power on and the node BMCs to be discovered.

10. Verify that the affected nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components describe x1005c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

    If discovery fails, the command will return "not found."

#### Verify discovery has completed

11. To verify the BMC(s) have been discovered by the HSM:

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3s0b0 --format json
    	{
    		"ID": "x1005c3s0b0",
    		"Type": "NodeBMC",
    		"Hostname": "x1005c3s0b0",
    		"Domain": "",
    		"FQDN": "x1005c3s0b0",
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
    -  If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    - If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

12. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1000, chassis 3).

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x1005c3
    ```

13. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3
    Type = "ChassisBMC"
    Domain = ""
    MACAddr = "02:13:88:03:00:00"
    Enabled = true
    Hostname = "x1005c3"
    RediscoverOnUpdate = true
    FQDN = "x1005c3"
    User = "root"
    Password = ""
    IPAddress = "10.104.0.76"
    ID = "x1005c3b0"
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2020-09-03T19:03:47.989621Z"
    RedfishVersion = "1.2.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

14. Enable each node individually in the HSM database (in this example, the nodes are `x1005c3s0b0n0-n3`).

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b0n0-n3
    ```

#### Check Firmware

15. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

16. Optional: If necessary, update the firmware. Review the Firmware Action Service (FAS).

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

#### Modify the HSN Network

17. Use fabric manger to update Slingshot fabric.

18. Use the fabric manager to update the System Layout Service. **SEE Slingshot SME**

    a. Dump the existing SLS configuration.

    ```bash
    ncn-m001# cray sls networks describe HSN --format=json > existingHSN.json
    ```

    b. Copy `existingHSN.json` to a `newHSN.json`, edit `newHSN.json` with the changes, then run:

    ```bash
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://API_SYSTEM/apis/sls/v1/networks/HSN -X PUT -d @newHSN.json
    ```

19. Reload DVS on NCNs **- Dat Le**

20. Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation reboot --limit x1000c3s0b0n0,x1000c3s0b0n1,x1000c3s0b1n0,x1000c3s0b1n1
    ```
