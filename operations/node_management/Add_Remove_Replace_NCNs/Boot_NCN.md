# Boot NCN

## Description

Boot a master, worker, or storage non-compute node (NCN) that is to be added to the cluster.

## Procedure

### Step 1 - Open and Watch the console for the node being rebuilt

1. Login to a second session to use it to watch the console using the instructions at the link below: 
   
   ***Please open this link in a new tab or page*** [Log in to a Node Using ConMan](../../conman/Log_in_to_a_Node_Using_ConMan.md)

   The first session will be needed to run the commands in the following Rebuild Node steps.

### Step 2 - Set the PXE boot option and power on the node

**IMPORTANT:** These commands assumes the variables from [the prerequisites section](../Add_Remove_Replace_NCNs.md#add-ncn-prerequisites) have been set.

1. Set the BMC variable to the hostname of the BMC of the node being rebuilt. If booting `ncn-m001`, set this to the FQDN or IP.

    ```bash
    BMC=${NODE}-mgmt
    ```

2. Export the root password of the BMC.

    ```bash
    export IPMI_PASSWORD=changeme
    ```

3. Check the power status. Power the BMC off if `Chassis Power is on`.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power status
    ipmitool -I lanplus -U root -E -H $BMC chassis power off
    ```

4. Set the PXE/efiboot option.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis bootdev pxe options=efiboot
    ```

5. Power on the node.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power on
     ```

6. Verify that the node is on.

    1. Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power status
     ```

### Step 3 - Observe the boot

1. After a bit, the node should begin to boot. This can be viewed from the ConMan console window. Eventually, there will be a `NBP file...` message in the console output which indicates that the PXE boot has begun the TFTP download of the ipxe program. Later messages will appear as the Linux kernel loads and then the scripts in the initrd begin to run, including `cloud-init`.

1. Wait until `cloud-init` displays messages similar to these on the console to indicate that cloud-init has finished with the module called `modules:final`.

    ```screen
    [  300.390000] cloud-init[7110]: 2022-03-16 18:30:59,449 - util.py[DEBUG]: cloud-init mode 'modules' took 244.143 seconds (198.87)
    [  300.390106] cloud-init[7110]: 2022-03-16 18:30:59,449 - handlers.py[DEBUG]: finish: modules-final: SUCCESS: running modules for final
    [  OK  ] Started Execute cloud user/final scripts.
    [  OK  ] Reached target Cloud-init target.
    ```

1. Then press enter on the console to ensure that the the login prompt is displayed including the correct hostname of this node. Then exit the ConMan console (**&** then **.**), and then use `ssh` to log in to the node to complete any remaining steps based on the node type.

### Step 4 - Verify the added master or worker $NODE has joined the cluster

  ```bash
  ncn-mw# kubectl get nodes
  ```

  Example output:

  ```screen
  NAME       STATUS   ROLES    AGE    VERSION
  ncn-m001   Ready    master   2d7h   v1.19.9
  ncn-m002   Ready    master   20d    v1.19.9
  ncn-m003   Ready    master   20d    v1.19.9
  ncn-w001   Ready    <none>   27h    v1.19.9
  ncn-w002   Ready    <none>   20d    v1.19.9
  ncn-w003   Ready    <none>   20d    v1.19.9
  ncn-w004   Ready    <none>    1h    v1.19.9
  ```

### Step 5 - Set the wipe flag to safeguard against the disk being wiped when the node is rebooted

1. Run the following commands from a node that has cray cli initialized:

    ```bash
    ncn-mw# cray bss bootparameters list --name $XNAME --format=json | jq .[] > ${XNAME}.json
    ```

2. Edit the XNAME.json file and set the `metal.no-wipe=1` value.

3. Get a token to interact with BSS using the REST API.

    ```bash
    ncn-mw# TOKEN=$(curl -s -S -d grant_type=client_credentials \
        -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
        -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
        | jq -r '.access_token')
    ```

4. Do a PUT action for the edited JSON file.

    * This command can be run from any node.

    ```bash
    ncn-mw# curl -i -s -k -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
        -X PUT -d @./${XNAME}.json
    ```

5. Verify the `bss bootparameters list` command returns the expected information.

    * Export the list from BSS to a file with a different name.

    ```bash
    ncn-mw# cray bss bootparameters list --name ${XNAME} --format=json |jq .[]> ${XNAME}.check.json
    ```

    * Compare the new JSON file with what was PUT to BSS.

    ```bash
    ncn-mw# diff ${XNAME}.json ${XNAME}.check.json
    ```

    * The files should be identical

### Step 6 - Run NCN Personalizations using CFS as desired

1. Run the following commands to list the available configurations.

    ```bash
    ncn-mw# cray cfs configurations list
    ```

    Example Output:

    ```screen
    [[results]]
    lastUpdated = "2022-03-14T20:59:44Z"
    name = "ncn-personalization"
    [[results.layers]]
    cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    commit = "1dc4038615cebcfad3e8230caecc885d987e8148"
    name = "csm-ncn-1.6.28"
    playbook = "site.yml"
    ```
    
2. Or determine the configuration applied another NCN of the same type. This example checks the configuration on `ncn-w002`.

    ```bash
    ncn-mw# cray cfs components describe $(ssh ncn-w002 cat /etc/cray/xname)
    ```

    Example Output:

    ```screen
    configurationStatus = "configured"
    desiredConfig = "ncn-personalization"
    enabled = true
    errorCount = 0
    id = "x3000c0s9b0n0"
    [[state]]
    cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    commit = "1dc4038615cebcfad3e8230caecc885d987e8148"
    lastUpdated = "2022-03-15T15:29:20Z"
    playbook = "site.yml"
    sessionName = "batcher-5e431205-a4b4-4a2e-8be3-21cf058774cc"
    ```

3. Select the appropriate configuration based on the above steps to personalize the added NCN. In this example, the `ncn-personalization` configuration is used.

    ```bash
    ncn-mw# cray cfs components update $XNAME --desired-config ncn-personalization
    ```

4. Wait for `configurationStatus` to transition from `pending` to `configured`.

    ```bash
    ncn-mw# watch "cray cfs components describe $XNAME"
    ```

    Example Output:

    ```
    configurationStatus = "configured"
    desiredConfig = "ncn-personalization"
    ...
    ```

### Step 7 - Lock the management nodes

Follow the [How to Lock Management Single Node](../../../operations/hardware_state_manager/Lock_and_Unlock_Management_Nodes.md#to-lock-single-nodes-or-lists-of-specific-nodes-and-their-bmcs) procedure. The management nodes may be unlocked at this point. Locking the management nodes and their BMCs will prevent actions from FAS to update their firmware or CAPMC to power off or do a power reset. Doing any of these by accident will take down a management node. If the management node is a Kubernetes master or worker node, this can have serious negative effects on system operation.

### Step 8 - **For Storage nodes only**

Follow [Add Ceph Node](../../utility_storage/Add_Ceph_Node.md) to join the added storage node to the Ceph cluster.

### Step 9 - **For ncn-m001 only**

1. Restore and verify the site link for `ncn-m001`.
 
    Use the $CAN_IP that was recorded prior to powering down `ncn-m001` to access `ncn-m002`.

    **IMPORTANT:** If the vendor of the replaced master node has changed, before the config is reloaded, verify that the `BRIDGE_PORTS` setting in `/etc/sysconfig/network/ifcfg-lan0` is based on the actual NIC names for the external site interface.

    ```bash
    remote# ssh root@$CAN_IP
    ncn-m002# rsync /tmp/ifcfg-lan0-m001 ncn-m001:/etc/sysconfig/network/ifcfg-lan0
    ncn-m002# ssh ncn-m001
    ncn-m001# wicked ifreload lan0
    ncn-m001# wicked ifstatus lan0
    ```

    Example output:

    ```screen
    lan0            up
      link:     #30, state up, mtu 1500
      type:     bridge, hwaddr a4:bf:01:5a:a9:ff
      config:   compat:suse:/etc/sysconfig/network/ifcfg-lan0
      leases:   ipv4 static granted
      addr:     ipv4 172.30.52.72/20 [static]
    ```

2. Run `ip a` to show the lan0 IP address, verify the site link.

    ```bash
    ncn-m001# ip a show lan0
    ```

Proceed to the next step to [Redeploy Services](Redeploy_Services.md) or return to the main [Add, Remove, Replace or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
