# Wipe NCN Disks for Reinstallation

This page will detail how disks are wiped and includes workarounds for wedged disks.
Any process covered on this page will be covered by the installer.

> **Everything in this section should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

Ideally the Basic Wipe is enough, and should be tried first. All type of disk wipe can be run from Linux or an initramFS/initrd emergency shell. 

The following are potential use cases for wiping disks:

<a name="use-cases"></a>
   * Adding a node that is not bare.
   * Adopting new disks that are not bare.
   * Doing a fresh install.


### Topics: 
   1. [Basic Wipe](#basic-wipe)
   1. [Advanced Wipe](#advanced-wipe)
   1. [Full Wipe](#full-wipe)

## Details

<a name="basic-wipe"></a>
### 1. Basic Wipe

A basic wipe includes wiping the disks and all of the RAIDs. These basic wipe instructions can be
executed on **any management nodes** (master, worker and storage).

1. List the disks for verification:

   ```bash
   ncn# ls -1 /dev/sd* /dev/disk/by-label/*
   ```

1. Wipe the disks and the RAIDs.

   ```bash
   ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

   If any disks had labels present, output looks similar to the following:

   ```
   /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
   /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
   /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
   /dev/sdb: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
   /dev/sdb: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
   /dev/sdc: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
   /dev/sdc: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
   /dev/sdc: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
   ```
      
   Verify there are no error messages in the output.

   The `wipefs` command may fail if no labeled disks are found, which is an indication of a larger problem.

<a name="advanced-wipe"></a>
### 2. Advanced Wipe

This section is specific to utility storage nodes. An advanced wipe includes deleting the Ceph volumes, and then
wiping the disks and RAIDs.

1. Delete CEPH Volumes

   ```bash
   ncn-s# systemctl stop ceph-osd.target
   ```

   Make sure the OSDs (if any) are not running after running the first command.

   ```bash
   ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
   ncn-s# vgremove -f --select 'vg_name=~ceph*'
   ```

1. Wipe the disks and RAIDs.

   ```bash
   ncn-s# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.

<a name="full-wipe"></a>
### 3. Full-Wipe

This section is preferred method for all nodes. A full wipe includes deleting the Ceph volumes (where applicable), stopping the
RAIDs, zeroing the disks, and then wiping the disks and RAIDs.

**IMPORTANT:** Step 1 is to wipe the Ceph OSD drives. ***Steps 2, 3, 4, and 5 are for all node types.***

1. Delete CEPH Volumes ***on Utility Storage Nodes ONLY***

   For Each Storage node:

    1. Stop CEPH

        * ***1.4 or earlier***

            ```bash
            ncn-s# systemctl stop ceph-osd.target
            ```

        * ***1.5 or later***

            ```bash
            ncn-s# cephadm rm-cluster --fsid $(cephadm ls|jq -r '.[0].fsid') --force
            ```

   2. Make sure the OSDs (if any) are not running.

        ```bash
        ncn-s# ps -ef|grep ceph-osd
        ```
        
        Examine the output. There should be no running ceph-osd processes.

   3. Remove the VGs.

        ```bash
        ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
        ncn-s# vgremove -f --select 'vg_name=~ceph*'
        ```

2. Unmount volumes
   1. Storage nodes
      ```bash
      ncn-s# umount -v /var/lib/ceph /var/lib/containers /etc/ceph
      ```
   2. Master nodes
      ```bash
      ncn-m# umount -v /var/lib/etcd
      ```
   3. Worker nodes
      ```bash
      ncn-w# umount -v /var/lib/containerd /var/lib/kubelet /var/lib/sdu
      ```
3. Remove auxiliary LVMs

   ```bash
   ncn# vgremove -f --select 'vg_name=~metal*'
   ```

   >>***Note***: Optionally you can run a pvs and if any drives are still listed, you can remove them with a pvremove. This is rarely needed.

4. Stop the RAIDs.

   ```bash
   ncn# for md in /dev/md/*; do mdadm -S $md || echo nope ; done
   ```
5. Wipe the disks and RAIDs.

   ```bash
   ncn# sgdisk --zap-all /dev/sd* 
   ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

   **Note**: On worker nodes, it is a known issue that the sgdisk command sometimes encounters a hard hang. If you see no output from the command for 90 seconds, close the terminal session to the worker node, open a new terminal session to it, and complete the disk wipe procedure by running the above wipefs command.

   See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.
