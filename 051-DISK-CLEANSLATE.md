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

- Wipe Magic Bits

```bash
# Print off the disks for verification:
ncn# ls -1 /dev/sd* /dev/disk/by-label/*

# Wipe the disks and the RAIDs:
ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

<a name="advanced-wipe"></a>
### Advanced Wipe

- Clear Ceph
- Wipe Magic Bits

```bash
# Delete CEPH Volumes
ncn-s# systemctl stop ceph-osd.target # Make sure the OSDs (if any) are not running
ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
ncn-s# vgremove -f --select 'vg_name=~ceph*'

# Wipe the disks and RAIDs:
ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

<a name="full-wipe"></a>
### Full-Wipe

- Clear Ceph
- Wipe Magic Bits
- Zero disks
- Stop RAIDs

```bash
# Delete CEPH Volumes
ncn-s# systemctl stop ceph-osd.target # Make sure the OSDs (if any) are not running
ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
ncn-s# vgremove -f --select 'vg_name=~ceph*'


# Nicely stop the RAIDs, or try.
ncn# for md in /dev/md/*; do mdadm -S $md || echo nope ; done


# Wipe the disks and RAIDs:
ncn# sgdisk --zap-all /dev/sd* 
ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

