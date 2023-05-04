# Adding a Liquid-cooled Blade to a System

This procedure will add a liquid-cooled blades from an HPE Cray EX system.

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
* Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).
* Blade is being added to an existing liquid-cooled cabinet in the system.
* The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.
* The System Layout Service (SLS) must have the desired HSN configuration.
* Check the status of the high-speed network (HSN) and record link status before the procedure.
* (`ncn#`) Review the following command examples.
  The commands can be used to capture the required values from the HSM `ethernetInterfaces` table and write the values to a file.
  The file then can be used to automate subsequent commands in this procedure, for example:

    ```bash
    mkdir blade_swap_scripts; cd blade_swap_scripts
    cat blade_query.sh
    ```

    Example output:

    ```bash
    #!/bin/bash
    BLADE=$1
    OUTFILE=$2

    BLADE_DOT=$BLADE.

    cray hsm inventory ethernetInterfaces list --format json | jq -c --arg BLADE "$BLADE_DOT" \
        'map(select(.ComponentID|test($BLADE))) | map(select(.Description == "Node Maintenance Network")) | .[] | {xname: .ComponentID, ID: .ID,MAC: .MACAddress, IP: .IPAddresses[0].IPAddress,Desc: .Description}' > $OUTFILE
    ```

    ```bash
    ./blade_query.sh x1000c0s1 x1000c0s1.json
    cat x1000c0s1.json
    ```

    Example output:

    ```json
    {"xname":"x1000c0s1b0n0","ID":"0040a6836339","MAC":"00:40:a6:83:63:39","IP":"10.100.0.10","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b0n1","ID":"0040a683633a","MAC":"00:40:a6:83:63:3a","IP":"10.100.0.98","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b1n0","ID":"0040a68362e2","MAC":"00:40:a6:83:62:e2","IP":"10.100.0.123","Desc":"Node Maintenance Network"}
    {"xname":"x1000c0s1b1n1","ID":"0040a68362e3","MAC":"00:40:a6:83:62:e3","IP":"10.100.0.122","Desc":"Node Maintenance Network"}
    ```

    To delete an`ethernetInterfaces` entry using `curl`:

    ```bash
    for ID in $(cat x1000c0s1.json | jq -r '.ID'); do cray hsm inventory ethernetInterfaces delete $ID; done
    ```

    To insert an `ethernetInterfaces` entry using `curl`:

    ```bash
    while read PAYLOAD ; do
        curl -H "Authorization: Bearer $TOKEN" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces' \
            -H 'Content-Type: application/json' \
            --data-raw "$(echo $PAYLOAD | jq -c '{ComponentID: .xname,Description: .Desc,MACAddress: .MAC,IPAddresses: [{IPAddress: .IP}]}')"
        sleep 5
    done < x1000c0s1.json
    ```

* The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  * Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*.
  * Review the *HPE Cray EX Hand Pump User Guide H-6200*.

## Procedure

1. (`ncn-mw#`) Suspend the `hms-discovery cron job` to disable it.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    Verify that the `hms-discovery cron job` has stopped.

    ```bash
    kubectl get cronjobs -n services hms-discovery
    ```

    Example output. Note the `ACTIVE` = `0` and is `SUSPEND` = `True` in the output indicating the job has been suspended:

    ```text
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *     True         0       117s             15d
    ```

1. (`ncn#`) Determine if the destination chassis slot is populated.

    This example is checking slot 0 in chassis 3 of cabinet `x1005`.

    ```bash
    cray hsm state components describe x1005c3s0 --format toml
    ```

    Example output:

    ```toml
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

1. (`ncn#`) Verify that the chassis slot is powered off.

    **Skip this step if the chassis slot is unpopulated**.

    ```bash
    cray capmc get_xname_status create --xnames x1005c3s0 --format toml
    ```

    Example output:

    ```toml
    e = 0
    err_msg = ""
    off = [ "x1005c3s0",]
    ```

    If the slot is powered on, then power the chassis slot off.

    ```bash
    cray capmc xname_off create --xnames x1005c3s0 --recursive true
    ```

1. Install the blade into the system into the desired location.

