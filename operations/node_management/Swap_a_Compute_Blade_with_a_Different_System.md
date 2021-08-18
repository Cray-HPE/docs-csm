## Swap a compute blade with a different system

Swap an HPE Cray EX liquid-cooled compute blade from System A to System B.

- The two systems in this example are:

  - System A  - Cray EX TDS cabinet x9000 with a healthy EX425 blade (Windom dual-injection) in chassis 3, slot 0
  - System B - Cray EX cabinet x1005 with a defective EX425 blade (Windom dual-injection) in chassis 3, slot 0 
- Substitute the correct xnames or other parameters in the command examples that follow. 
- All the nodes in the blade must be specified using a comma separated list. For example, EX425 compute blades include two node cards, each with two logical nodes (4 nodes). 
- Blade A x1000c5s5
- Blade B x1000c7s7

### Prerequisites

- Both systems must have the Slingshot fabric configured with the desired topology for both blades
- The SLS has the desired HSN configuration
- The blade that is removed from the System A is installed in the empty slot left by the blade removed from System B and visa-versa.
- Each blade must have the coolant drained and filled to minimize cross-contamination of cooling systems. 
  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199* 
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*

### System A Procedure 

1. Use WLM to drain running jobs from the affected nodes on the blade.
   
2. Use Boot Orchestration Services (BOS) to shut down the affected nodes on the donor blade (in this example, x9000c3s0). Specify the appropriate xname and BOS template for the node type in the following command. 

   ```bash
   ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
   ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
   ```
#### Disable the Redfish endpoints for the nodes

3. Temporarily disable endpoint discovery service (MEDS) for each compute node. Disabling the slot prevents hms-discovery from automatically powering on the slot. 

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
   ```

#### Clear the node controller settings

4. Remove the system specific settings from each node controller on the blade.

   ```bash
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
   
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
   'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```

#### Power off the chassis slot for the blade in System A

5. Suspend the hms-discovery cron job.

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
   ```

   1. Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`). 

   
      ```bash
      ncn-m001# kubectl get cronjobs -n services hms-discovery
      NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
      hms-discovery    */3 * * * *     True         0       117s             15d
      ```
   
   2. Power off slot 0 in chassis 3, cabinet 9000.
   
   
      ```bash
      ncn-m001# cray capmc xname_off create --xnames x9000c3s0 --recursive true
      ```

#### Disable the chassis slot in the hardware state manager (HSM)

6. Disable slot 0 in chassis 3, cabinet 9000.

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x9000c3s0
   ```

#### Record MAC and IP addresses for system A nodes

**IMPORTANT**: Record the node management network (NMN) MAC and IP addresses for each node in the blade (labeled `Node Maintenance Network`).  To prevent disruption in the data virtualization service (DVS), these addresses must be maintained in the HSM when the blade is swapped and discovered. 

The hardware management network MAC and IP addresses are assigned algorithmically and *must not be deleted* from the HSM.

7. Query HSM to determine the ComponentID, MAC, and IP addresses for each node in the blade. 

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n0 --format json
   [
     {
       "ID": "0040a6836339",
       "Description": "Node Maintenance Network",
       "MACAddress": "00:40:a6:83:63:39",
       "LastUpdate": "2021-04-09T21:51:04.662063Z",
       "ComponentID": "x9000c3s0b0n0",
       "Type": "Node",
       "IPAddresses": [
         {
           "IPAddress": "10.100.0.10"
         }
       ]
     }
   ]
   ```
   
   1. Record the following values:
   
      ```bash
      `ComponentID: "x9000c3s0b0n0"`
      `MACAddress: "00:40:a6:83:63:39"`
      `IPAddress: "10.100.0.10"`
      ```
   
   2. Repeat the command to record the ComponentID, MAC, and IP addresses for the `Node Maintenance Network`  the other nodes in the blade.
   
      ```bash
      ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n1 --format json
      ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b1n0 --format json
      ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b1n1 --format json
      ```
   
   3. Delete the NMN MAC and IP addresses each node in the blade from the HSM. *Do not delete the MAC and IP addresses for the node BMC*.
   
      ```bash
      ncn-m001# cray hsm inventory ethernetInterfaces delete 0040a6836339
      ```
      
   4. Repeat the preceding command for each node in the blade.

   5. Delete the Redfish endpoints for each node.
   
      ```bash
      ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b0
      ncn-m001# cray hsm inventory redfishEndpoints delete x9000c3s0b1
      ```

#### Remove the blade from System A

