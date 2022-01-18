

## Swap a Compute Blade with a Different System

Swap an HPE Cray EX liquid-cooled compute blade between two systems.

- The two systems in this example are:

  - Source system - Cray EX TDS cabinet x9000 with a healthy EX425 blade (Windom dual-injection) in chassis 3, slot 0
  - Destination system - Cray EX cabinet x1005 with a defective EX425 blade (Windom dual-injection) in chassis 3, slot 0

- Substitute the correct xnames or other parameters in the command examples that follow.

- All the nodes in the blade must be specified using a comma separated list. For example, EX425 compute blades include two node cards, each with two logical nodes (4 nodes).



### Prerequisites

- The Slingshot fabric must be configured with the desired topology for both blades.

- The System Layout Service (SLS) must have the desired HSN configuration.

- The blade that is removed from the source system must be installed in the empty slot left by the blade removed from destination system and visa-versa.

- Check the status of the high-speed network (HSN) and record link status before the procedure.

- Review the following command examples. The commands can be used to capture the required values from the HSM `ethernetInterfaces` table and write the values to a file. The file then can be used to automate subsequent commands in this procedure, for example:

  ```bash
  ncn-m001# mkdir blade_swap_scripts; cd blade_swap_scripts
  ncn-m001# cat blade_query.sh

  #!/bin/bash
  BLADE=$1
  OUTFILE=$2

  BLADE_DOT=$BLADE.

  cray hsm inventory ethernetInterfaces list --format json | jq -c --arg BLADE "$BLADE_DOT" 'map(select(.ComponentID|test($BLADE))) | map(select(.Description == "Node Maintenance Network")) | .[] | {xname: .ComponentID, ID: .ID,MAC: .MACAddress, IP: .IPAddresses[0].IPAddress,Desc: .Description}' > $OUTFILE
  ```

  ```bash
  ncn-m001# ./blade_query.sh x1000c0s1 x1000c0s1.json
  ncn-m001# cat x1000c0s1.json
  {"xname":"x9000c3s1b0n0","ID":"0040a6836339","MAC":"00:40:a6:83:63:39","IP":"10.100.0.10","Desc":"Node Maintenance Network"}
  {"xname":"x9000c3s1b0n1","ID":"0040a683633a","MAC":"00:40:a6:83:63:3a","IP":"10.100.0.98","Desc":"Node Maintenance Network"}
  {"xname":"x9000c3s1b1n0","ID":"0040a68362e2","MAC":"00:40:a6:83:62:e2","IP":"10.100.0.123","Desc":"Node Maintenance Network"}
  {"xname":"x9000c3s1b1n1","ID":"0040a68362e3","MAC":"00:40:a6:83:62:e3","IP":"10.100.0.122","Desc":"Node Maintenance Network"}
  ```

  To delete an `ethernetInterfaces` entry using curl:

  ```bash
  ncn-m001# for ID in $(cat x9000c3s1.json | jq -r '.ID'); do cray hsm inventory ethernetInterfaces delete $ID; done
  ```

  To insert an `ethernetInterfaces` entry using curl:

  ```bash
  ncn-m001:# while read PAYLOAD ; do curl -H "Authorization: Bearer $MY_TOKEN" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw "$(echo $PAYLOAD | jq -c '{ComponentID: .xname,Description: .Desc,MACAddress: .MAC,IPAddress: .IP}')";sleep 5; done < x9000c3s1.json
  ```

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.

  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*



### Prepare the source system blade for removal

1. Using the work load manager (WLM), drain running jobs from the affected nodes on the blade. Refer to the vendor documentation for the WLM for more information.

2. Use Boot Orchestration Services (BOS) to shut down the affected nodes in the source blade (in this example, x9000c3s0). Specify the appropriate xname and BOS template for the node type in the following command.

   ```bash
   ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
   ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
   ```



#### Disable the Redfish endpoints for the nodes

3. Temporarily disable the Redfish endpoints for each compute node NodeBMC.

   ```bash
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
   ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
   ```



#### Clear the node controller settings

4. Remove the system specific settings from each node controller on the blade.

   ```bash
   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
    'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
    https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset

   ncn-m001# curl -k -u root:PASSWORD -X POST -H \
     'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
     https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```
   Use Ctrl-C to return to the prompt if command does not return.



#### Power off the chassis slot

