# Wipe NCN Disks for Reinstallation

This page will detail how disks are wiped and includes workarounds for wedged disks.
Any process covered on this page will be covered by the installer.

> **Everything in this section should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

Ideally the Basic Wipe is enough, and should be tried first. All type of disk wipe can be run from Linux or an initramFS/initrd emergency shell. 

The following are potential use cases for wiping disks:

   * Adding a node that isn't bare.
   * Adopting new disks that aren't bare.
   * Fresh-installing.

<a name="basic-wipe"></a>

### Topics: 
   * [Basic Wipe](#basic-wipe)
   * [Advanced Wipe](#advanced-wipe)
   * [Full Wipe](#full-wipe)

## Details

<a name="use-cases"></a>
### Basic Wipe

A basic wipe includes wiping the disks and all of the RAIDs.  These basic wipe instructions can be
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
### Advanced Wipe

This section is specific to utility storage nodes. An advanced wipe includes deleting the Ceph volumes, and then
wiping the disks and RAIDs.

1. Delete CEPH Volumes

   ```bash
   ncn-s# systemctl stop ceph-osd.target

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
### Full-Wipe

This section is specific to utility storage nodes. A full wipe includes deleting the Ceph volumes, stopping the
RAIDs, zeroing the disks, and then wiping the disks and RAIDs.

1. Delete CEPH Volumes

   ```bash
   ncn-s# systemctl stop ceph-osd.target

   Make sure the OSDs (if any) are not running after running the first command.

   ```bash
   ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
   ncn-s# vgremove -f --select 'vg_name=~ceph*'
   ```

1. Stop the RAIDs.

   ```bash
   ncn-s# for md in /dev/md/*; do mdadm -S $md || echo nope ; done
   ```

1. Remove auxillary LVMs

   ```bash
   ncn-s# vgremove -f --select 'vg_name=~metal*'
   ```

1. Wipe the disks and RAIDs.

   ```bash
   ncn-s# sgdisk --zap-all /dev/sd* 
   ncn-s# wipefs --all --force /dev/sd* /dev/disk/by-label/*
   ```

See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.
