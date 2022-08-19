# Alternate Storage Pools

- [Description](#description)
- [Use cases](#use-cases)
- [Best practices](#best-practices)
- [Procedures](#procedures)
  - [Create a storage pool](#create-a-storage-pool)
  - [Create and map an `rbd` device](#create-and-map-an-rbd-device)
  - [Mount an `rbd` device](#mount-an-rbd-device)
  - [Move an `rbd` device to another node](#move-an-rbd-device-to-another-node)
  - [Unmount, unmap, and delete an `rbd` device](#unmount-unmap-and-delete-an-rbd-device)
  - [Remove a storage pool](#remove-a-storage-pool)

## Description

Creating, maintaining, and removing Ceph storage pools.

## Use cases

- A landing space for the CSM tarball used for upgrades.
- Temporary space needed for maintenance or pre/post upgrade activities.

## Best practices

- Apply a proper quota to any pools created.
  - This will use storage from the default crush rule which is utilizing every OSD.
  - Improper use of this procedure can have a negative impact on the cluster and space available to running services.
    - Failure to set a quota and not policing space usage can result in the Ceph cluster going into read-only mode.
      - This will cause running services to crash if the space issue is not resolved quickly.
- Cleanup after the criteria for the pool creation has been met.
  - This can be as simple as removing volumes but leaving the pool for future use.

## Procedures

This example shows the creation and mounting of an `rbd` device on `ncn-m001`.

**NOTE:** The commands to create and delete pools or `rbd` devices must be run from a master node or one of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).

### Create a storage pool

The below example will create a storage pool name `csm-release`. The pool name can be changed to better reflect any use cases outside of support for upgrades.
The `3 3` arguments can be left unchanged. For more information on their meaning and possible alternative values, see the Ceph product documentation.

1. (`ncn-ms#`) Create the storage pool.

    ```bash
    ceph osd pool create csm-release 3 3
    ```

    Output:

    ```text
    pool 'csm-release' created
    ```

1. (`ncn-ms#`) Enable `rbd` on the new pool.

    ```bash
    ceph osd pool application enable csm-release rbd
    ```

    Example output:

    ```text
    enabled application 'rbd' on pool 'csm-release'
    ```

1. (`ncn-ms#`) Set a quota on the new pool.

    ```bash
    ceph osd pool set-quota csm-release max_bytes 500G
    ```

    Example output:

    ```text
    set-quota max_bytes = 536870912000 for pool csm-release
    ```

1. (`ncn-ms#`) View the quotas on the new pool.

    ```bash
    ceph osd pool get-quota csm-release
    ```

    Example output:

    ```text
    quotas for pool 'csm-release':
      max objects: N/A
      max bytes  : 500 GiB  (current num bytes: 0 bytes)
    ```

**NOTES:**

- The above example sets the quota to 500 GiB.
  - If this pool is fully utilized it will be using 1.5 TiB of raw space.
  - This space counts against the total space provided by the cluster; Use cautiously.
  - If this pool or any pool reaches 95-100% utilization, then all volumes for the fully utilized pool will go into read-only mode.

### Create and map an `rbd` device

**IMPORTANT:**

- Creating an `rbd` device requires proper access and must be run from a master node or one of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`).
- Mounting a device will occur on the node where the storage needs to be present.

1. (`ncn-ms#`) Create the `rbd` device.

    ```bash
    rbd create -p csm-release release_version --size 100G
    ```

    This command gives no output when successful.

1. (`ncn-ms#`) Map the device.

    ```bash
    rbd map -p csm-release release_version
    ```

    Example output:

    ```text
    /dev/rbd0
    ```

1. (`ncn-ms#`) Show mapped `rbd` devices.

    ```bash
    rbd showmapped
    ```

    Example output:

    ```text
    id  pool         namespace  image            snap  device
    0   csm-release             release_version  -     /dev/rbd0
    ```

**IMPORTANT NOTE:**

- Master nodes normally do not have `rbd` devices mapped via Ceph provisioner.
  - If mapping to a worker node where there are mapped PVCs, then ensure the proper `rbd` device is being captured for the following steps.
  - Failure to do this most likely will result in data corruption or loss.

### Mount an `rbd` device

1. (`ncn#`) Format the device with a file system.

    ```bash
    mkfs.ext4 /dev/rbd0
    ```

    Example output:

    ```text
    mke2fs 1.43.8 (1-Jan-2018)
    Discarding device blocks: done
    Creating filesystem with 26214400 4k blocks and 6553600 inodes
    Filesystem UUID: d5fe6df4-a0ab-49bc-8d49-9cc62700915d
    Superblock backups stored on blocks:
     32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
     4096000, 7962624, 11239424, 20480000, 23887872

    Allocating group tables: done
    Writing inode tables: done
    Creating journal (131072 blocks): done
    Writing superblocks and filesystem accounting information: mkdir done
    ```

1. (`ncn#`) Create a directory for the mount point.

    ```bash
    mkdir -pv /etc/cray/csm/csm-release
    ```

    The output from this command will vary depending on whether or not the directory already exists.
    Example output:

    ```text
    mkdir: created directory '/etc/cray/csm'
    mkdir: created directory '/etc/cray/csm/csm-release'
    ```

1. (`ncn#`) Mount the `rbd` device.

    ```bash
    mount /dev/rbd0 /etc/cray/csm/csm-release/
    ```

    This command gives no output when successful.

1. (`ncn#`) Validate the mount.

    ```bash
    mountpoint /etc/cray/csm/csm-release/
    ```

    Example output:

    ```text
    /etc/cray/csm/csm-release/ is a mountpoint
    ```

### Move an `rbd` device to another node

1. (`ncn#`) Unmap the device on the node where it is currently mapped.

    1. Unmount the `rbd` device.

        ```bash
        umount /etc/cray/csm/csm-release
        ```

    1. Unmap the `rbd` device.

        ```bash
        rbd unmap  -p csm-release release_version
        ```

    1. Show the `rbd` mappings to verify that it has been removed.

        ```bash
        rbd showmapped
        ```

        **NOTE:** There should be no output from the above unless other `rbd` devices are mapped on the node.

1. (`ncn#`) Map and mount the device on the destination node ((that is, the node where the `rbd` device is being remapped to).

    1. Map the `rbd` device.

        ```bash
        rbd map -p csm-release release_version
        ```

        Example output:

        ```text
        /dev/rbd0
        ```

    1. Show the `rbd` mappings.

        ```bash
        rbd showmapped
        ```

        Example output:

        ```text
        id  pool         namespace  image            snap  device
        0   csm-release             release_version  -     /dev/rbd0
        ```

    1. Create the mount point directory, if it does not already exist.

        ```bash
        mkdir -pv /etc/cray/csm/csm-release 
        ```

        The output from this command will vary depending on whether or not the directory already exists.

    1. Mount the `rbd` device over the mount point.

        ```bash
        mount /dev/rbd0 /etc/cray/csm/csm-release
        ```

        This command gives no output when successful.

    1. Validate the mount.

        ```bash
        mountpoint /etc/cray/csm/csm-release/
        ```

        Example output:

        ```text
        /etc/cray/csm/csm-release/ is a mountpoint
        ```

### Unmount, unmap, and delete an `rbd` device

1. (`ncn#`) Unmount the `rbd` device.

    ```bash
    umount /etc/cray/csm/csm-release
    ```

1. (`ncn#`) Unmap the `rbd` device.

    ```bash
    rbd unmap  -p csm-release release_version
    ```

1. (`ncn#`) Show the `rbd` mappings to verify that it has been removed.

    ```bash
    rbd showmapped
    ```

    **NOTE:** There should be no output from the above unless other `rbd` devices are mapped on the node.

1. (`ncn#`) Remove the `rbd` device.

    ```bash
    rbd remove csm-release/release_version
    ```

    Output:

    ```text
    Removing image: 100% complete...done.
    ```

### Remove a storage pool

**CRITICAL NOTE:** This will permanently delete data.

1. (`ncn-ms#`) Check to see if the cluster is allowing pool deletion.

    ```bash
    ceph config get mon mon_allow_pool_delete
    ```

    Example output:

    ```text
    true
    ```

    If the above command shows `false`, then enable it using the following command:

    ```bash
    ceph config set mon mon_allow_pool_delete true
    ```

1. (`ncn-sm#`) Remove the pool.

    ```bash
    ceph osd pool rm csm-release csm-release --yes-i-really-really-mean-it
    ```

    Example output:

    ```text
    pool 'csm-release' removed
    ```