5. Suspend the hms-discovery cron job.

   ```bash
   ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
   ```

   1. Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`).

      ```bash
      ncn-m001# kubectl get cronjobs -n services hms-discovery
      ```

      Example output:

      ```
      NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
      hms-discovery    */3 * * * *     True         0       117s             15d
      ```

   2. Power off the chassis slot. This examples powers off slot 0, chassis 3, in cabinet 9000.


      ```bash
      ncn-m001# cray capmc xname_off create --xnames x9000c3s0 --recursive true
      ```



#### Disable the chassis slot

6. Disable the chassis slot. Disabling the slot prevents hms-discovery from automatically powering on the slot. This example disables slot 0, chassis 3, in cabinet 9000.

   ```bash
   ncn-m001# cray hsm state components enabled update --enabled false x9000c3s0
   ```



#### Record MAC and IP addresses for nodes

**IMPORTANT**: Record the node management network (NMN) MAC and IP addresses for each node in the blade (labeled `Node Maintenance Network`). To prevent disruption in the data virtualization service (DVS), these addresses must be maintained in the HSM when the blade is swapped and discovered.

The hardware management network MAC and IP addresses are assigned algorithmically and *must not be deleted* from the HSM.

7. Query HSM to determine the ComponentID, MAC, and IP addresses for each node in the blade.
   The prerequisites show an example of how to gather HSM values and store them to a file.

   ```bash
   ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n0 --format json
   ```

   Example output:

   ```
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

   1. Record the following values for the blade:

      ```bash
      `ComponentID: "x9000c3s0b0n0"`
      `MACAddress: "00:40:a6:83:63:39"`
      `IPAddress: "10.100.0.10"`
      ```

   2. Repeat the command to record the ComponentID, MAC, and IP addresses for the `Node Maintenance Network` the other nodes in the blade.

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



#### Remove the blade

8. Remove the blade from the source system.
   - Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).
9. Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems.
   - Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* (https://internal.support.hpe.com/).
10. Install the blade from the source system in a storage rack or leave it on the cart.



### Prepare the blade in the destination system for removal

11. Use WLM to drain jobs from the affected nodes on the blade.

12. Use BOS to shut down the affected nodes in the destination blade (in this example, x1005c3s0).

    ```bash
    ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown \
    --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```



#### Disable the Redfish endpoints for the nodes

13. When nodes are `Off`, temporarily disable endpoint discovery service (MEDS) for the compute nodes(s).
    Disabling chassis slot prevents hms-discovery from attempting to power them back on.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b0
    ncn-m001# cray hsm inventory redfishEndpoints update --enabled false x1005c3s0b1
    ```



#### Clear the node controller settings

14. Remove system specific settings from each node controller on the blade.

    ```bash
    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d \
      '{"ResetType": "StatefulReset"}' \
      https://x1005c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset

    ncn-m001# curl -k -u root:PASSWORD -X POST -H 'Content-Type: application/json' -d \
      '{"ResetType": "StatefulReset"}' \
      https://x1005c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
    ```



#### Power off the chassis slot

15. Suspend the hms-discovery cron job.

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery \
      -p '{"spec": {"suspend": true }}'
    ```

16. Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`).

    ```bash
    ncn-m001# kubectl get cronjobs -n services hms-discovery
    ```

    Example output:

    ```
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST SCHEDULE    AGE
    hms-discovery    */3 * * * *     True         0       128s             15d
    ```

17. Power off the chassis slot. This example powers off slot 0 in chassis 3 of cabinet 1005.

    ```bash
    ncn-m001# cray capmc xname_off create --xnames x1005c3s0 --recursive true
    ```



#### Disable the chassis slot

18. Disable the chassis slot. This example disables slot 0, chassis 3, in cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled false x1005c3s0
    ```



#### Record the NIC MAC and IP addresses

**IMPORTANT**: Record the ComponentID, MAC, and IP addresses for each node in the blade in the destination system. To prevent disruption in the data virtualization service (DVS), these addresses must be maintained in the HSM when the replacement blade is swapped and discovered.

The hardware management network NIC MAC addresses for liquid-cooled blades are assigned algorithmically and *must not be deleted* from the HSM.

19. Query HSM to determine the ComponentID, MAC, and IP addresses associated with nodes in the destination blade. The prerequisites show an example of how to gather HSM values and store them to a file.

    ```bash
    ncn-m001# cray hsm inventory ethernetInterfaces list \
    --component-id XNAME --format json
    ```

    Example output:

    ```
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

21. Delete the node NIC MAC and IP addresses from the HSM `ethernetInterfaces` table for each node.

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

24. Remove the blade from destination system install it in a storage cart.

25. Install the blade from the source system into the destination system.



#### Bring up the blade in the destination system

26. Obtain an authentication token to access the API gateway. In the example below, replace `myuser`, `mypass`, and `shasta` in the cURL command with site-specific values. Note the value of `access_token`. Review [Retrieve an Authentication Token](../security_and_authentication/Retrieve_an_Authentication_Token.md) for more information. The example is a script to secure a token and set it to the variable MY_TOKEN.

    ```bash
    ncn-m001# MY_TOKEN=$(curl -s -d grant_type=password -d client_id=shasta -d \
      username=USERNAME -d password=PASSWORD \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    ncn-m001:# echo $MY_TOKEN
    eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJW . .
    ```

27. Kea automatically adds entries to the HSM `ethernetInterfaces` table when DHCP lease is provided (about every 5 minutes). To prevent from Kea from automatically adding MAC entries to the HSM `ethernetInterfaces` table, use the following commands:

    1. Create an `eth_interfaces` file that contains the interface IDs for the `Node Maintenance Network` entries for the destination system. (When repeating this procedure for the source system, use the interface IDs for the source system.)

       ```bash
       ncn-m001# cat eth_interfaces
       0040a6836339
       0040a683633a
       0040a68362e2
       0040a68362e3
       ```

    2. Run the following commands in succession to remove the interfaces.
       Delete the cray-dhcp-kea pod to prevent the interfaces from being re-created.

       ```bash
       ncn-m001# kubectl get pods -Ao wide | grep kea

       ncn-m001# kubectl delete -n services pod CRAY_DHCP_KEA_PODNAME
       ncn-m001# for ETH in $(cat eth_interfaces); do cray hsm inventory ethernetInterfaces delete $ETH --format json ; done
       ```

28. Add the MAC and IP addresses and also the `Node Maintenance Network` description to the interfaces. The ComponentID and IPAddress must be the values recorded from the destination blade and the MACAddress must be the value recorded from the source blade.

    ```bash
    `ComponentID: "x1005c3s0b0n0"`
    `MACAddress: "00:40:a6:83:63:99"`
    `IPAddress: "10.10.0.123"`
    ```

    ```bash
    ncn-m001# MAC=SOURCESYS_MAC_ADDRESS
    ncn-m001# IP_ADDRESS=DESTSYS_IP_ADDRESS
    ncn-m001# XNAME=DESTSYS_XNAME
    ```

    ```bash
    ncn-m001# curl -H "Authorization: Bearer ${MY_TOKEN}" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw "{
            \"Description\": \"Node Maintenance Network\",
            \"MACAddress\": \"$MAC\",
            \"IPAddress\": \"$IP_ADDRESS\",
            \"ComponentID\": \"$XNAME\"
        }"
    ```

    **Note:**  Kea may must be restarted when the curl command is issued.
    ```bash
    ncn-m001# kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
    ```

    When repeating this procedure for the source system, ComponentID and IPAddress must be the values recorded from the source system, and the MACAddress must be the value recorded from the blade in the destination system.

    ```bash
    ncn-m001# MAC=DESTSYS_MAC_ADDRESS
    ncn-m001# IP_ADDRESS=SOURCESYS_IP_ADDRESS
    ncn-m001# XNAME=SOURCESYS_XNAME
    ```
    To change or correct a curl command that has been entered, use a PATCH request, for example:

    ```bash
    ncn-m001# curl -k -H "Authorization: Bearer $TOKEN" -L -X PATCH \
      'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces/0040a68350a4' -H 'Content-Type: application/json'  --data-raw '{"MACAddress":"xx:xx:xx:xx:xx:xx","IPAddress":"10.xxx.xxx.xxx","ComponentID":"XNAME"}'
    ```

29. Repeat the preceding command for each node in the blade.



#### Enable and power on the chassis slot

30. Enable the chassis slot. The example enables slot 0, chassis 3, in cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0
    ```

31. Power on the chassis slot. The example powers on slot 0, chassis 3, in cabinet 1005.

    ```bash
    ncn-m001# cray capmc xname_on create --xnames x1005c3s0 --recursive true
    ```



#### Enable discovery

