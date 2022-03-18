# Boot NCN

## Description

Boot a master, worker, or storage non-compute node (NCN) that is to be added to the cluster.

## Procedure

### Step 1 - Open and Watch the console for the node being rebuilt

1. Login to a second session to use it to watch the console using the instructions at the link below:

   ***Please open this link in a new tab or page*** [Log in to a Node Using ConMan](../../conman/Log_in_to_a_Node_Using_ConMan.md)

   The first session will be needed to run the commands in the following Rebuild Node steps.

### Step 2 - Set the PXE boot option and power on the node

**IMPORTANT:** These commands assumes you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#add-prerequisites).

1. Set the BMC variable to the hostname of the BMC of the node being rebuilt.

    ```bash
    BMC=${NODE}-mgmt
    ```

2. Export the root password of the BMC.

    ```bash
    export IPMI_PASSWORD=changeme
    ```

3. Verify you can access the BMC by checking the power status.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power status
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

### Step 4 - Set the wipe flag to safeguard against the disk being wiped when the node is rebooted.

1. Run the following commands from a node that has cray cli initialized:

    ```bash
    cray bss bootparameters list --name $XNAME --format=json | jq .[] > ${XNAME}.json
    ```

2. Edit the XNAME.json file and set the `metal.no-wipe=1` value.

3. Get a token to interact with BSS using the REST API.

    ```bash
    ncn# TOKEN=$(curl -s -S -d grant_type=client_credentials \
        -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
        -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
        | jq -r '.access_token')
    ```

4. Do a PUT action for the edited JSON file.

    * This command can be run from any node.

    ```bash
    ncn# curl -i -s -k -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
        -X PUT -d @./${XNAME}.json
    ```

5. Verify the `bss bootparameters list` command returns the expected information.

    * Export the list from BSS to a file with a different name.

    ```bash
    ncn# cray bss bootparameters list --name ${XNAME} --format=json |jq .[]> ${XNAME}.check.json
    ```

    * Compare the new JSON file with what was PUT to BSS.

    ```bash
    ncn# diff ${XNAME}.json ${XNAME}.check.json
    ```

    * The files should be identical

### Step 5 - Run NCN Personalizations using CFS as desired

1. Run the following commands to list the available configurations.

    ```bash
    ncn-mw# cray cfs configurations list
    ```

    Example Output:

    ```
    [[results]]
    lastUpdated = "2022-03-14T20:59:44Z"
    name = "ncn-personalization"
    [[results.layers]]
    cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    commit = "1dc4038615cebcfad3e8230caecc885d987e8148"
    name = "csm-ncn-1.6.28"
    playbook = "site.yml"
    ```
    
2. Select the appropriate configuration from the above list and configure the added NCN. In this example, the `ncn-personalization` config is used.

    ```bash
    ncn-mw# cray cfs components update $XNAME --desired-config ncn-personalization
    ```

3. Wait for `configurationStatus` to transistion from `pending` to `configured`

    ```bash
    ncn-mw# watch "cray cfs components describe $XNAME"
    ```

    Example Output:

    ```
    configurationStatus = "configured"
    desiredConfig = "ncn-personalization"
    ...
    ```

### Step 6 - Lock the management nodes

Follow [How to Lock Management Single Node](../../../operations/hardware_state_manager/Lock_and_Unlock_Management_Nodes.md#to-lock-single-nodes-or-lists-of-specific-nodes-and-their-bmcs). The management nodes may be unlocked at this point. Locking the management nodes and their BMCs will prevent actions from FAS to update their firmware or CAPMC to power off or do a power reset. Doing any of these by accident will take down a management node. If the management node is a Kubernetes master or worker node, this can have serious negative effects on system operation.

### Step 7 - **For Storage nodes only**

1. Follow [Add Ceph Node](../../utility_storage/Add_Ceph_Node.md) to join the added storage node to the Ceph cluster.

2. Follow [Redeploy Services](./Redeploy_Services.md) to update service endpoints to include the newly added storage node.

### Step 8 - Validate the node

Follow the validation steps in the section for the node type that was added:

- [Worker node](Add_Worker_Node_Validation.md)
- [Storage node](Add_Storage_Node_Validation.md)
- [Master node](Add_Master_Node_Validation.md)

