# Adding a Liquid-cooled blade to a System

This procedure will add a liquid-cooled blades from an HPE Cray EX system.

## Perquisites
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

-   Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

-   Blade is being added to an existing liquid-cooled cabinet in the system.

-   The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

-   The System Layout Service (SLS) must have the desired HSN configuration.

-   Check the status of the high-speed network (HSN) and record link status before the procedure.

-   Review the following command examples. The commands can be used to capture the required values from the HSM `ethernetInterfaces` table and write the values to a file. The file then can be used to automate subsequent commands in this procedure, for example:

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
    {"xname":"x1000c0s1b0n0","ID":"0040a6836339","MAC":"00:40:a6:83:63:39","IP":"10.100.0.10","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b0n1","ID":"0040a683633a","MAC":"00:40:a6:83:63:3a","IP":"10.100.0.98","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b1n0","ID":"0040a68362e2","MAC":"00:40:a6:83:62:e2","IP":"10.100.0.123","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b1n1","ID":"0040a68362e3","MAC":"00:40:a6:83:62:e3","IP":"10.100.0.122","Desc":"Node Maintenance Network"}
    ```

    To delete an`ethernetInterfaces`  entry using curl:

    ```bash
    ncn-m001# for ID in $(cat x1000c0s1.json | jq -r '.ID'); do cray hsm inventory ethernetInterfaces delete $ID; done
    ```

    To insert an `ethernetInterfaces` entry using curl:

    ```bash
    ncn-m001# while read  PAYLOAD ; do curl -H "Authorization: Bearer $TOKEN" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw "$(echo $PAYLOAD | jq -c '{ComponentID: .xname,Description: .Desc,MACAddress: .MAC,IPAddress: .IP}')";sleep 5;  done < x1000c0s1.json
    ```

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*


## Procedure
1.  Suspend the hms-discovery cron job to disable it.

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    Verify that the hms-discovery cron job has stopped.

    ```bash
    ncn-m001# kubectl get cronjobs -n services hms-discovery
    ```

    Example output. Note the `ACTIVE` = `0` and is `SUSPEND` = `True` in the output indicating the job has been suspended:
    ```
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *     True         0       117s             15d
    ```

2.  Determine if the destination chassis slot is populated. This example is checking slot 0 in chassis 3 of cabinet x1005.
    ```bash
    ncn-m001# cray hsm state components describe x1005c3s0
    ```

    Example output:
    ```
    ID = "x1005c3s0"
    Type = "ComputeModule"
    State = "Empty"
    Flag = "OK"
    Enabled = true
    NetType = "Sling"
    Arch = "X86"
    Class = "Mountain"
    ```

    If the state of the slot is `On` or `Off`, then the chassis slot is populated.
    If the state of the slot is `Empty`, then the chassis slot is not populated.

3.  **Skip this step if the chassis slot is unpopulated**. Verify the chassis slot is powered off.
    ```bash
    ncn-m001# cray capmc get_xname_status create --xnames x1005c3s0
    ```

    Example output:
    ```
    e = 0
    err_msg = ""
    off = [ "x1005c3s0",]
    ```

    If the slot is powered on, then power the chassis slot off.
    ```
    ncn-m001# cray capmc component name (xname)_off create --xnames x1005c3s0 --recursive true
    ```

4.  Install the the blade into the system into the desired location.

5.  Obtain an authentication token to access the API gateway.
    ```bash
    ncn-m001# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                          -d client_id=admin-client \
                          -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                          https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