32. Verify the hms-discovery cronjob is not suspended in k8s (`ACTIVE` = `1` and `SUSPEND` = `False`).

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery \
      -p '{"spec" : {"suspend" : false }}'

    ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
    NAME             SCHEDULE      SUSPEND   ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *   False       1      41s              33d

    ncn-m001# kubectl get pods -Ao wide | grep hms-discovery

    ncn-m001# kubectl -n services logs hms-discovery-1600117560-5w95d \
      hms-discovery | grep "Mountain discovery finished" | jq '.discoveredXnames'
    [
      "x1005c3s0b0"
    ]
    ```

33. Wait for 3 minutes for the blade to power on and the node controllers (BMCs) to be discovered.

    ```bash
    ncn-m001# sleep 180
    ```



#### Verify discovery has completed

34. To verify the BMC(s) have been discovered by the HSM, run this command for each BMC in the blade.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe XNAME --format json
    ```

    Example output:

    ```
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

35. Optional: To force rediscovery of the components in the chassis (the example shows cabinet 1005, chassis 3).

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x1005c3b0
    ```

36. Optional: Verify that discovery has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3 --format json
    ```

    Example output:

    ```
    {
        "ID": "x1005c3",
        "Type": "ChassisBMC",
        "Hostname": "x1005c3",
        "Domain": "",
        "FQDN": "x1005c3",
        "Enabled": true,
        "User": "root",
        "Password": "",
        "MACAddr": "02:03:ED:03:00:00",
        "RediscoverOnUpdate": true,
        "DiscoveryInfo": {
            "LastDiscoveryAttempt": "2020-09-03T19:03:47.989621Z",
            "LastDiscoveryStatus": "DiscoverOK",
            "RedfishVersion": "1.2.0"
        }
    }
    ```

37. Enable the nodes in the HSM database.

    ```bash
    ncn-m001# cray hsm state components bulkEnabled update --enabled true \
    --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

38. Verify that the nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components query create \
    --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

    Example output:

    ```
    [[Components]]
    ID = x1005c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    [[Components]]
    ID = x1005c3s0b1n1
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```



#### Power on and boot the nodes

39. Use boot orchestration to power on and boot the nodes. Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE \
      --operation reboot --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```



#### Check firmware

40. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

41. If necessary, update the firmware. Review the [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) and [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) procedure.

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```



#### Check DVS

There should be a cray-cps pod (the broker), three cray-cps-etcd pods and their waiter, and at least one cray-cps-cm-pm pod. Usually there are two cray-cps-cm-pm pods, one on ncn-w002 and one on ncn-w003 and other worker nodes

42. Check the cray-cps pods on worker nodes and verify they are `Running`.

    ```bash
    ncn-m001# kubectl get pods -Ao wide | grep cps
    ```

    Example output:

    ```
    services   cray-cps-75cffc4b94-j9qzf    2/2  Running   0   42h 10.40.0.57  ncn-w001
    services   cray-cps-cm-pm-g6tjx         5/5  Running   21  41h 10.42.0.77  ncn-w003
    services   cray-cps-cm-pm-kss5k         5/5  Running   21  41h 10.39.0.80  ncn-w002
    services   cray-cps-etcd-knt45b8sjf     1/1  Running   0   42h 10.42.0.67  ncn-w003
    services   cray-cps-etcd-n76pmpbl5h     1/1  Running   0   42h 10.39.0.49  ncn-w002
    services   cray-cps-etcd-qwdn74rxmp     1/1  Running   0   42h 10.40.0.42  ncn-w001
    services   cray-cps-wait-for-etcd-jb95m 0/1  Completed
    ```

43. SSH to each worker node running CPS/DVS, and run `dmesg -T` to ensure that there are no recurring `"DVS: merge_one" ` error messages as shown. The error messages indicate that DVS is detecting an IP address change for one of the client nodes.

    ```bash
    ncn-m001# dmesg -T | grep "DVS: merge_one"
    ```

    ```
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#351: New node map entry does not match the existing entry
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#353:   nid: 8 -> 8
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#355:   name: 'x3000c0s19b1n0' -> 'x3000c0s19b1n0'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#357:   address: '10.252.0.26@tcp99' -> '10.252.0.33@tcp99'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#358:   Ignoring.
    ```

44. Make sure the Configuration Framework Service (CFS) finished successfully. Review *HPE Cray EX DVS Administration Guide 1.4.1 S-8004*.

45. SSH to the node and check each DVS mount.

    ```bash
    nid001133:~ # mount | grep dvs | head -1
    /var/lib/cps-local/0dbb42538e05485de6f433a28c19e200 on /var/opt/cray/gpu/nvidia-squashfs-21.3 type dvs (ro,relatime,blksize=524288,statsfile=/sys/kernel/debug/dvs/mounts/1/stats,attrcache_timeout=14400,cache,nodatasync,noclosesync,retry,failover,userenv,noclusterfs,killprocess,noatomic,nodeferopens,no_distribute_create_ops,no_ro_cache,loadbalance,maxnodes=1,nnodes=6,nomagic,hash_on_nid,hash=modulo,nodefile=/sys/kernel/debug/dvs/mounts/1/nodenames,nodename=x3000c0s6b0n0:x3000c0s5b0n0:x3000c0s4b0n0:x3000c0s9b0n0:x3000c0s8b0n0:x3000c0s7b0n0)

    nid001133:~ # ls /var/opt/cray/gpu/nvidia-squashfs-21.3
    rootfs
    ```



