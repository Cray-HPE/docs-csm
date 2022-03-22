# Power Cycle and Rebuild Node

## Description

This section applies to all node types. The commands in this section assume you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).

## Procedure

### Step 1 - Open and Watch the console for the node being rebuilt

1. Login to a second session to use it to watch the console using the instructions at the link below: 
   
   ***Please open this link in a new tab or page*** [Log in to a Node Using ConMan](../../conman/Log_in_to_a_Node_Using_ConMan.md)

   The first session will be needed to run the commands in the following Rebuild Node steps.

### Step 2 - Set the PXE boot option and power cycle the node

**IMPORTANT:** Run these commands from a node ***NOT*** being rebuilt.

**IMPORTANT:** These commands assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).

1. Set the BMC variable to the hostname of the BMC of the node being rebuilt.

    ```bash
    BMC=${NODE}-mgmt
    ```

2. Export the root password of the BMC.

    ```bash
    export IPMI_PASSWORD=changeme
    ```

3. Set the PXE/efiboot option.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis bootdev pxe options=efiboot
    ```

4. Power off the node.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power off
     ```

5. Verify that the node is off.

    ```bash
    ipmitool -I lanplus -U root -E -H $BMC chassis power status
    ```

    * Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30seconds after receiving the correct power status before issuing the next command.

6. Power on the node.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power on
     ```

7. Verify that the node is on.

    1. Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

     ```bash
     ipmitool -I lanplus -U root -E -H $BMC chassis power status
     ```

### Step 3 - Observe the boot

1. After a bit, the node should begin to boot. This can be viewed from the ConMan console window. Eventually, there will be a `NBP file...` message in the console output which indicates that the PXE boot has begun the TFTP download of the ipxe program. Later messages will appear as the Linux kernel loads and then the scripts in the initrd begin to run, including `cloud-init`.

1. Wait until `cloud-init` displays messages similar to these on the console to indicate that cloud-init has finished with the module called `modules:final`.

    ```screen
    [  295.466827] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 running 'modules:final' at Thu, 26 Aug2021  15:23:20 +0000. Up 125.72 seconds.
    [  295.467037] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 finished at Thu, 26 Aug 2021 15:26:12+0000. Datasource DataSourceNoCloudNet [seed=cmdline,http://10.92.100.81:8888/][dsmode=net].  Up 29546 seconds
    ```

1. Then press enter on the console to ensure that the the login prompt is displayed including the correct hostname of this node. Then exit the ConMan console (**&** then **.**), and then use `ssh` to log in to the node to complete the remaining validation steps.

    * **Troubleshooting:** If the `NBP file...` output never appears, or something else goes wrong, go back to the steps for modifying the `XNAME.json` file (see the step to [inspect and modify the JSON file](Identify_Nodes_and_Update_Metadata.md#Inspect-and-modify-the-JSON-file) and make sure these instructions were completed correctly.

    * **Master nodes only:** If `cloud-init` did not complete the newly-rebuilt node will need to have its etcd service definition manually updated. Reconfigure the etcd service, and restart the cloud init on the newly rebuilt master:

    ```bash
    ncn-m# systemctl stop etcd.service; sed -i 's/new/existing/' \
           /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service; \
           systemctl daemon-reload ; rm -rf /var/lib/etcd/member; \
           systemctl start etcd.service; /srv/cray/scripts/common/kubernetes-cloudinit.sh
    ```

    **Rebuilt node with modified ssh key(s):** The cloud-init process can fail when accessing other nodes if ssh keys have been modified in the cluster. If this occurs, the following steps can be used to repair the desired ssh keys on the newly rebuilt node:

    1. Allow cloud-init to fail due to the non-matching keys.
    1. Copy the correct ssh key(s) to the newly rebuilt node.
    1. Re-run cloud-init on the newly rebuilt node:

    ```bash
    ncn-m# cloud-init clean; cloud-init init --local; cloud-init init
    ```

## Step 4 - Set the wipe flag back so it will not wipe the disk when the node is rebooted.

1. Run the following commands from a node that has cray cli initialized:

    ```bash
    cray bss bootparameters list --name $XNAME --format=json | jq .[] > ${XNAME}.json
    ```

2. Edit the `XNAME.json` file and set the `metal.no-wipe=1` value.

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

For the next step please click the link for the node type you are rebuilding

[Next Step Validate Boot Raid](Validate_Boot_Raid.md)