1. (`ncn#`) Obtain an authentication token to access the API gateway.

    ```bash
    export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

### Preserve node component name (xname) to IP address mapping

1. (`ncn-mw#`) **Skip this step if DVS is operating over the HSN, otherwise proceed with this step.**

   When DVS is operating over the NMN and a blade is being replaced, the mapping of node component name (xname) to node IP address must be preserved.
   Kea automatically adds entries to the HSM `ethernetInterfaces` table when DHCP lease is provided (about every 5 minutes).
   To prevent from Kea from automatically adding MAC entries to the HSM `ethernetInterfaces` table, use the following commands:

    1. Create an `eth_interfaces` file that contains the interface IDs for the `Node Maintenance Network` entries for the destination blade location.
        If there has not been a blade previously in the destination location there may not be any Ethernet Interfaces to delete from HSM.
        The `blade_query.sh` script from the prerequisites section can help determine the IDs for the HSM Ethernet Interfaces associated with the blade if any.
        It is expected that if a blade has not been populated in the slot before that no HSM Ethernet Interfaces IDs would be found.

        ```bash
        cat eth_interfaces
        ```

        Example output:

        ```text
        0040a6836339
        0040a683633a
        0040a68362e2
        0040a68362e3
        ```

    1. Run the following commands in succession to remove the interfaces if any.

       Delete the `cray-dhcp-kea` pod to prevent the interfaces from being re-created.

        ```bash
        kubectl get pods -Ao wide | grep kea
        kubectl delete -n services pod CRAY_DHCP_KEA_PODNAME
        for ETH in $(cat eth_interfaces); do cray hsm inventory ethernetInterfaces delete $ETH --format json ; done
        ```

    1. **Skip this step if the destination blade location has not been previously populated with a blade.**

       Add the MAC address, IP address, and the `Node Maintenance Network` description to the interfaces.
       The component ID and IP address must be the values recorded from the blade previously in the destination location, and the MAC address must be the value recorded from the blade.
       These values were recorded if the blade was removed via the [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md) procedure.

        Values recorded from the blade that was was previously in the slot.

        ```text
        ComponentID: "x1005c3s0b0n0"
        MACAddress: "00:40:a6:83:63:99"
        IPAddress: "10.10.0.123"
        ```

        ```bash
        MAC=NEW_BLADE_MAC_ADDRESS
        IP_ADDRESS=DESTLOCATION_IP_ADDRESS
        XNAME=DESTLOCATION_XNAME

        curl -H "Authorization: Bearer ${TOKEN}" -L -X POST 'https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces' -H 'Content-Type: application/json' --data-raw "{
            \"Description\": \"Node Maintenance Network\",
            \"MACAddress\": \"$MAC\",
            \"IPAddresses\": [
                {
                    \"IPAddress\": \"$IP_ADDRESS\"
                }
            ],
            \"ComponentID\": \"$XNAME\"
        }"
        ```

        **`NOTE`** Kea may must be restarted when the `curl` command is issued.

        ```bash
        kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
        ```

        To change or correct a curl command that has been entered, use a PATCH request, for example:

        ```bash
        curl -k -H "Authorization: Bearer $TOKEN" -L -X PATCH \
            'https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces/0040a68350a4' -H 'Content-Type: application/json' \
            --data-raw '{"MACAddress":"xx:xx:xx:xx:xx:xx","IPAddresses":[{"IPAddress":"10.xxx.xxx.xxx"}],"ComponentID":"XNAME"}'
        ```

    1. Repeat the preceding command for each node in the blade.

#### Re-enable `hms-discovery` cron job

1. (`ncn#`) Rediscover the `ChassisBMC` (the example shows cabinet 1005, chassis 3).

   Rediscovering the `ChassisBMC` will update HSM to become aware of the newly populated slot and allow CAPMC to perform power actions on the slot.

    ```bash
    cray hsm inventory discover create --xnames x1005c3b0
    ```

1. (`ncn#`) Verify that discovery of the `ChassisBMC` has completed.

    That is, verify that `LastDiscoveryStatus` = `DiscoverOK`.

    ```bash
    cray hsm inventory redfishEndpoints describe x1005c3b0 --format json
    ```

    Example output:

    ```json
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

1. (`ncn-mw#`) Unsuspend the `hms-discovery cronjob` to re-enable the `hms-discovery` job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

1. (`ncn-mw#`) Verify that the `hms-discovery` job has been unsuspended.

    ```bash
    kubectl get cronjobs.batch -n services hms-discovery
    ```

    Example output.

    `ACTIVE` = `1` and `SUSPEND` = `False` in the output indicates that the job has been unsuspended:

    ```text
    NAME             SCHEDULE      SUSPEND   ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *   False       1      41s              33d
    ```

#### Enable and power on the chassis slot

1. (`ncn#`) Enable the chassis slot.

    The example enables slot 0, chassis 3, in cabinet 1005.

    ```bash
    cray hsm state components enabled update --enabled true x1005c3s0
    ```

