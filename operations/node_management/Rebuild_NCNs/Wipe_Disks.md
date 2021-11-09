# Wipe Disks

> **WARNING:** This is the point of no return. Once the disks are wiped, the node must be rebuilt.

All commands in this section must be run on the node being rebuilt \(unless otherwise indicated\). These commands can be done from the ConMan console window.

## Procedure 

Only follow the steps in the section for the node type that is being rebuilt:

  - [Wipe Disks: Master Node](#wipe-disks-master-node)
  - [Wipe Disks: Worker Node](#wipe-disks-worker-node)
  - [Wipe Disks: Utility Storage Node](#wipe-disks-utility-storage-node)

After completing the steps for the node type being rebuilt, proceed to the [next step](#next-step) header.

### Wipe Disks: Master Node

1. Unmount the etcd volume and remove the volume group.

   > **NOTE:** etcd should already be stopped as part of the [Prepare Master Node](Prepare_Master_Nodes.md) steps.

   ```bash
   /run/lib-etcd
   vgremove -f etcdvg0-ETCDK8S
   ```

2. Unmount the System Dump Utility (SDU) mountpoint and remove the volume group.

   ```bash
   umount /var/lib/sdu
   vgremove -f metalvg0-CRAYSDU
   ```

3. Wipe the drives.

   ```bash
   mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '   {print "/dev/" $2}')
   wipefs --all --force $mdisks
   ```

### Wipe Disks: Worker Node

1. Stop contianerd and wipe drives.

    ```bash
    systemctl stop containerd.service
    ```

1. Unmount partitions.

    ```bash
    umount /var/lib/kubelet
    umount /run/lib-containerd
    umount /run/containerd
    ```

1. Wipe the drives.

    ```bash
    wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

### Wipe Disks: Utility Storage Node

1. Stop running OSDs on the node being wiped.

    ```bash
    ncn-s# systemctl stop ceph-osd.target
    ```

1. Make sure the OSDs (if any) are not running after running the first command.

    ```bash
    ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
    ncn-s# vgremove -f --select 'vg_name=~ceph*'
    ```

1. Unmount and remove the metalvg0 volume group.

   ```bash
   umount /etc/ceph
   umount /var/lib/ceph
   umount /var/lib/containers
   vgremove -f metalvg0
   ```

1. Wipe the disks and RAIDs.

    ```bash
    wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

## Next Step

Proceed to the next step to [Power Cycle and Rebuild Nodes](Power_Cycle_and_Rebuild_Nodes.md) or return to the high-level [Rebuild NCNs](../Rebuild_NCNs.md) procedure.

