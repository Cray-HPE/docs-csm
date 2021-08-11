## Swap a compute blade with a different system

Swap an HPE Cray EX liquid-cooled compute blade from one system to another system.

### Prerequisites

- Both systems must have the Slingshot fabric configured with the desired topology for both blades. 
- The blades being swapped must be of the same type and have the same Slingshot NIC mezzanine card topology.
- The SLS is updated with the desired HSN configuration
- The that is blade removed from the donor system is installed in the empty slot left by the blade removed from destination system and visa-versa.

The two systems in this procedure are referred to as:

- The *donor* system compute blade - Cray EX TDS cabinet x9000 EX425 blade (Windom) in chassis 3, slot 0.
- The *destination* system - Cray EX cabinet x1005 an EX425 blade (Windom) in chassis 3, slot 0.

Substitute the correct xnames or other parameters in the command examples that follow. All the nodes in the blade must be specified using a comma separated list. EX425 compute blades include two node cards, each with two logical nodes (4 nodes). 

### Donor System Procedure 

1. Use WLM remove jobs from the affected nodes on the blade.
   
2. Use Boot Orchestration Services (BOS) to shut down the affected nodes on the donor blade (in this example, x9000c3s0). Specify the appropriate xname and BOS template for the node type in the following command. 

   ```bash
   ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
   ```
#### Disable the Redfish endpoints for the nodes

3. Temporarily disable endpoint discovery service (MEDS) for each donor compute node. Disabling the slot prevents hms-discovery from automatically powering on the slot. 

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
   ```

#### Clear the node controller settings

4. Remove the system specific settings from each node controller on the blade.

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

   Alternatively, use Redfish to wipe each node controller in the blade:

   ```bash
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
   
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```

#### Power off the chassis slot

5. Suspend the hms-discovery cron job.

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
   ```

   1. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

   
         ```bash
         ncn-m001# kubectl get cronjobs -n services hms-discovery
         NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
         hms-discovery */3 * * * * True 0 117s 15d
         ```
   
   2. Power off slot 0 in chassis 3, cabinet 9000.
   
   
         ```bash
         ncn-m001# cray capmc xname_off create --xnames x9000c3s0 --recursive true --format json
         ```

#### Disable the chassis slot in the hardware state manager (HSM)

6. Disable slot 0 in chassis 3, cabinet 9000.

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x9000c3s0
   ```

#### Record the node management network NIC addresses

**IMPORTANT**: Record the node management network (NMN) IP and MAC addresses for each node in the blade.  To avoid disruptions in the data virtualization server (DVS), these addresses must be propagated to the destination system during the blade swap. The hardware management network NIC MAC addresses for liquid-cooled blades are assigned algorithmically and *must not be deleted* from the HSM.

7. Query HSM to determine the NMN NIC IP and MAC addresses associated with the blade. (The following command must run 4 times for Windom blades.)

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

   1. Record the following values:

      `ComponentID: "x9000c3s0b0n0"`
      `MACAddress: "b4:2e:99:be:1a:2b"`
      `IPAddress: "10.252.1.26"`

   2. Repeat the preceding command to record the MAC and IP addresses for the other nodes in the blade (x9000c3s0b0n1, 9000c3s0b1n0, 9000c3s0b1n1).

   3. Delete the node IP and MAC addresses from the HSM for each node. (Each Windom node has 2 NICs).

      ```bash
      ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2b
      ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2c
      ```

   4. Delete the Redfish endpoints for each node.

      ```bash
      ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b0
      ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b1
      ```

#### Remove the blade from the Donor System

8. Remove the blade hardware from the donor system.  Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

### Destination System Procedure

9. Use WLM remove jobs from the affected nodes on the blade.

10. Use BOS to shut down the affected nodes on the destination blade (in this example, x1005c3s0). 

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation shutdown --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

#### Disable the Redfish endpoints for the nodes

11. Temporarily disable endpoint discovery service (MEDS) for the compute nodes(s) being replaced. Disabling the slot prevents hms-discovery from attempting to automatically power on slots. 

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b0
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b1
    ```

#### Clear the node controller settings

12. Remove system specific settings from each node controller.

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

    Alternatively, use Redfish to wipe each node controller in the blade:

    ```bash
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x1000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
    
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x1000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
    ```

#### Power off the chassis slot

13. Suspend the hms-discovery cron job:

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```
    1. Verify that the hms-discovery cron job has stopped (ACTIVE column = 0).

       ```bash
       ncn-m001# kubectl get cronjobs -n services hms-discovery
       NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE^M
       hms-discovery */3 * * * * True 0 117s 15d
       ```

    2. Power off slot 0 in chassis 3 of cabinet 1005.

       ```bash
       ncn-m001# cray capmc xname_off create --xnames x1005c3s0 --recursive true --format json
       ```

#### Disable the chassis slot in the HSM

14. Disable slot 0 in chassis 3, cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled false x1005c3s0
    ```

#### Record the node management network NIC addresses

