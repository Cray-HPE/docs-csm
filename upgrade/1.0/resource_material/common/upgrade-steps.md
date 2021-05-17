# Common Upgrade Steps

These steps will be run on the stable NCN of choice regardless of NCN type to be upgraded.

1. Change the boot parameters for the node being upgraded to use the newly upgraded image. Make sure you have 
   `KUBERNETES_VERSION` and `CEPH_VERSION` environment variables exported to the version you uploaded into S3:

   > NOTE: If the node removed from the cluster in the previous step moved the `sls` pod, the following command may fail for a few minutes (with an error message about `failed to unmarshal body`) while the pod starts up on a remaining worker node in the cluster.  Once the `sls` pod is back in a running state the command should then succeed.

   - For each kubernetes ***MASTER*** or ***WORKER*** node:

     ```bash
     ncn# csi handoff bss-update-param \
          --set metal.server=http://rgw-vip.nmn/ncn-images/k8s/${KUBERNETES_VERSION} \
          --set rd.live.squashimg=filesystem.squashfs \
          --set metal.no-wipe=0 \
          --kernel s3://ncn-images/k8s/${KUBERNETES_VERSION}/kernel \
          --initrd s3://ncn-images/k8s/${KUBERNETES_VERSION}/initrd \
          --limit $UPGRADE_XNAME
     ```

   - For each ***STORAGE*** node:

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

    > **NOTE:** If the node being upgraded is `ncn-m001`, the adminstrator will need to watch the using the web interface for the bmc (typically https://SYSTEM-ncn-m001-mgmt/viewer.html).

    ```bash
    ncn# kubectl -n services exec -it $(kubectl get po -n services | grep conman | awk '{print $1}') -- /bin/sh -c 'conman -j <xname>'
    ```

3. Wipe/erase the disks on the node being rebuilt.  This can be done from the conman console window.

     > NOTE: This is the point of no return, once disks are wiped, you are committed to rebuilding the node.

   1. Execute the wipe command for a ***MASTER*** or ***WORKER*** (***skip this step and proceed to step (3.ii) if a storage node***):

      ```bash
      ncn# md_disks="$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')"
      ncn# wipefs -af $md_disks
      ```

   2. If the node being upgraded is a ***STORAGE*** node use the following command to only wipe OS disks with mirrored devices:

      ```bash
      ncn# for d in $(lsblk | grep -B2 -F md1  | grep ^s | awk '{print $1}'); do wipefs -af "/dev/$d"; done
      ```

4. Set the PXE boot option and power cycle the node.

    > NOTE:
    >
    >  * If the node getting upgraded has its BMC connection on the customer network (typically ncn-m001) then these
         commands will need to be run locally on that NCN.
    >  * It's possible for the NCNs to have booting issues at this stage similar to those that could be encountered
         during the initial install. If you run into any issues at this stage please consult the PXE boot
         Troubleshooting guide.

    1. Set the pxe/efiboot option

       ```bash
       ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis bootdev pxe options=efiboot
       ```

    2. Power off the server.

       ```bash
       ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power off
       ```

    3. Check the server is off (might need to wait a few seconds).

       ```bash
       ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power status
       ```

    4. Power on the server.

       ```bash
       ipmitool -I lanplus -U root -P initial0 -H $UPGRADE_NCN-mgmt chassis power on
       ```

5. If the node is a ***WORKER***, confirm BGP is healthy by following the steps in the 'Check BGP Status and Reset Sessions' section in the admin guide for steps to verify and fix BGP if needed.

6. Set the disk wipe flag back to not wipe the disk in the event that the node reboots.

   ```bash
   ncn# csi handoff bss-update-param --set metal.no-wipe=1 --limit $UPGRADE_XNAME
   ```

7. If the node just upgraded was `ncn-m001`, you'll want to copy the `/etc/sysconfig/network/ifcfg-lan0` and  `/etc/sysconfig/network/ifroute-lan` files back into place, and run the following command.

   ```bash
   ncn# wicked ifreload lan0
   ```

8. Finally, login to the newly rebuild node, and run the appropriate set of goss tests to confirm the node is in a healthy state before proceeding to the next node to upgrade.  If any of the tests fail, inspect the output from the goss command and address any failures.

   - ***MASTER***:

     ```bash
     ncn# goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-master.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
     ```

   - ***WORKER***:

     ```bash
     ncn# GOSS_BASE=/opt/cray/tests/install goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-worker.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
     ```

   - ***STORAGE***:

     ```bash
     ncn# goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-tests-storage.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
     ```

Proceed to either:
- [Back to Main Page](../../README.md) if done upgrading either master or worker nodes
- [Back to Common Prerequisite Steps](../common/prerequisite-steps.md) to rebuild another master or worker node
- [Additional Storage Upgrade Steps](../stage2/storage-node-upgrade.md) to complete the upgrade if a storage node
