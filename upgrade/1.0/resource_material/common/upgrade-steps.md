# Common Upgrade Steps

These steps will be run on the stable NCN of choice regardless of NCN type to be upgraded.

1. Change the boot parameters for the node being upgraded to use the newly upgraded image. Make sure you have 
   `KUBERNETES_VERSION` and `CEPH_VERSION` environment variables exported to the version you uploaded into S3:

   > NOTE: If the node removed from the cluster in the previous step moved the `sls` pod, the following command may fail for a few minutes (with an error message about `failed to unmarshal body`) while the pod starts up on a remaining worker node in the cluster.  Once the `sls` pod is back in a running state the command should then succeed.

   - If your upgrade node is a ***MASTER*** or ***WORKER*** node, run this command on the stable node:

     ```bash
     ncn# csi handoff bss-update-param \
          --set metal.server=http://rgw-vip.nmn/ncn-images/k8s/${KUBERNETES_VERSION} \
          --set rd.live.squashimg=filesystem.squashfs \
          --set metal.no-wipe=0 \
          --kernel s3://ncn-images/k8s/${KUBERNETES_VERSION}/kernel \
          --initrd s3://ncn-images/k8s/${KUBERNETES_VERSION}/initrd \
          --limit $UPGRADE_XNAME
     ```

   - If your upgrade node is a ***STORAGE*** node, run this command on the stable node:

     ```bash
     ncn# csi handoff bss-update-param \
          --set metal.server=http://rgw-vip.nmn/ncn-images/ceph/${CEPH_VERSION} \
          --set rd.live.squashimg=filesystem.squashfs \
          --set metal.no-wipe=1 \
          --kernel s3://ncn-images/ceph/${CEPH_VERSION}/kernel \
          --initrd s3://ncn-images/ceph/${CEPH_VERSION}/initrd \
          --limit $UPGRADE_XNAME
     ```

