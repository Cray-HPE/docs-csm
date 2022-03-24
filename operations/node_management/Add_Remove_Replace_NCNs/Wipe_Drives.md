# Wipe Disks
(#wipe-disks-utility-storage-node
**Warning:** This is the point of no return. 

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

Only follow the steps in the section for the node type that is being removed:

- [Wipe Disks](#wipe-disks)
  - [Wipe Disks: Master Node](#wipe-disks-master-node)
  - [Wipe Disks: Worker Node](#wipe-disks-worker-node)
  - [Wipe Disks: Utility Storage Node](#wipe-disks-utility-storage-node)

<a name="wipe-disks-master-node"></a>
## Wipe Disks: Master Node

**NOTE:** etcd should already be stopped as part of the "Remove NCN from Role" steps.

1. Remove the etcd device mapper.

    ```bash
    dmsetup remove $(dmsetup ls | grep -i etcd | awk '{print $1}')
    ```

    > **Note:** The following output  means the etcd volume  mapper is not present.
    ```bash
    No device specified.
    Command failed.
    ```

1. Unmount the etcd volume and remove the volume group.

   ```bash
   umount /run/lib-etcd
   vgremove -f etcdvg0-ETCDK8S
   ```

1. Unmount the `SDU` mountpoint and remove the volume group.

   ```bash
   umount /var/lib/sdu
   vgremove -f -v --select 'vg_name=~metal*'
   ```

1. Wipe the drives

   ```bash
   mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '   {print "/dev/" $2}')
   wipefs --all --force $mdisks
   ```

<a name="wipe-disks-worker-node"></a>
## Wipe Disks: Worker Node

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

1. Unmount the `SDU` mountpoint and remove the volume group.

   ```bash
   umount /var/lib/sdu
   vgremove -f -v --select 'vg_name=~metal*'
   ```

1. Wipe Drives

    ```bash
    wipefs --all --force /dev/disk/by-label/*
    wipefs --all --force /dev/sd*
    ```

<a name="wipe-disks-utility-storage-node"></a>
## Wipe Disks: Utility Storage Node

1. Make sure the OSDs (if any) are not running.

    ```bash
    podman ps
    ```

    Examine the output. There should be no running ceph processes or containers.

2. Remove the Volume Groups.

    ```bash
    ls -1 /dev/sd* /dev/disk/by-label/*
    vgremove -f --select 'vg_name=~ceph*'
    ```

3. Unmount and remove the metalvg0 volume group

   ```bash
   umount /etc/ceph
   umount /var/lib/ceph
   umount /var/lib/containers
   vgremove -f metalvg0
   ```

4. Wipe the disks and RAIDs.

    ```bash
    wipefs --all --force /dev/disk/by-label/*
    wipefs --all --force /dev/sd*
    ```
