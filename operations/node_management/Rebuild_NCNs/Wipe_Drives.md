# Wipe Disks

**Warning:** This is the point of no return. Once the disks are wiped, the node must be rebuilt.

All commands in this section must be run on the node being rebuilt \(unless otherwise indicated\). These commands can be done from the ConMan console window.

Only follow the steps in the section for the node type that is being rebuilt:

- [Wipe Disks](#wipe-disks)
  - [Wipe Disks: Master or Worker Node](#wipe-disks-master-or-worker-node)
  - [Wipe Disks: Utility Storage Node](#wipe-disks-utility-storage-node)

<a name="wipe_disks_master_worker"></a>

## Wipe Disks: Master or Worker Node

This section applies to master and worker nodes. Skip this section if rebuilding a storage node. 

```bash
ncn-mw# mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')
ncn-mw# wipefs --all --force $mdisks
```

## Wipe Disks: Utility Storage Node

1. Stop running OSDs on the node being wiped

    ```bash
    ncn-s# systemctl stop ceph-osd.target
    ```

2. Make sure the OSDs (if any) are not running after running the first command.

    ```bash
    ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
    ncn-s# vgremove -f --select 'vg_name=~ceph*'
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
    wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

[Click Here for the Next Step](Power_Cycle_and_Rebuild_Nodes.md)

Or [CLick Here to Return to the Main Page](../Rebuild_NCNs.md)