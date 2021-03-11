# Disk Cleanslate


* [Disk Cleanslate](#disk-cleanslate)
* [Use Cases](#use-cases)
    * [Basic Wipe](#basic-wipe)
    * [Advanced Wipe](#advanced-wipe)
    * [Full Wipe](#full-wipe)

This page will detail how disks are wiped and workarounds for wedged 
disks.

Any process covered on this page will be covered by the installer.

> **Everything in this guide should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

<a name="use-cases"></a>
## Use Cases

Ideally the Basic Wipe is enough, and should be tried first. All of these procedures may be ran from Linux or an initramFS/initrd emergency shell.

- Adding a node that isn't bare.
- Adopting new disks that aren't bare.
- Fresh-installing.

<a name="basic-wipe"></a>
### Basic Wipe

These basic wipe instructions can be executed on **any ncn nodes** (master, worker and storage).

- Wipe Magic Bits

```bash
# Enable extended globbing for use in subsequent commands
ncn# shopt -s extglob

# Print off the disks for verification:
ncn# ls -1 /dev/sd+([a-z]) /dev/disk/by-label/*

# Wipe the disks and the RAIDs:
ncn# wipefs --all --force /dev/sd+([a-z]) /dev/disk/by-label/*
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
      
The thing to verify is that there are no error messages in the output.

<a name="advanced-wipe"></a>
### Advanced Wipe

This section is specific to **storage nodes**.

- Clear Ceph
- Wipe Magic Bits

```bash
# Delete CEPH Volumes
# Enable extended globbing for use in subsequent commands
ncn-s# shopt -s extglob

ncn-s# systemctl stop ceph-osd.target # Make sure the OSDs (if any) are not running
ncn-s# ls -1 /dev/sd+([a-z]) /dev/disk/by-label/*
ncn-s# vgremove -f --select 'vg_name=~ceph*'

# Wipe the disks and RAIDs:
ncn# wipefs --all --force /dev/sd+([a-z]) /dev/disk/by-label/*
```

See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.

<a name="full-wipe"></a>
### Full-Wipe

This section is also specific to **storage nodes**.

- Clear Ceph
- Wipe Magic Bits
- Zero disks
- Stop RAIDs

```bash
# Enable extended globbing for use in subsequent commands
ncn-s# shopt -s extglob

# Delete CEPH Volumes
ncn-s# systemctl stop ceph-osd.target # Make sure the OSDs (if any) are not running
ncn-s# ls -1 /dev/sd+([a-z]) /dev/disk/by-label/*
ncn-s# vgremove -f --select 'vg_name=~ceph*'

# Nicely stop the RAIDs, or try.
ncn# for md in /dev/md/*; do mdadm -S $md || echo nope ; done

# Wipe the disks and RAIDs:
ncn# sgdisk --zap-all /dev/sd+([a-z]) 
ncn# wipefs --all --force /dev/sd+([a-z]) /dev/disk/by-label/*
```

See [Basic Wipe](#basic-wipe) section for expected output from the wipefs command.
