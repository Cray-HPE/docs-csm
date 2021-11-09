# Power Cycle and Rebuild Nodes

This section applies to all node types.

## Prerequisites 

The commands in this section assume the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

## Procedure

### Step 1 - Open and watch the console for the node being rebuilt

1. Log in to a second session to use it to watch the console using the instructions at the link below: 
   
   ***Please open the following link in a new tab or page:*** [Log in to a Node Using ConMan](../../conman/Log_in_to_a_Node_Using_ConMan.md)

   The first session will be needed to run the commands in the following rebuild node steps.

### Step 2 - Set the PXE boot option and power cycle the node

> **IMPORTANT:** Run these commands from a node ***NOT*** being rebuilt.

> **IMPORTANT:** These commands assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

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
   
   Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

6. Power on the node.
   
   ```bash
   ipmitool -I lanplus -U root -E -H $BMC chassis power on
   ```

7. Verify that the node is on.
   
   Ensure the power is reporting as on. This may take 5-10 seconds for this to update.
   
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

1. Press enter on the console to ensure that the the login prompt is displayed including the correct hostname of this node. Then exit the ConMan console (**&** then **.**), and then use `ssh` to log in to the node to complete the remaining validation steps.

   * **Troubleshooting:** If the `NBP file...` output never appears, or something else goes wrong, go back to the steps for modifying XNAME.json file (see the step to [inspect and modify the JSON file](Identify_Nodes_and_Update_Metadata.md#Inspect-and-modify-the-JSON-file) and make sure these instructions were completed correctly.

   * **Master nodes only:** If `cloud-init` did not complete the newly-rebuilt node will need to have its etcd service definition manually updated. Reconfigure the etcd service, and restart the cloud init on the newly rebuilt master:

   ```bash
   ncn-m# systemctl stop etcd.service; sed -i 's/new/existing/' \
         /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service; \
         systemctl daemon-reload ; rm -rf /var/lib/etcd/member; \
         systemctl start etcd.service; /srv/cray/scripts/common/kubernetes-cloudinit.sh
   ```

### Step 4 - Confirm `vlan004` is up with the correct IP address on the rebuilt node

Run these commands on the rebuilt node.

1. Find the desired IP address.

   > **NOTE:** The following command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.
   
   ```bash
   ncn# dig +short ${NODE}.hmn
   10.254.1.16
   ```

2. Confirm the output from the `dig` command matches the interface.

    1. If the IP addresses match, proceed to the next step. If they do not match, continue with the following sub-steps.

        ```bash
        ncn# ip addr show vlan004
        14: vlan004@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
            link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
            inet 10.254.1.16/17 brd 10.254.127.255 scope global vlan004
               valid_lft forever preferred_lft forever
            inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
               valid_lft forever preferred_lft forever
        ```

    2. Change the IP address for `vlan004` if necessary.

        ```bash
        ncn# vim /etc/sysconfig/network/ifcfg-vlan004
        ```

        1. Set the `IPADDR` line to the correct IP address with a `/17` mask. For example, if the correct IP address is `10.254.1.16`, the line should be:

             ```bash
             IPADDR='10.254.1.16/17'
             ```

    3. Restart the `vlan004` network interface.

        ```bash
        ncn# wicked ifreload vlan004
        ```

    4. Confirm the output from the `dig` command matches the interface.

        ```bash
        ncn# ip addr show vlan004
        ```

### Step 5 - Confirm that `vlan007` is up with the correct IP address on the rebuilt node

Run these commands on the rebuilt node.

1. Find the desired IP address.
   
   > **NOTE:** The following command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

   ```bash
   ncn# dig +short ${NODE}.can
   10.103.8.11
   ```

2. Confirm the output from the dig command matches the interface.

   * If the IP addresses match, proceed to the next step. If they do not match, continue with the following sub-steps.

     ```bash
     ip addr show vlan007
     ```

     Example Output:

     ```screen
     15: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
          link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
          inet 10.103.8.11/24 brd 10.103.8.255 scope global vlan007
            valid_lft forever preferred_lft forever
            inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
               valid_lft forever preferred_lft forever
     ```

     1. Change the IP address for `vlan007` if necessary.
   
        ```bash
        vim /etc/sysconfig/network/ifcfg-vlan007
        ```

        Set the `IPADDR` line to the correct IP address with a `/24` mask. For example, if the correct IP address is `10.103.8.11`, the line should be:

        ```bash
        IPADDR='10.103.8.11/24'
        ```

     2. Restart the `vlan007` network interface.

        ```bash
        wicked ifreload vlan007
        ```

     3. Confirm the output from the `dig` command matches the interface.

        ```bash
        ip addr show vlan007
        ```

## Step 6 - Set the wipe flag back so it will not wipe the disk when the node is rebooted

1. Edit the XNAME.json file and set the `metal.no-wipe=1` value.

2. Do a PUT action for the edited JSON file.
   
   * This command can be run from any node. This command assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).
     
     ```bash
     ncn# curl -i -s -k -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${TOKEN}" \
         "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
         -X PUT -d @./${XNAME}.json
     ```

   * The output from the `ncnHealthChecks.sh` script \(run later in the "Validation" steps\) can be used to verify the `metal.no-wipe` value on every NCN.


## Next Step

For the next step in the NCN Rebuild procedure, see [Validate Boot Raid](Validate_Boot_Raid.md).