1. (`ncn#`) Power on the chassis slot.

    The example powers on slot 0, chassis 3, in cabinet 1005.

    ```bash
    cray capmc xname_on create --xnames x1005c3s0 --recursive true
    ```

1. Wait at least three minutes for the blade to power on and the node controllers (BMCs) to be discovered.

#### Verify that discovery has completed

1. (`ncn#`) Verify that the two node BMCs in the blade have been discovered by the HSM.

    Run this command for each BMC in the blade (`x1005c3s0b0` and `x1005c3s0b1` in this example):

    ```bash
    cray hsm inventory redfishEndpoints describe x1005c3s0b0 --format json
    ```

    Example output:

    ```json
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

    * When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    * If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    * If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

    **Troubleshooting**:

    * If the Redfish endpoint does not exist for a BMC, then verify the following:

        1. (`ncn#`) Verify that the node BMC is pingable:

            ```bash
            ping x1005c3s0b0
            ```

        1. (`ncn#`) If the BMC is not pingable, then verify that the chassis slot has power.

            ```bash
            cray capmc get_xname_status create --xnames x1005c3s0
            ```

    * If the Redfish endpoint is in `HTTPsGetFailed`:

        1. (`ncn#`) Verify that the node BMC is pingable:

            ```bash
            ping x1005c3s0b0
            ```

        1. (`ncn#`) If the BMC is pingable, then verify that the node BMC is configured with the expected credentials.

            ```bash
            curl -k -u root:password https://x1005c3s0b0/redfish/v1/Managers
            ```

1. (`ncn#`) Clear out the existing Redfish event subscriptions from the BMCs on the blade.

    1. Set the environment variable `SLOT` to the blade's location.

        ```bash
        SLOT="x1005c3s0"
        ```

    1. Clear the Redfish event subscriptions.

        ```bash
        for BMC in $(cray hsm inventory  redfishEndpoints list --type NodeBMC --format json | jq .RedfishEndpoints[].ID -r | grep ${SLOT}); do
            /usr/share/doc/csm/scripts/operations/node_management/delete_bmc_subscriptions.py $BMC
        done
        ```

        Each BMC on the blade will have output like the following:

        ```text
        Clearing subscriptions from NodeBMC x3000c0s9b0
        Retrieving BMC credentials from SCSD
        Retrieving Redfish Event subscriptions from the BMC: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions
        Deleting event subscription: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
        Successfully deleted https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
        ```

1. (`ncn#`) Enable the nodes in the HSM database.

    For a blade with four nodes per blade:

    ```bash
    cray hsm state components bulkEnabled update --enabled true --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
    ```

    For a blade with two nodes per blade:

    ```bash
    cray hsm state components bulkEnabled update --enabled true --component-ids x1005c3s0b0n0,x1005c3s0b1n0
    ```

1. Verify that the nodes are enabled in the HSM.

    ```bash
    cray hsm state components query create --component-ids x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1 --format toml
    ```

    Partial example output:

    ```toml
    [[Components]]
    ID = x1005c3s0b0n0
    Type = "Node"
    Enabled = true
    State = "Off"

    [[Components]]
    ID = x1005c3s0b1n1
    Type = "Node"
    Enabled = true
    State = "Off"
    ```

#### Power on and boot the nodes

Use boot orchestration to power on and boot the nodes. Specify the appropriate BOS template for the node type.

1. (`ncn#`) Determine how the BOS Session template references compute hosts.

    Typically, they are referenced by their `Compute` role.
    However, if they are referenced by component name (xname), then these new nodes should added to the BOS Session template.

    ```bash
    BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    cray bos v1 sessiontemplate describe $BOS_TEMPLATE --format json|jq '.boot_sets[] | select(.node_list)'
    ```

    * If this query returns empty, then skip to booting the nodes.
    * If this query returns with data, then one or more boot sets within the BOS Session template
      reference nodes explicitly by xname. Consider adding the new nodes to this list (sub-step 1) or adding them on the command line (sub-step 2).

    1. (`ncn#`) Add new nodes to the list.

       1. Dump the current Session template.

          ```bash
          cray bos v1 sessiontemplate describe $BOS_TEMPLATE --format json > tmp.txt
          ```

       1. Edit the `tmp.txt` file, adding the new nodes to the `node_list`.

    1. (`ncn#`) Create the Session template.

       1. Set the name of the template.

          The name of the Session template is determined by the name provided to the `--name` option on the command line.
          Use the current value of `$BOS_TEMPLATE` if wanting to overwrite the existing Session template.
          If wanting to use the current value, then skip this sub-step.
          Otherwise, provide a different name for `BOS_TEMPLATE` which will be used the `--name` option.
          The name specified in `tmp.txt` is overridden by the value provided to the `--name` option.

          ```bash
          BOS_TEMPLATE="New-Session-Template-Name"
          ```

       1. Create the Session template.

          ```bash
          cray bos v1 sessiontemplate create --file tmp.txt --name $BOS_TEMPLATE
          ```

       1. Verify that the Session template contains the additional nodes and the proper name.

           ```bash
           cray bos v1 sessiontemplate describe $BOS_TEMPLATE --format json
           ```

    1. (`ncn#`) Boot the nodes.

       ```bash
       cray bos v1 session create --template-uuid $BOS_TEMPLATE \
            --operation reboot --limit x1005c3s0b0n0,x1005c3s0b0n1,x1005c3s0b1n0,x1005c3s0b1n1
       ```

