# Power Cycle and Rebuild Node

This section applies to all node types. The commands in this section assume the variables from [the prerequisites section](../Rebuild_NCNs.md#prerequisites) have been set.

## Procedure

1. Open and watch the console for the node being rebuilt.

1. Log in to a second session to use it to watch the console using the instructions at the link below:

   ***Open this link in a new tab or page*** [Log in to a Node Using ConMan](../../conman/Log_in_to_a_Node_Using_ConMan.md)

   The first session will be needed to run the commands in the following Rebuild Node steps.

1. Set the PXE boot option and power cycle the node.

    **IMPORTANT:** Run these commands from a node ***NOT*** being rebuilt.

    **IMPORTANT:** The commands in this section assume the variables from [the prerequisites section](../Rebuild_NCNs.md#prerequisites) have been set.

    1. Set the BMC variable to the hostname of the BMC of the node being rebuilt.

        ```bash
        linux# BMC="${NODE}-mgmt"
        ```

    1. Set and export the `root` password of the BMC.

        > NOTE: `read -s` is used to prevent the password from echoing to the screen or
        > being saved in the shell history.

        ```bash
        linux# read -r -s -p "${BMC} root password: " IPMI_PASSWORD
        linux# export IPMI_PASSWORD
        ```

    1. Set the PXE/efiboot option.

        ```bash
        linux# ipmitool -I lanplus -U root -E -H "${BMC}" chassis bootdev pxe options=efiboot
        ```

    1. Power off the node.

        ```bash
        linux# ipmitool -I lanplus -U root -E -H "${BMC}" chassis power off
        ```

    1. Verify that the node is off.

        ```bash
        linux# ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

    1. Power on the node.

        ```bash
        linux# ipmitool -I lanplus -U root -E -H "${BMC}" chassis power on
        ```

    1. Verify that the node is on.

       Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

       ```bash
       linux# ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
       ```

1. Observe the boot.

   After a bit, the node should begin to boot. This can be viewed from the ConMan console window. Eventually, there will be a `NBP file...` message in the console output which indicates that the
   PXE boot has begun the TFTP download of the `ipxe` program. Messages will appear as the Linux kernel loads, and later when the scripts in the `initrd` begin to run, including `cloud-init`.

1. Wait until `cloud-init` displays messages similar to these on the console, indicating that `cloud-init` has finished with the module called `modules:final`.

   ```text
   [  295.466827] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 running 'modules:final' at Thu, 26 Aug2021  15:23:20 +0000. Up 125.72 seconds.
   [  295.467037] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 finished at Thu, 26 Aug 2021 15:26:12+0000. Datasource DataSourceNoCloudNet [seed=cmdline,http://10.92.100.81:8888/][dsmode=net].  Up 29546 seconds
   ```

   **Troubleshooting:**

   * If the `NBP file...` output never appears, or something else goes wrong, then go back to the steps for modifying the `XNAME.json` file (see the step to
     [inspect and modify the JSON file](Identify_Nodes_and_Update_Metadata.md#Inspect-and-modify-the-JSON-file) and make sure these instructions were completed correctly.

   * **Master nodes only:** If `cloud-init` did not complete, then the newly rebuilt node will need to have its `etcd` service definition manually updated. Reconfigure the `etcd` service and
     restart `cloud-init` on the newly rebuilt master:

       ```bash
       ncn-m# systemctl stop etcd.service; sed -i 's/new/existing/' \
                /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service; \
              systemctl daemon-reload ; rm -rf /var/lib/etcd/member; \
              systemctl start etcd.service; /srv/cray/scripts/common/kubernetes-cloudinit.sh
       ```

   * **Rebuilt node with modified SSH keys:** The `cloud-init` process can fail when accessing other nodes if SSH keys have been modified in the cluster. If this occurs, the following steps can be used to repair the desired SSH keys on the newly rebuilt node:

      1. Allow `cloud-init` to fail because of the non-matching keys.
      1. Copy the correct SSH keys to the newly rebuilt node.
      1. Re-run `cloud-init` on the newly rebuilt node.

         ```bash
         ncn-m# cloud-init clean; cloud-init init --local; cloud-init init
         ```

1. Press enter on the console to ensure that the the login prompt is displayed including the correct hostname of this node.

1. Exit the ConMan console.

   Type `&` and then `.`.

1. Confirm that `vlan004` is up with the correct IP address on the rebuilt node.

   Run these commands on the rebuilt node.

   1. Find the desired IP address.

      These commands assume that the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) have been set.

      ```bash
      ncn# dig +short ${NODE}.hmn
      ```

      Example output:

      ```text
      10.254.1.16
      ```

   1. Show the IP address configured for `vlan004` on the rebuilt node.

      ```bash
      ncn# ip addr show vlan004
      ```

      Example output:

      ```text
      14: vlan004@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
          link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
          inet 10.254.1.16/17 brd 10.254.127.255 scope global vlan004
             valid_lft forever preferred_lft forever
          inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
             valid_lft forever preferred_lft forever
      ```

   1. Confirm that the IP addresses from the two commands match.

      If they do not match, then perform the following remediation steps:

      1. Change the IP address for `vlan004`.

         Edit the `/etc/sysconfig/network/ifcfg-vlan004` file on the rebuilt node.
         Set the `IPADDR` line to the correct IP address with a `/17` mask.

         For example, if the correct IP address is `10.254.1.16`, then the line should be:

         ```text
         IPADDR='10.254.1.16/17'
         ```

      1. Restart the `vlan004` network interface.

         ```bash
         ncn# wicked ifreload vlan004
         ```

      1. Repeat the earlier steps and confirm that the IP addresses now match.

1. Confirm that `vlan007` is up with the correct IP address on the rebuilt node.

   Run these commands on the rebuilt node.

   1. Find the desired IP address.

      These commands assume that the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) have been set.

      ```bash
      ncn# dig +short ${NODE}.can
      ```

      Example output:

      ```text
      10.103.8.11
      ```

   1. Show the IP address configured for `vlan007` on the rebuilt node.

      ```bash
      ncn# ip addr show vlan007
      ```

      Example output:

      ```text
      15: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
          link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
          inet 10.103.8.11/24 brd 10.103.8.255 scope global vlan007
             valid_lft forever preferred_lft forever
          inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
             valid_lft forever preferred_lft forever
      ```

   1. Confirm that the IP addresses from the two commands match.

      If they do not match, then perform the following remediation steps:

      1. Change the IP address for `vlan007`.

         Edit the `/etc/sysconfig/network/ifcfg-vlan007` file on the rebuilt node.
         Set the `IPADDR` line to the correct IP address with a `/24` mask.

         For example, if the correct IP address is `10.103.8.11`, then the line should be:

         ```text
         IPADDR='10.103.8.11/24'
         ```

      1. Restart the `vlan007` network interface.

         ```bash
         ncn# wicked ifreload vlan007
         ```

      1. Repeat the earlier steps and confirm that the IP addresses now match.

1. Set the wipe flag back so it will not wipe the disk when the node is rebooted.

   1. Run the following commands from a node that has `cray` CLI initialized.

      See [Configure the Cray CLI](../../configure_cray_cli.md).

      ```bash
      ncn# cray bss bootparameters list --name "${XNAME}" --format=json | jq .[] > "${XNAME}.json"
      ```

   1. Edit the `XNAME.json` file and set the `metal.no-wipe=1` value.

   1. Get a token to interact with BSS using the REST API.

      ```bash
      ncn# TOKEN=$(curl -s -S -d grant_type=client_credentials -d client_id=admin-client \
                       -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                       https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                       | jq -r '.access_token')
      ```

   1. Do a `PUT` action for the edited JSON file.

      This command can be run from any node.

      ```bash
      ncn# curl -i -s -k -H "Content-Type: application/json" \
               -H "Authorization: Bearer ${TOKEN}" \
               "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
               -X PUT -d @"./${XNAME}.json"
      ```

   1. Verify that the `bss bootparameters list` command returns the expected information.

      1. Export the list from BSS to a file with a different name.

         ```bash
         ncn# cray bss bootparameters list --name "${XNAME}" --format=json |jq .[]> "${XNAME}.check.json"
         ```

      1. Compare the new JSON file with what was put into BSS.

         This command should give no output, because the files should be identical.

         ```bash
         ncn# diff "${XNAME}.json" "${XNAME}.check.json"
         ```

## Next step

Proceed to the next step to [Validate Boot Raid](Validate_Boot_Raid.md).