8. Remove the blade from System A.
9. Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems. 
   - Review fill station procedures in *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* (https://internal.support.hpe.com/).
10. Install the blade from System A in a storage rack.  
    - Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

### System B Procedure

11. Use WLM to drain jobs from the affected nodes on the blade.

12. Use BOS to shut down the affected nodes on the blade (in this example, x1005c3s0). 

    ```bash
    ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

#### Disable the Redfish endpoints for the nodes

13. When nodes are `Off`, Temporarily disable endpoint discovery service (MEDS) for the compute nodes(s). 
    Disabling the slot prevents hms-discovery from attempting to automatically power on slots. 
    
    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b0
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b1
    ```

#### Clear the node controller settings

14. Remove system specific settings from each node controller on the blade.

    ```bash
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType": "StatefulReset"}' https://x1005c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset
    
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d '{"ResetType": "StatefulReset"}' https://x1005c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
    ```

#### Power off the chassis slot

15. Suspend the hms-discovery cron job:

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec": {"suspend": true }}'
    ```

16. Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`). 

    ```bash
    ncn-m001# kubectl get cronjobs -n services hms-discovery
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST SCHEDULE    AGE
    hms-discovery    */3 * * * *     True         0       128s             15d
    ```

17. Power off slot 0 in chassis 3 of cabinet 1005.

    ```bash
    ncn-m001# cray capmc xname_off create --xnames x1005c3s0 --recursive true
    ```

#### Disable the chassis slot in the HSM

18. Disable slot 0 in chassis 3, cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled false x1005c3s0
    ```

#### Record the NIC MAC and IP addresses

**IMPORTANT**: Record the ComponentID, MAC, and IP addresses for each node in the blade in System B.  To prevent disruption in the data virtualization service (DVS), these addresses must be maintained in the HSM when the replacement blade is swapped and discovered.    

The hardware management network NIC MAC addresses for liquid-cooled blades are assigned algorithmically and *must not be deleted* from the HSM.

19. Query HSM to determine the ComponentID, MAC, and IP addresses associated with the blade in System B.  

    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces list --component-id XNAME --format json
    [
      {
        "ID": "0040a6836399",
        "Description": "Node Maintenance Network",
        "MACAddress": "00:40:a6:83:63:99",
        "LastUpdate": "2021-04-09T21:51:04.662063Z",
        "ComponentID": "x1005c3s0b0n0",
        "Type": "Node",
        "IPAddresses": [
          {
            "IPAddress": "10.100.0.123"
          }
        ]
      }
    ]
    ```

20. Record the following `Node Maintenance Network` values for each node in the blade.
    
    ```bash
    `ComponentID: "x1005c3s0b0n0"`
    `MACAddress: "00:40:a6:83:63:99"`
    `IPAddress: "10.10.0.123"`
    ```
    
21. Delete the node NIC MAC and IP addresses from the HSM Ethernet interfaces table for each node.

    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces delete 0040a6836399
    ```
    
22. Repeat the preceding command for each node in the blade.

23. Delete the Redfish endpoints for each node.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b0
    ncn-m001# cray hsm inventory redfishEndpoints delete x1005c3s0b1
    ```

#### Swap the blade hardware

24. Remove the blade from System B install it in a storage cart.

25. Install the blade from System A into System B.

#### Bring up the Blade in System B

26. Obtain an authentication token to access the API gateway. In the example below, replace `myuser`, `mypass`, and `shasta` in the cURL command with site-specific values. Note the value of `access_token`. Review [Retrieve an Authentication Token](../security_and_authentication/Retrieve_an_Authentication_Token.md) for more information.

    ```bash
    ncn-w001# curl -s \
    -d grant_type=password \
    -d client_id=shasta \
    -d username=myuser \
    -d password=mypass \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | python -mjson.tool
    
    {
    "access_token": "ey...IA", <<-- Note this value
    "expires_in": 300,
    "not-before-policy": 0,
    "refresh_expires_in": 1800, "refresh_token": "ey...qg", "scope": "profile email",
    "session_state": "10c7d2f7-8921-4652-ad1e-10138ec6fbc3", "token_type": "bearer"
    }
    
    ncn-m001# TOKEN=access_token
    ```

Use the value of `access_token` to make API requests.

27. Add the MAC and IP addresses for `Node Maintenance Network` interfaces to the HSM.

    ```bash
    `ComponentID: "x1005c3s0b0n0"`
    `MACAddress: "00:40:a6:83:63:99"`
    `IPAddress: "10.10.0.123"`  
    ```

    ```bash
    ncn-m001# MAC=MAC_ADDRESS
    ncn-m001# SYSTEMB_IP_ADDRESS=SYS_B_IP_ADDRESS
    ncn-m001# SYSTEMB_XNAME=SYS_B_XNAME
    ```

    ```bash
    ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -L -X POST 'https://api_gw_service.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw '{
            "MACAddress": "$MAC",
            "IPAddress": "$SYSTEMB_IP_ADDRESS",
            "ComponentID": "$SYSTEMB_XNAME"
          }'
    ```

