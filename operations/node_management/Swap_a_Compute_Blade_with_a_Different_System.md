## Swap a compute blade with a different system

Move an HPE Cray EX liquid-cooled compute blade from one system to another system.

### Prerequisites

- Both systems must have the Slingshot fabric configured with the desired topology for both blades. 
- The SLS is updated with the desired HSN configuration.

### Procedure

This procedure swaps compute blades while the system is in operation. To organize the procedure, the two liquid-cooled systems are designated as:

- the "donor" system Cray EX TDS cabinet x9000
- the destination system Cray EX cabinet x1005

#### On the donor system, shutdown software on the nodes

1. Use WLM remove jobs from the affected blade.
   
2. Use Boot Orchestration Services (BOS) to shut down the affected nodes on the donor blade (in this example, x9000c3s0). 

   Specify the appropriate xname and BOS template for the node type in the following command. 
   
   ```bash
   ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
   ```
   **NOTE:** The examples show an EX425 compute blade (Windom) in cabinet 9000, chassis 3, slot 0.  Substitute the correct xnames for the donor blade being removed in the command lines below. Specify all the nodes in the blade using a comma separated list. This blade type includes two node cards, each with two logical nodes (4 nodes).
#### Disable Redfish endpoints for the nodes

3. Temporarily disable endpoint discovery service (MEDS) for each donor compute node. Disabling the slot will prevents hms-discovery from automatically powering on the slots. 

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
   ```

#### Clear the Node Controller Settings on the Donor Blade

4. Remove the system specific settings from each node controller on the donor blade.

   ```bash
   ncn-m001# ssh root@x9000c3s0b0 
   x9000c3s0b0# rm -rf /rwfs/*
   x9000c3s0b0# emmc-setup -U
   x9000c3s0b0# rm -rf /nvram/*
   x9000c3s0b0# exit
   
   ncn-m001#  ssh root@x9000c3s0b1 
   x9000c3s0b1# rm -rf /rwfs/*
   x9000c3s0b1# emmc-setup -U
   x9000c3s0b1# rm -rf /nvram/*
   x9000c3s0b1# exit
   ```

   ​	Alternatively, use Redfish:

   ```bash
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
   
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```

#### 

#### Use CAPMC to power off the slot

5. Suspend the hms-discovery cron job:

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
   ```

   a. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

   ```bash
   ncn-m001# kubectl get cronjobs -n services hms-discovery
   NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
   hms-discovery */3 * * * * True 0 117s 15d
   ```

   b. Use CAPMC to power off slot 0 in chassis 3, cabinet 1000.

   ```bash
   ncn-m001# cray capmc xname_off create --xnames x9000c3s0 --recursive true --format json
   ```

#### Disable the slot in the hardware state manager (HSM)

6. This example disables slot 0 in cabinet 9000, chassis 3 (x9000c3s0).

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x9000c3s0
   ```

#### Delete the Ethernet MAC and Redfish endpoint from donor system HSM

**IMPORTANT**: The HSM stores the node's BMC NIC MAC addresses for the hardware management
network and the node's Ethernet NIC MAC addresses for the node management network. The MAC
addresses for the node NICs must be updated in the DHCP/DNS configuration when a liquid-cooled
blade is replaced. Their entries must be deleted from the HSM Ethernet interfaces table and be rediscovered. The BMC NIC MAC addresses for liquid-cooled blades are assigned algorithmically
and *should not be deleted from the HSM.*

Record the the following HSM settings **for each node** in the donor system blade:

- ComponentID: "x9000c3s0b0n0"
- MACAddress: "b4:2e:99:be:1a:2b"
- IPAddress: "10.252.1.26"

5. Query HSM to determine the Node NIC MAC addresses associated with the blade. (The following command must run 4 times for Windom blades.)

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n0 --format json
   [
   	{
			"ID": "b42e99be1a2b",
			"Description": "Ethernet Interface Lan1",
			"MACAddress": "b4:2e:99:be:1a:2b",
			"LastUpdate": "2021-01-27T00:07:08.658927Z",
			"ComponentID": "x9000c3s0b0n0",
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
			"ComponentID": "x9000c3s0b0n0",
			"Type": "Node",
			"IPAddresses": []
		}
	]
	```
	
   a. Repeat the preceding command to record the MAC addresses and IPs for the other nodes in the blade (x9000c3s0b0n1, 9000c3s0b1n0, 9000c3s0b1n1).

   b. Delete the node NIC MAC addresses from the HSM Ethernet interfaces table for every node. (Each Windom node has 2 NICs).
   
   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2b
   ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2c
   ```

   c. Delete the Redfish endpoints for the donor blade nodes.
   
   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b1
   ```