### Preserve node component name (xname) to IP address mapping
6.  **Skip this step if DVS is operating over the HSN, otherwise proceed with this step.** When DVS is operating over the NMN and a blade is being replaced, the mapping of node component name (xname) to node IP address must be preserved. Kea automatically adds entries to the HSM `ethernetInterfaces` table when DHCP lease is provided (about every 5 minutes). To prevent from Kea from automatically adding MAC entries to the HSM `ethernetInterfaces` table, use the following commands:

    1.  Create an `eth_interfaces` file that contains the interface IDs for the `Node Maintenance Network` entries for the destination blade location. If there has not been a blade previously in the destination location there may not be any Ethernet Interfaces to delete from HSM.

        The `blade_query.sh` script from the perquisites section can help determine the IDs for the HSM Ethernet Interfaces associated with the blade if any. It is expected that if a blade has not been populated in the slot before that no HSM Ethernet Interfaces IDs would be found.

        ```bash
        ncn-m001# cat eth_interfaces
        0040a6836339
        0040a683633a
        0040a68362e2
        0040a68362e3
        ```

    2.  Run the following commands in succession to remove the interfaces if any. Delete the cray-dhcp-kea pod to prevent the interfaces from being re-created.

        ```bash
        ncn-m001# kubectl get pods -Ao wide | grep kea

        ncn-m001# kubectl delete -n services pod CRAY_DHCP_KEA_PODNAME
        ncn-m001# for ETH in $(cat eth_interfaces); do cray hsm inventory ethernetInterfaces delete $ETH --format json ; done
        ```

    3.  **Skip this step if the destination blade location has not been previously populated with a blade** Add the MAC and IP addresses and also the `Node Maintenance Network` description to the interfaces. The ComponentID and IPAddress must be the values recorded from the blade previously in the destination location and the MACAddress must be the value recorded from the blade. These values were recorded if the blade was removed via the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure.

        Values recorded from the blade that was was previously in the slot.
        ```bash
        ComponentID: "x1005c3s0b0n0"
        MACAddress: "00:40:a6:83:63:99"
        IPAddress: "10.10.0.123"
        ```

        ```bash
        ncn-m001# MAC=NEW_BLADE_MAC_ADDRESS
        ncn-m001# IP_ADDRESS=DESTLOCATION_IP_ADDRESS
        ncn-m001# XNAME=DESTLOCATION_XNAME

        ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw "{
            \"Description\": \"Node Maintenance Network\",
            \"MACAddress\": \"$MAC\",
            \"IPAddress\": \"$IP_ADDRESS\",
            \"ComponentID\": \"$XNAME\"
        }"
        ```

        **Note:** Kea may must be restarted when the curl command is issued.
        ```bash
        ncn-m001# kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
        ```

        To change or correct a curl command that has been entered, use a PATCH request, for example:

        ```bash
        ncn-m001# curl -k -H "Authorization: Bearer $TOKEN" -L -X PATCH \
            'https://api-gw-service-nmn.local/apis/smd/hsm/v1/Inventory/EthernetInterfaces/0040a68350a4' -H 'Content-Type: application/json' --data-raw '{"MACAddress":"xx:xx:xx:xx:xx:xx","IPAddress":"10.xxx.xxx.xxx","ComponentID":"XNAME"}'
        ```

    4.  Repeat the preceding command for each node in the blade.

#### Re-enable hms-discovery cron job
7. Rediscover the ChassisBMC (the example shows cabinet 1005, chassis 3). Rediscovering the ChassisBMC will update HSM to become aware of the newly populated slot and allow CAPMC to perform power actions on the slot.

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames x1005c3b0
    ```

8.  Verify that discovery of the ChassisBMC has completed (`LastDiscoveryStatus` = "`DiscoverOK`").

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3b0 --format json
    ```

    Example output:
    ```
    {
        "ID": "x1005c3b0",
        "Type": "ChassisBMC",
        "Hostname": "x1005c3b0",
        "Domain": "",
        "FQDN": "x1005c3b0",
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

9. Unsuspend the hms-discovery cronjob to re-enable the hms-discovery job.

    ```bash
    ncn-m001# kubectl -n services patch cronjobs hms-discovery \
      -p '{"spec" : {"suspend" : false }}'
    ```

    Verify the hms-discovery job has been unsuspended:
    ```bash
    ncn-m001# kubectl get cronjobs.batch -n services hms-discovery
    ```

    Example output. Note the `ACTIVE` = `1` and is `SUSPEND` = `False` in the output indicating the job has been unsuspended:
    ```
    NAME             SCHEDULE      SUSPEND   ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *   False       1      41s              33d
    ```

#### Enable and power on the chassis slot

10. Enable the chassis slot. The example enables slot 0, chassis 3, in cabinet 1005.

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x1005c3s0
    ```

11. Power on the chassis slot. The example powers on slot 0, chassis 3, in cabinet 1005.

    ```bash
    ncn-m001# cray capmc component name (xname)_on create --xnames x1005c3s0 --recursive true
    ```

12. Wait at least 3 minutes for the blade to power on and the node controllers (BMCs) to be discovered.

    ```bash
    ncn-m001# sleep 180
    ```

#### Verify discovery has completed