28. Repeat the preceding command for each node in the blade.

#### Enable the Slot and Power on the Slot

29. Enable slot 0 in chassis 3, cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0
    ```

30. Power on slot 0 in chassis 3 of cabinet 1005.

    ```bash
    ncn-m001# cray capmc xname_on create --xnames x1005c3s0 --recursive true --format json
    ```

#### Enable Discovery

31. Verify the hms-discovery cronjob is not suspended in k8s (`ACTIVE` = `1` and `SUSPEND` = `False`). 

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
        
    ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST SCHEDULE    AGE
    hms-discovery    */3 * * * *     False         1       41s             33d
    
    ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d hms-discovery | grep 
    "Mountain discovery finished" | jq '.discoveredXnames'
    [
    "x1005c3s0b0"
    ]
    ```

32. Wait for 3-5 minutes for the blade to power on and the node controllers  (BMCs) to be discovered.

#### Verify discovery has completed

33. To verify the BMC(s) have been discovered by the HSM, run this command for each BMC in the blade.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe XNAME --format json
    {
    	"ID": "x1005c3s0b0",
    	"Type": "NodeBMC",
    	"Hostname": "x1005c3s0b0",
    	"Domain": "",
    	"FQDN": "x1005c3s0b0",
    	"Enabled": true,
    	"User": "root",
    	"Password": "",
    	"MACAddr": "02:03:E8:00:31:00",
    	"RediscoverOnUpdate": true,
    	"DiscoveryInfo": {
    		"LastDiscoveryAttempt": "2021-06-10T18:01:59.920850Z",
    		"LastDiscoveryStatus": "DiscoverOK",
    		"RedfishVersion": "1.2.0"
    	}
    }
    ```

- When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
- If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
- If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
  occurred during the discovery process.

34. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1005, chassis 3).

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x1005c3
    ```

35. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3
    Type = "ChassisBMC"
    Domain = ""
    MACAddr = "02:03:ed:03:00:00"
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

36. Enable each node individually in the HSM database.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b0n0
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b0n1
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b1n0
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0b1n1
    ```

37. Verify that the nodes are enabled in the HSM. This command must be run for each node in the blade.

    ```bash
    ncn-m001# cray hsm state components describe x1005c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

#### Power on and boot the nodes

38. Use boot orchestration to power on and boot the nodes. Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# COS-VERSION=cos-2.0.30-slurm-healthy-compute
    ncn-m001# cray bos session create --template-uuid $COS-VERSION --operation reboot --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

#### Check Firmware

39. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

40. If necessary, update the firmware. Review the [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) and [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) procedure.

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

#### Check DVS

There should be a cray-cps pod (the broker), three cray-cps-etcd pods and their waiter, and at least one cray-cps-cm-pm pod.  Usually there are two cray-cps-cm-pm pods, one on ncn-w002 and one on ncn-w003 and other worker nodes

41. Check the cray-cps pods on worker nodes and verify they are Running.

    ```bash
    # kubectl get pods -Ao wide | grep cps
    services   cray-cps-75cffc4b94-j9qzf    2/2  Running   0   42h 10.40.0.57  ncn-w001 
    services   cray-cps-cm-pm-g6tjx         5/5  Running   21  41h 10.42.0.77  ncn-w003 
    services   cray-cps-cm-pm-kss5k         5/5  Running   21  41h 10.39.0.80  ncn-w002 
    services   cray-cps-etcd-knt45b8sjf     1/1  Running   0   42h 10.42.0.67  ncn-w003 
    services   cray-cps-etcd-n76pmpbl5h     1/1  Running   0   42h 10.39.0.49  ncn-w002 
    services   cray-cps-etcd-qwdn74rxmp     1/1  Running   0   42h 10.40.0.42  ncn-w001 
    services   cray-cps-wait-for-etcd-jb95m 0/1  Completed       
    ```

#### Check the HSN for the affected nodes

42. Switch to the fabric manager pod.

    ```bash
    ncn-m001# container=$(kubectl get pods --all-namespaces | grep slingshot | awk '{print $2}') 
    
    ncn-m001# kubectl exec -it -n services $container -- bash
    
    slingshot-fabric-manager# fmn_status
    ```

#### Bring up the Blade in System A

43. Drain the coolant from the blade removed from system B and fill with fresh coolant to minimize cross-contamination of cooling systems. 
    - Review fill station procedures in *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* (https://internal.support.hpe.com/).

44. Install the blade from System B into System A.  
    - Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

45. Repeat steps 26 through 42 to power on the nodes in System A.