#### Remove the blade from the Donor System

6. Remove the blade hardware from the donor system.  Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).



## Prepare the destination system

This procedure assumes there was a blade in the destination slot previously. 

#### On the destination system, shutdown software on the nodes

7. Use WLM remove jobs from the affected blade.

8. Use Boot Orchestration Services (BOS) to shut down the affected nodes on the destination blade (in this example, x1005c3s0). 

   Specify the appropriate xname and BOS template for the node type in the following command. 

   ```bash
   ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation shutdown --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
   ```

#### Disable Redfish endpoints for the nodes

9. Temporarily disable endpoint discovery service (MEDS) for the compute nodes(s) being replaced.
   This example disables MEDS for the compute nodes in cabinet 1000, chassis 3, slot 0 (x1005c3s0b0 and x1005c3s0b1). 
   
   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b1
   ```
   
   Disabling the slot prevents hms-discovery from attempting to automatically power on slots. 

#### Clear the Node Controller Settings on the Destination Blade

10. Remove system specific settings from each node controller (On a Windom blade: x1005c3s0b0, x1005c3s0b1s).

    ```bash
    ncn-m001#  ssh root@x1005c3s0b0 
    xx1005c3s0b0# rm -rf /rwfs/*
    x1005c3s0b0# emmc-setup -U
    x1005c3s0b0# rm -rf /nvram/*
    x1005c3s0b0# exit
    
    ncn-m001#  ssh root@x1005c3s0b1 
    xx1005c3s0b1# rm -rf /rwfs/*
    x1005c3s0b1# emmc-setup -U
    x1005c3s0b1# rm -rf /nvram/*
    x1005c3s0b1# exit
    ```

    ​	Alternatively, use Redfish:

    ```bash
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x1000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
    
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x1000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
    ```

#### Use CAPMC to power off the destination slot

11. Suspend the hms-discovery cron job:

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    a. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

    ```bash
    ncn-m001# kubectl get cronjobs -n services hms-discovery
    NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
    hms-discovery */3 * * * * True 0 117s 15d
    ```

    b. Power off slot 0 in chassis 3 of cabinet 1005.

    ```bash
    ncn-m001# cray capmc xname_off create --xnames x1005c3s0 --recursive true --format json
    ```

#### Disable the destination slot in the HSM

12. Disables slot 0 in chassis 3 of in cabinet 1005.

```bash
ncn-m001# cray hsm state components enabled update --enabled false x1005c3s0
```

#### Delete the Ethernet MAC and Redfish endpoint from destination system HSM

Record the the following **for each node in the blade.**

- ComponentID: "x1005c3s0b0n0"
- MACAddress: "b4:fe:99:be:1a:2b"
- IPAddress: "10.252.1.32"

13. Query HSM to determine the Node NIC MAC addresses ("ID": "b4fe99be1a2b") associated with the blade. The following command must run 4 times for Windom blades x1005c3s0b0n0, b0n1, b1n0 and b1n1. 

    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces list --component-id XNAME --format json
    [
    	{
    		"ID": "b4fe99be1a2b",
    		"Description": "Ethernet Interface Lan1",
    		"MACAddress": "b4:fe:99:be:1a:2b",
    		"LastUpdate": "2021-01-27T00:07:08.658927Z",
    		"ComponentID": "x1005c3s0b0n0",
    		"Type": "Node",
    		"IPAddresses": [
    		{
    			"IPAddress": "10.252.1.32"
    		}
    		]
    	},
    	{
    		"ID": "b4fe99be1a2c",
    		"Description": "Ethernet Interface Lan2",
    		"MACAddress": "b4:fe:99:be:1a:2c",
    		"LastUpdate": "2021-01-26T22:43:10.593193Z",
    		"ComponentID": "x1005c3s0b0n0",
    		"Type": "Node",
    		"IPAddresses": []
    	}
    ]
    ```

     a.  Delete every node NIC MAC address from the HSM Ethernet interfaces table for each node. For example Windom blade, each node has 2 NICs. 

    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces delete b4fe99be1a2b
    ncn-m001# cray hsm inventory ethernetInterfaces delete b4fe99be1a2c
    ```

    b. Delete the Redfish endpoints for the nodes.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b0
    ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b1
    ```