#### Check Firmware

1. Verify that the correct firmware versions are present for node BIOS, node controller (nC), NIC mezzanine card (NMC), GPUs, and so on.

    1. Review [FAS Admin Procedures](../firmware/FAS_Admin_Procedures.md) to perform a dry run using FAS to verify firmware versions.

    1. If necessary update firmware with FAS. See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) for more information.

#### Check DVS

There should be a `cray-cps` pod (the broker), three `cray-cps-etcd` pods and their waiter, and at least one `cray-cps-cm-pm` pod.
Usually there are two `cray-cps-cm-pm` pods, one on `ncn-w002` and one on `ncn-w003` and other worker nodes.

1. (`ncn-mw#`) Verify that the `cray-cps` pods on worker nodes are `Running`.

    ```bash
    kubectl get pods -Ao wide | grep cps
    ```

    Example output:

    ```text
    services   cray-cps-75cffc4b94-j9qzf    2/2  Running   0   42h 10.40.0.57  ncn-w001
    services   cray-cps-cm-pm-g6tjx         5/5  Running   21  41h 10.42.0.77  ncn-w003
    services   cray-cps-cm-pm-kss5k         5/5  Running   21  41h 10.39.0.80  ncn-w002
    services   cray-cps-etcd-knt45b8sjf     1/1  Running   0   42h 10.42.0.67  ncn-w003
    services   cray-cps-etcd-n76pmpbl5h     1/1  Running   0   42h 10.39.0.49  ncn-w002
    services   cray-cps-etcd-qwdn74rxmp     1/1  Running   0   42h 10.40.0.42  ncn-w001
    services   cray-cps-wait-for-etcd-jb95m 0/1  Completed
    ```

1. (`ncn-w#`) SSH to each worker node running CPS/DVS, and run ensure that there are no recurring `"DVS: merge_one"` error messages as shown.

    The error messages indicate that DVS is detecting an IP address change for one of the client nodes.

    ```bash
    dmesg -T | grep "DVS: merge_one"
    ```

    Example output:

    ```text
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#351: New node map entry does not match the existing entry
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#353:   nid: 8 -> 8
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#355:   name: 'x3000c0s19b1n0' -> 'x3000c0s19b1n0'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#357:   address: '10.252.0.26@tcp99' -> '10.252.0.33@tcp99'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#358:   Ignoring.
    ```