2. Watch the console for the node being rebuilt by exec'ing into the conman pod and connect to the console (press `&.` to exit).

    > **NOTE:** If the node being upgraded is `ncn-m001`, the administrator will need to watch the using the web interface for the bmc (typically https://SYSTEM-ncn-m001-mgmt/viewer.html).

    ```bash
    ncn# kubectl -n services exec -it $(kubectl get po -n services | grep conman | awk '{print $1}') -- /bin/sh -c 'conman -j <xname>'
    ```

3. Update bss cloud-init data so that Mountain/Hill routes get added to NCNs when they boot with the new image.  This will affect all NCNs.
    ```bash
    ncn# cd /usr/share/doc/csm/upgrade/1.0/scripts/cloud-init
    ncn# ./update-ncn-mountain-hill-routes.sh
    ```

    Output will look similar to:
    ```bash
    ncn# ./update-ncn-mountain-hill-routes.sh
    2021/06/04 14:51:22 Getting management NCNs from SLS...
    2021/06/04 14:51:22 Done getting management NCNs from SLS.
    2021/06/04 14:51:22 Updating NCN cloud-init parameters...
    2021/06/04 14:51:28 Sucessfuly PUT BSS entry for x3000c0s21b0n0
    2021/06/04 14:51:35 Sucessfuly PUT BSS entry for x3000c0s7b0n0
    2021/06/04 14:51:42 Sucessfuly PUT BSS entry for x3000c0s19b0n0
    2021/06/04 14:51:48 Sucessfuly PUT BSS entry for x3000c0s13b0n0
    2021/06/04 14:51:55 Sucessfuly PUT BSS entry for x3000c0s3b0n0
    2021/06/04 14:52:02 Sucessfuly PUT BSS entry for x3000c0s11b0n0
    2021/06/04 14:52:08 Sucessfuly PUT BSS entry for x3000c0s5b0n0
    2021/06/04 14:52:15 Sucessfuly PUT BSS entry for x3000c0s25b0n0
    2021/06/04 14:52:22 Sucessfuly PUT BSS entry for x3000c0s17b0n0
    2021/06/04 14:52:28 Sucessfuly PUT BSS entry for x3000c0s1b0n0
    2021/06/04 14:52:35 Sucessfuly PUT BSS entry for x3000c0s9b0n0
    2021/06/04 14:52:42 Sucessfuly PUT BSS entry for Global
    2021/06/04 14:52:42 Done updating NCN cloud-init parameters.
    ncn#
    ```

    Verify the operation was successful, picking any one of the xnames from the above output.  You should see `write_files` content similar to the following::
    ```bash
    ncn# cray bss bootparameters list --hosts x3000c0s25b0n0 --format=json | jq '.[] | ."cloud-init"."user-data"."write_files"'
    {
      "write_files": [
        {
          "content": "10.100.0.0/22 10.252.0.1 - vlan002\n10.100.4.0/22 10.252.0.1 - vlan002\n10.100.8.0/22 10.252.0.1 - vlan002\n10.100.12.0/22 10.252.0.1 - vlan002\n10.106.0.0/22 10.252.0.1 - vlan002\n",
          "owner": "root:root",
          "path": "/etc/sysconfig/network/ifroute-vlan002",
          "permissions": "0644"
        },
        {
          "content": "10.104.0.0/22 10.254.0.1 - vlan004\n10.104.4.0/22 10.254.0.1 - vlan004\n10.104.8.0/22 10.254.0.1 - vlan004\n10.104.12.0/22 10.254.0.1 - vlan004\n10.107.0.0/22 10.254.0.1 - vlan004\n",
          "owner": "root:root",
          "path": "/etc/sysconfig/network/ifroute-vlan004",
          "permissions": "0644"
        }
      ]
    }
    ```

4. Wipe/erase the disks on the node being rebuilt.  This can be done from the conman console window.

     > NOTE: This is the point of no return, once disks are wiped, you are committed to rebuilding the node.

   1. Execute the wipe command for a ***MASTER*** or ***WORKER*** (***skip this step and proceed to step (3.ii) if a storage node***):

      ```bash
      ncn# md_disks="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')"
      ncn# wipefs -af $md_disks
      ```

   2. If the node being upgraded is a ***STORAGE*** node use the following command to only wipe OS disks with mirrored devices:

      ```bash
      ncn-s# for d in $(lsblk | grep -B2 -F md1  | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
      ```

5. Set the PXE boot option and power cycle the node.

    > NOTE:
    >
    >  * If the node getting upgraded has its BMC connection on the customer network (typically ncn-m001) then these
         commands will need to be run from another system on that network. Otherwise they can be run from the stable node.
    >  * It's possible for the NCNs to have booting issues at this stage similar to those that could be encountered
         during the initial install. If you run into any issues at this stage please consult the PXE boot
         Troubleshooting guide.

    1. Set the pxe/efiboot option

       ```bash
       linux# ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis bootdev pxe options=efiboot
       ```

    2. Power off the server.

       ```bash
       linux# ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power off
       ```

    3. Check the server is off (might need to wait a few seconds).

       ```bash
       linux# ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power status
       ```

    4. Power on the server.

       ```bash
       linux# ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power on
       ```

    5. Wait for the server to boot and complete cloud-init.

6. If the node is a ***WORKER***, confirm BGP is healthy by following the steps in the 'Check BGP Status and Reset Sessions' section in the admin guide for steps to verify and fix BGP if needed.

7. Set the disk wipe flag back to not wipe the disk in the event that the node reboots.

   ```bash
   ncn# csi handoff bss-update-param --set metal.no-wipe=1 --limit $UPGRADE_XNAME
   ```

8. If the node just upgraded was `ncn-m001`, you'll want to copy the `/etc/sysconfig/network/ifcfg-lan0` and  `/etc/sysconfig/network/ifroute-lan` files back into place, and run the following command.

   ```bash
   ncn# wicked ifreload lan0
   ```


9. Verify node health.

    * If the node is a **MASTER** or **WORKER**, login to the newly-rebuilt node, and run the appropriate set of goss tests to confirm the node is in a healthy state before proceeding to the next node to upgrade.  If any of the tests fail, inspect the output from the goss command and address any failures.

        - ***MASTER***:

            ```bash
            ncn# GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
            ```

        - ***WORKER***:

            ```bash
            ncn# GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
            ```

    * If the node is a **STORAGE** node, there is no validation to perform at this point. It is expected that ceph will be in an unhealthy state until further upgrade steps are performed.

Proceed to either:
- [Back to Main Page](../../README.md) if done upgrading either master or worker nodes
- [Back to Common Prerequisite Steps](../common/prerequisite-steps.md) to rebuild another master or worker node
- [Additional Storage Upgrade Steps](../stage2/storage-node-upgrade.md) to complete the upgrade if a storage node