#### Add the Ethernet MAC addresses to the nodes on destination system

14. Add the MAC addresses recorded from the donor system. For Windom blades, there will be four MAC address that have IP addresses.

- ComponentID: "x1005c3s0b0n0"
- MACAddress: "b4:2e:99:be:1a:2b"
- IPAddress: "10.252.1.26"

  The xname values that should change are the cabinet, chassis, and slot (xXcCsS). The BMC and node values should not be changed (bBnN). This command updates destination system HSM so that the node MAC addresses for the blade being installed will be the same as donor blade.
  
  ```bash
  ncn-m001# MAC=DONOR_MAC
  ncn-m001# DEST_XNAME=DESTINATION_XNAME
  ncn-m001# DEST_IP_ADDRESS=DESTINATION_IP_ADDRESS
  ```
  
  ```bash
  ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -L -X POST 'https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw '{
          "MACAddress": "$MAC",
          "IPAddress": "$DEST_IP_ADDRESS",
          "ComponentID": "$DEST_XNAME"
        }'
  ```

 

#### Swap the blade hardware

15. Remove the blade hardware from the destination system and install the blade in the donor system. 

16. Install the donor blade in the destination system.



***Do we do these commands on both Donor and Destination Systems?***

#### Power on and boot the nodes

17. Verify the the hms-discovery is cronjob not suspended in k8s.

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    
    ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
    NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE
    hms-discovery */3 * * * * False 1 41s 33d
    
    ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d hms-discovery | grep 
    "Mountain discovery finished" | jq '.discoveredXnames'
    [
    "x1005c3s0b0"
    ]
    ```

18. Wait for 3-5 minutes for the blade to power on and the node BMCs to be discovered.

#### Verify discovery has completed

19. To verify the BMC(s) have been discovered by the HSM, run this command for each BMC in the blade.

```bash
ncn-m001# cray hsm inventory redfishEndpoints describe XNAME --format json
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

20. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1005, chassis 3).

```bash
ncn-m001# cray hsm inventory discover create --xnames x1005c3
```

21. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

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

22. Enable each node individually in the HSM database (in this example, the nodes are `x1005c3s0b0n0-n3`).

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b0n0-n3
    ```

23. Verify that the affected nodes are enabled in the HSM. This command must be run for each node in the blade.

    ```bash
    ncn-m001# cray hsm state components describe x1005c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

#### Check Firmware

25. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

26. Optional: If necessary, update the firmware. Review the Firmware Action Service (FAS).

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

#### Update/Check the HSN Network???

27. Use fabric manger to update Slingshot fabric **????**

28. Use the fabric manager to update the System Layout Service **???** **Need Slingshot SME**

    a. Dump the existing SLS configuration.

    ```bash
    ncn-m001# cray sls networks describe HSN --format=json > existingHSN.json
    ```

    b. Copy `existingHSN.json` to a `newHSN.json`, edit `newHSN.json` with the changes, then run:

    ```bash
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://API_SYSTEM/apis/sls/v1/networks/HSN -X PUT -d @newHSN.json
    ```

30. Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation reboot --limit x1000c3s0b0n0,x1000c3s0b0n1,x1000c3s0b1n0,x1000c3s0b1n1
    ```