**IMPORTANT**: Record the node management network (NMN) IP and MAC addresses for each node in the blade.  To avoid disruptions in the data virtualization server (DVS), these addresses must be propagated to the donor system during the blade swap. The hardware management network NIC MAC addresses for liquid-cooled blades are assigned algorithmically and *must not be deleted* from the HSM.

15. Query HSM to determine the NMN NIC IP and MAC addresses associated with the blade. The following command must run for each node on a Windom blade (4 times.) 

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

    1. Record the the following values for each node in the blade.
       `ComponentID: "x1005c3s0b0n0"`
       `MACAddress: "b4:fe:99:be:1a:2b"`
       `IPAddress: "10.252.1.32"`  

    2. Delete the node NIC MAC addresses from the HSM Ethernet interfaces table for each node. For example Windom blade, each node has 2 NICs.

       ```bash
       ncn-m001# cray hsm inventory ethernetInterfaces delete b4fe99be1a2b
       ncn-m001# cray hsm inventory ethernetInterfaces delete b4fe99be1a2c
       ```

    3. Delete the Redfish endpoints for the nodes.

       ```bash
       ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b0
       ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b1
       ```

#### Update the IP and MAC addresses for the nodes on destination system

16. Add the NMN IP and MAC addresses recorded from the donor system to the destination system. For Windom blades, there will be four MAC addresses and IP addresses.

    `ComponentID: "x1005c3s0b0n0"`
    `MACAddress: "b4:2e:99:be:1a:2b"`
    `IPAddress: "10.252.1.26"`

    The xname values that should change are the cabinet, chassis, and slot (xXcCsS). The BMC and node values should not be changed (bBnN). This command updates destination system HSM so that the node MAC addresses for the blade being installed will be the same as donor blade.

    ```bash
    ncn-m001# MAC=MAC_ADDRESS
    ncn-m001# DEST_IP_ADDRESS=DESTINATION_IP_ADDRESS
    ncn-m001# DEST_XNAME=DESTINATION_XNAME
    ```

    ```bash
    ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -L -X POST 'https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw '{
            "MACAddress": "$MAC",
            "IPAddress": "$DEST_IP_ADDRESS",
            "ComponentID": "$DEST_XNAME"
          }'
    ```

#### Swap the blade hardware

17. Remove the blade hardware from the destination system and install the blade in the donor system. 

#### Update the IP and MAC addresses for the nodes on donor system

18. Add the NMN MAC and IP addresses recorded from the nodes on destination system to the HSM on the donor system (see Step 16).

19. Install the donor blade in the destination system.

#### Power on and boot the nodes on the donor system

20. Verify the the hms-discovery is cronjob not suspended in k8s.

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    
    ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
    NAME SCHEDULE SUSPEND ACTIVE LAST SCHEDULE AGE
    hms-discovery */3 * * * * False 1 41s 33d
    
    ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d hms-discovery | grep 
    "Mountain discovery finished" | jq '.discoveredXnames'
    [
    "x9000c3s0b0"
    ]
    ```

21. Wait for 3-5 minutes for the blade to power on and the node controllers  (BMCs) to be discovered.

#### Verify discovery has completed

22. To verify the BMC(s) have been discovered by the HSM, run this command for each BMC in the blade.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe XNAME --format json
    	{
    		"ID": "x9000c3s0b0",
    		"Type": "NodeBMC",
    		"Hostname": "x9000c3s0b0",
    		"Domain": "",
    		"FQDN": "x9000c3s0b0",
    		"Enabled": true,
    		"UUID": "e005cc6e-debf-0010-e803-b42e99be1a2d",
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

23. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1005, chassis 3).

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x9000c3
    ```

24. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x9000c3
    Type = "ChassisBMC"
    Domain = ""
    MACAddr = "02:13:88:03:00:00"
    Enabled = true
    Hostname = "x9000c3"
    RediscoverOnUpdate = true
    FQDN = "x9000c3"
    User = "root"
    Password = ""
    IPAddress = "10.104.0.76"
    ID = "x9000c3b0"
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2020-09-03T19:03:47.989621Z"
    RedfishVersion = "1.2.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

25. Enable each node individually in the HSM database (in this example, the nodes are `x9000c3s0b0n0-n3`).

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x9000c3s0b0n0-n3
    ```

26. Verify that the affected nodes are enabled in the HSM. This command must be run for each node in the blade.

    ```bash
    ncn-m001# cray hsm state components describe x9000c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

#### Power on and boot the nodes

26. Use boot orchestration to power on and boot the nodes. Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid COS-VERSION --operation reboot --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
    ```

#### Optional - Check Firmware

25. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

26. If necessary, update the firmware. Review the Firmware Action Service (FAS).

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

#### Check DVS

27. ***To be supplied..***.

#### Check the HSN Network for the affected nodes

28. Switch to the fabric manager pod.

    ```bash
    ncn-m001# container=$(kubectl get pods --all-namespaces | grep slingshot | awk '{print $2}') 
    
    ncn-m001# kubectl exec -it -n services $container -- bash
    
    slingshot-fabric-manager# fmn_status
    ```

#### Power on and boot the nodes in the destination system

28. Repeat steps 20 through 27 to power on the nodes in the destination system.
