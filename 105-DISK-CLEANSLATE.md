# Disk Cleanslate

This page will detail how disks are wiped and work-arounds for wedged 
disks.

Any process covered on this page will be covered by the installer.

> **Everything in this guide should be considered DESTRUCTIVE**.

After following these procedures an NCN can be rebooted and redeployed.

### Basic Wipe

- Wipe Magic Bits

```bash
# Print off the disks for verification:
ncn:~ # ls -1 /dev/sd* /dev/disk/bu-label/*

# Wipe the disks and the RAIDs:
ncn:~ # wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

### Advanced Wipe

- Clear Ceph
- Wipe Magic Bits

```bash
# Delete CEPH Volumes
ncn:~ # ls -1 /dev/sd* /dev/disk/bu-label/*
ncn:~ # vgremove -f --select 'vg_name=~ceph*'

# Wipe the disks and RAIDs:
ncn:~ # wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

### Full-Wipe

- Clear Ceph
- Wipe Magic Bits
- Zero disks
- Stop RAIDs

```bash
# Delete CEPH Volumes
ncn:~ # ls -1 /dev/sd* /dev/disk/bu-label/*
ncn:~ # vgremove -f --select 'vg_name=~ceph*'


# Nicely stop the RAIDs, or try.
ncn:~ # for md in /dev/md/*; do mdadm -S $md || echo nope ; done


# Wipe the disks and RAIDs:
ncn:~ # sgdisk --zap-all /dev/sd* 
ncn:~ # wipefs --all --force /dev/sd* /dev/disk/by-label/*
```