13. To verify the two Node BMCs in the blade have been discovered by the HSM, run this command for each BMC in the blade (x1005c3s0b0 and x1005c3s0b1).

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x1005c3s0b0 --format json
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

    **Troubleshooting**:
    - If the redfish endpoint does not exist for a BMC verify the following:

        Verify the Node BMC is pingable:
        ```bash
        ncn-m001# ping x1005c3s0b0
        ```

        If the BMC is not pingable, verify the chassis slot has power.
        ```bash
        ncn-m001# cray capmc get_xname_status create --xnames x1005c3s0
        ```

    - If the redfish endpoint is in `HTTPsGetFailed`:

        Verify the Node BMC is pingable:
        ```bash
        ncn-m001# ping x1005c3s0b0
        ```

        If the BMC is pingable, verify the node BMC is configured with expected credentials.
        ```bash
        ncn-m001# curl -k -u root:password https://x1005c3s0b0/redfish/v1/Managers
        ```

14. Enable the nodes in the HSM database.

    For a blade with four nodes per blade:
    ```bash
    ncn-m001# cray hsm state components bulkEnabled update --enabled true --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

    For a blade with two nodes per blade:
    ```bash
    ncn-m001# cray hsm state components bulkEnabled update --enabled true --component-ids x1005c3s0b0n0,x1005c3s0b1n0
    ```

15. Verify that the nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components query create --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
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

Use boot orchestration to power on and boot the nodes. Specify the appropriate BOS template for the node type.

16. Determine how the BOS Session template references compute hosts.
    Typically, they are referenced by their "Compute" role. However, if they are referenced by xname, then these new nodes should added to the BOS Session template.
    
    ```bash
    ncn-m001# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    ncn-m001# cray bos sessiontemplate describe $BOS_TEMPLATE --format json|jq '.boot_sets[] | select(.node_list)'
    ```
    
    If this query returns empty, then skip to sub-step 3.
    If this query returns with data, then one or more boot sets within the BOS Session template reference nodes explicitly by xname. Consider adding your new nodes to this list (sub-step 1) or adding them on the command line (sub-step 2).

    1. Adding new nodes to your list.
       
       1. Dump the current Session template.
          
          ```bash
          ncn-m001# cray bos sessiontemplate describe $BOS_TEMPLATE --format json > tmp.txt
          ```
       
       2. Edit the tmp.txt file adding the new nodes to the node_list.
          
          ```bash
          ncn-m001# vi tmp.txt
          ```

    2. Create the Session template.
       
       1. The name of the Session template is determined by the name provided to the '--name' option on the command line. Use the current value of $BOS_TEMPLATE if you want to overwrite the existing Session template. If you want to use the current value, skip this sub-step and go on to sub-step 2. Otherwise, provide a different name for BOS_TEMPLATE which will be used the '--name' option. The name specified in tmp.txt is overridden by the value provided by the '--name' option.
  	      
          ```bash
          ncn-m001# $BOS_TEMPLATE=<New Session Template name>
          ```

	 3. Create the Session template.
        
        ```bash
        ncn-m001# cray bos sessiontemplate create --file tmp.txt --name $BOS_TEMPLATE
        ```
        
        1. Verify that the Session template contains the additional nodes and the proper name.
           
           ```bash
           ncn-m001# cray bos sessiontemplate describe $BOS_TEMPLATE --format json
           ```

    4. Boot the nodes.
       
       ```bash
       ncn-m001# cray bos session create --template-uuid $BOS_TEMPLATE \
         --operation reboot --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
       ```

#### Check firmware
17. Verify that the correct firmware versions for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.
    1. Review [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) to perform a dry run using FAS to verify firmware versions.

    2. If necessary update firmware with FAS. See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) for more information.
#### Check DVS

There should be a cray-cps pod (the broker), three cray-cps-etcd pods and their waiter, and at least one cray-cps-cm-pm pod. Usually there are two cray-cps-cm-pm pods, one on ncn-w002 and one on ncn-w003 and other worker nodes

18. Check the cray-cps pods on worker nodes and verify they are `Running`.

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

19. SSH to each worker node running CPS/DVS, and run `dmesg -T` to ensure that there are no recurring `"DVS: merge_one" ` error messages as shown. The error messages indicate that DVS is detecting an IP address change for one of the client nodes.

    ```bash
    ncn-m001# dmesg -T | grep "DVS: merge_one"
    ```

    Example output:
    ```
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#351: New node map entry does not match the existing entry
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#353:   nid: 8 -> 8
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#355:   name: 'x3000c0s19b1n0' -> 'x3000c0s19b1n0'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#357:   address: '10.252.0.26@tcp99' -> '10.252.0.33@tcp99'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#358:   Ignoring.
    ```

20. SSH to the node and check each DVS mount.

    ```bash
    nid# mount | grep dvs | head -1
    ```

    Example output:
    ```
    /var/lib/cps-local/0dbb42538e05485de6f433a28c19e200 on /var/opt/cray/gpu/nvidia-squashfs-21.3 type dvs (ro,relatime,blksize=524288,statsfile=/sys/kernel/debug/dvs/mounts/1/stats,attrcache_timeout=14400,cache,nodatasync,noclosesync,retry,failover,userenv,noclusterfs,killprocess,noatomic,nodeferopens,no_distribute_create_ops,no_ro_cache,loadbalance,maxnodes=1,nnodes=6,nomagic,hash_on_nid,hash=modulo,nodefile=/sys/kernel/debug/dvs/mounts/1/nodenames,nodename=x3000c0s6b0n0:x3000c0s5b0n0:x3000c0s4b0n0:x3000c0s9b0n0:x3000c0s8b0n0:x3000c0s7b0n0)
    ```
#### Check the HSN for the affected nodes

21. Determine the pod name for the Slingshot fabric manager pod and check the status of the fabric.

    ```bash
    ncn-m001# kubectl exec -it -n services \
      $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') \
      -- fmn_status
    ```

#### Check for duplicate IP address entries

22. Check for duplicate IP address entries in the Hardware State Management Database (HSM). Duplicate entries will cause DNS operations to fail.

  1.  Verify each node hostname resolves to one IP address.
      ```bash
      ncn-m001# nslookup x1005c3s0b0n0
      ```

      Example output with one IP address resolving:
      ```
      Server:         10.92.100.225
      Address:        10.92.100.225#53

      Name:   x1005c3s0b0n0
      Address: 10.100.0.26
      ```

  2.  Reload the KEA configuration.
      ```bash
      ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-reload",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea |jq
      ```

      If there are no duplicate IP addresses within HSM the following response is expected:
      ```json
      [
        {
          "result": 0,
          "text": "Configuration successful."
        }
      ]
      ```

      If there is a duplicate IP address an error message similar to the message below. This message indicates a duplicate IP address (10.100.0.105) in the HSM:
      ```
      [{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf': failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the address 10.100.0.105: There's already a reservation for this address"}]
      ```

23. Use the following example curl command to check for active DHCP leases. If there are 0 DHCP leases, there is a configuration error.

    ```bash
    ncn-m001# curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
    ```

    Example output with no active DHCP leases:
    ```json
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

24. If there are duplicate entries in the HSM as a result of this procedure, (10.100.0.105 in this example), delete the duplicate entry.

    1. Show the `EthernetInterfaces` for the duplicate IP address:

       ```bash
       ncn-m001# cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
       ```

       Example output for an IP address that is associated with two MAC addresses:
       ```json
       [
         {
           "ID": "0040a68350a4",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:50:a4",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-24T20:24:23.214023Z",
           "ComponentID": "x1005c3s0b0n0",
           "Type": "Node"
         },
         {
           "ID": "0040a683639a",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:63:9a",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-27T19:15:53.697459Z",
           "ComponentID": "x1005c3s0b0n0",
           "Type": "Node"
         }
       ]
       ```

    2. Delete the older entry.

       ```bash
       ncn-m001# cray hsm inventory ethernetInterfaces delete 0040a68350a4
       ```

25. Check DNS using `nslookup`.

    ```bash
    ncn-m001# nslookup 10.100.0.105
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.local.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.local.
    ```

26. Check SSH.

    ```bash
    ncn-m001# ssh x1005c3s0b0n0
    ```

    Example output:
    ```
    The authenticity of host 'x1005c3s0b0n0 (10.100.0.105)' can't be established.
    ECDSA key fingerprint is SHA256:wttHXF5CaJcQGPTIq4zWp0whx3JTwT/tpx1dJNyyXkA.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added 'x1005c3s0b0n0' (ECDSA) to the list of known hosts.
    Last login: Tue Aug 31 10:45:49 2021 from 10.252.1.9
    ```