1. (`ncn-mw#`) **If the `"DVS: merge_one"` error messages is shown**, then the IP address of the node needs to be corrected. This will prevent the need to reload DVS.

    1. Set the following environment variables based on the output collected in the previous step.

        ```bash
        NODE_XNAME=x3000c0s19b1n0
        CURRENT_IP_ADDRESS=10.252.0.33
        DESIRED_IP_ADDRESS=10.252.0.26
        ```

    1. Determine the HSM EthernetInterface entry holding onto the desired IP address.

        ```bash
        cray hsm inventory ethernetInterfaces list --ip-address "${DESIRED_IP_ADDRESS}" --output toml
        ```

        * **If no EthernetInterfaces are found**, then continue on to the next step.

            Example output:

            ```bash
            results = []
            ```

        * **If an EthernetInterface is found**, then it needs to be removed from HSM.

            Example output:

            ```toml
            [[results]]
            ID = "b42e99dfecf0"
            Description = "Ethernet Interface Lan2"
            MACAddress = "b4:2e:99:df:ec:f0"
            LastUpdate = "2022-08-08T10:10:57.527819Z"
            ComponentID = "x3000c0s17b2n0"
            Type = "Node"
            [[results.IPAddresses]]
            IPAddress = "10.252.1.26"
            ```

            1. Record the returned `ID` value into the `EI_ID` environment variable.

                ```bash
                OLD_EI_ID=b42e99dfecf0
                ```

            1. Delete the EthernetInterfaces from HSM.

                ```bash
                cray hsm inventory ethernetInterfaces delete ${OLD_EI_ID}
                ```

    1. Determine the HSM EthernetInterface entry holding onto the current IP address.

        ```bash
        cray hsm inventory ethernetInterfaces list --component-id "${NODE_XNAME}" --ip-address "${CURRENT_IP_ADDRESS}" --output toml
        ```

        Example output:

        ```toml
        [[results]]
        ID = "b42e99dff35f"
        Description = "Ethernet Interface Lan1"
        MACAddress = "b4:2e:99:df:f3:5f"
        LastUpdate = "2022-08-18T16:38:21.13173Z"
        ComponentID = "x3000c0s17b1n0"
        Type = "Node"
        [[results.IPAddresses]]
        IPAddress = "10.252.1.69"
        ```

        Record the returned `ID` value into the `EI_ID` environment variable.

        ```bash
        CURRENT_EI_ID=b42e99dff35f
        ```

    1. Update the EthernetInterface to have the desired IP address:

        ```bash
        cray hsm inventory ethernetInterfaces update "$CURRENT_EI_ID" --component-id "${NODE_XNAME}" --ip-addresses--ip-address "${DESIRED_IP_ADDRESS}"
        ```

1. Reboot the node.

1. (`nid#`) SSH to the node and check each DVS mount.

    ```bash
    mount | grep dvs | head -1
    ```

    Example output:

    ```text
    /var/lib/cps-local/0dbb42538e05485de6f433a28c19e200 on /var/opt/cray/gpu/nvidia-squashfs-21.3 type dvs (ro,relatime,blksize=524288,statsfile=/sys/kernel/debug/dvs/mounts/1/stats,attrcache_timeout=14400,cache,nodatasync,noclosesync,retry,failover,userenv,noclusterfs,killprocess,noatomic,nodeferopens,no_distribute_create_ops,no_ro_cache,loadbalance,maxnodes=1,nnodes=6,nomagic,hash_on_nid,hash=modulo,nodefile=/sys/kernel/debug/dvs/mounts/1/nodenames,nodename=x3000c0s6b0n0:x3000c0s5b0n0:x3000c0s4b0n0:x3000c0s9b0n0:x3000c0s8b0n0:x3000c0s7b0n0)
    ```

#### Check the HSN for the affected nodes

1. (`ncn-mw#`) Determine the pod name for the Slingshot fabric manager pod and check the status of the fabric.

    ```bash
    kubectl exec -it -n services $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') -- fmn_status
    ```

#### Check for duplicate IP address entries

1. (`ncn#`) Check for duplicate IP address entries in the Hardware State Management Database (HSM).

    Duplicate entries will cause DNS operations to fail.

    1. Verify that each node hostname resolves to one IP address.

        ```bash
        nslookup x1005c3s0b0n0
        ```

        Example output with one IP address resolving:

        ```text
        Server:         10.92.100.225
        Address:        10.92.100.225#53

        Name:   x1005c3s0b0n0
        Address: 10.100.0.26
        ```

    1. Reload the Kea configuration.

        ```bash
        curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-reload",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea |jq
        ```

        If there are no duplicate IP addresses within HSM, then the following response is expected:

        ```json
        [
            {
            "result": 0,
            "text": "Configuration successful."
            }
        ]
        ```

        If there is a duplicate IP address in the HSM, then an error message similar to the message below will be returned.

        ```text
        [{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf': 
        failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the 
        address 10.100.0.105: There's already a reservation for this address"}]
        ```

1. (`ncn#`) Check for active DHCP leases.

    If there are no DHCP leases, then there is a configuration error.

    ```bash
    curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
        -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
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

1. (`ncn#`) If there are duplicate entries in the HSM as a result of this procedure (`10.100.0.105` in this example), then delete the duplicate entry.

    1. Show the `EthernetInterfaces` for the duplicate IP address:

       ```bash
       cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
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

    1. Delete the older entry.

       ```bash
       cray hsm inventory ethernetInterfaces delete 0040a68350a4
       ```

1. (`ncn#`) Check DNS.

    ```bash
    nslookup 10.100.0.105
    ```

    Example output:

    ```text
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.local.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.local.
    ```

1. (`ncn#`) Check SSH.

    ```bash
    ssh x1005c3s0b0n0
    ```