#### Check the HSN for the affected nodes

46. Determine the pod name for the Slingshot fabric manager pod and check the status of the fabric.

    ```bash
    ncn-m001# kubectl exec -it -n services \
      $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') \
      -- fmn_status
    ```



#### Check DNS

Check for duplicate IP entries in the State Management Database (SMD). Duplicate entries will cause DNS operations to fail.

```bash
ncn-m001# ssh uan01
ssh: Could not resolve hostname uan01: Temporary failure in name resolution
ncn-m001# ssh x3000c0s14b0n0
ssh: Could not resolve hostname x3000c0s14b0n0: Temporary failure in name resolution
ncn-m001# ssh x1000c1s1b0n1
ssh: Could not resolve hostname x1000c1s1b0n1: Temporary failure in name resolution
```

The Kea configuration error will display a message similar to the message below. This message indicates a duplicate IP address (10.100.0.105) in the SMD:

```
Config reload failed
[{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf': failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the address 10.100.0.105: There's already a reservation for this address"}]
ncn-m001#
```

47. Use the following example curl command to check for active DHCP leases. If there are 0 DHCP leases, there is a configuration error.

    ```bash
    ncn-m001# curl -H "Authorization: Bearer ${MY_TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
    [
      {
        "arguments": {
          "leases": []
        },
        "result": 3,
        "text": "0 IPv4 lease(s) found."
      }
    ]
    ```

48. If there are duplicate entries in the SMD as a result of the swap procedure, (10.100.0.105 in this example), delete the duplicate entry.

    1. Show the `EthernetInterfaces` for the duplicate IP address:

       ```bash
       ncn-m001# cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
       ```

       Example output:

       ```
       [
         {
           "ID": "0040a68350a4",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:50:a4",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-24T20:24:23.214023Z",
           "ComponentID": "x1000c7s7b0n1",
           "Type": "Node"
         },
         {
           "ID": "0040a683639a",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:63:9a",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-27T19:15:53.697459Z",
           "ComponentID": "x1000c7s7b0n1",
           "Type": "Node"
         }
       ]
       ```

    2. Delete the older entry.

       ```bash
       ncn-m001# cray hsm inventory ethernetInterfaces delete 0040a68350a4
       ```

49. Check DNS using `dnslookup`.

    ```bash
    ncn-w001# nslookup 10.252.1.29
    29.1.252.10.in-addr.arpa	name = uan01.
    29.1.252.10.in-addr.arpa	name = uan01.local.
    29.1.252.10.in-addr.arpa	name = x3000c0s14b0n0.
    29.1.252.10.in-addr.arpa	name = x3000c0s14b0n0.local.
    29.1.252.10.in-addr.arpa	name = uan01-nmn.
    29.1.252.10.in-addr.arpa	name = uan01-nmn.local.

    ncn-w001# nslookup uan01
    Server:		10.92.100.225
    Address:	10.92.100.225#53

    Name:	uan01
    Address: 10.252.1.29

    ncn-w001# nslookup x3000c0s14b0n0
    Server:		10.92.100.225
    Address:	10.92.100.225#53

    Name:	x3000c0s14b0n0
    Address: 10.252.1.29
    ```

50. Check SSH.

    ```bash
    ncn-m001# ssh x3000c0s14b0n0
    ```

    Example output:

    ```
    The authenticity of host 'x3000c0s14b0n0 (10.252.1.29)' can't be established.
    ECDSA key fingerprint is SHA256:wttHXF5CaJcQGPTIq4zWp0whx3JTwT/tpx1dJNyyXkA.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added 'x3000c0s14b0n0' (ECDSA) to the list of known hosts.
    Last login: Tue Aug 31 10:45:49 2021 from 10.252.1.9
    ```



#### Bring up the blade in the source system

51. To minimize cross-contamination of cooling systems, drain the coolant from the blade removed from destination system and fill with fresh coolant .

- Review the *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* (https://internal.support.hpe.com/).

52. Install the blade from the destination system into source system.

- Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

53. Repeat steps 26 through 50 to power on the nodes in the source system.





