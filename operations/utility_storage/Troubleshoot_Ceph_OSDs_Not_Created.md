# Troubleshoot Ceph OSDs Not Being Created on Disks

Use this procedure to examine the Ceph cluster and troubleshoot issues where Ceph OSDs are not being created on disks.
This procedure will help start an OSD on an available disk or a disk marked as unavailable.

## Procedure

1. (`ncn-s001/2/3#`) Observe the current Ceph OSDs running.

    ```bash
    ceph osd tree
    ```

    Example output:

    ```bash
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         34.93088  root default
    -3         17.46544      host ncn-s001
    0    ssd   3.49309          osd.0          up   0.92000  1.00000
    4    ssd   3.49309          osd.4          up   0.92000  1.00000
    -7         10.47926      host ncn-s002
    1    ssd   3.49309          osd.1          up   0.92000  1.00000
    3    ssd   3.49309          osd.3          up   0.89999  1.00000
    -5          6.98618      host ncn-s003
    2    ssd   3.49309          osd.2          up   0.89999  1.00000
    5    ssd   3.49309          osd.5          up   0.89999  1.00000
    ```

1. (`ncn-s001/2/3#`) Observe what disks are being utilized by Ceph.

    ```bash
    lsblk
    ```

    Example output:

    ```text
    NAME                                                                                        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
    loop0                                                                                         7:0    0   2.3G  1 loop  /run/rootfsbase
    sda                                                                                           8:0    1   3.5T  0 disk
    sdb                                                                                           8:16   1   3.5T  0 disk
    sdc                                                                                           8:32   1   3.5T  0 disk
    sdd                                                                                           8:48   1   3.5T  0 disk
    sde                                                                                           8:64   1 447.1G  0 disk
    ├─sde1                                                                                        8:65   1   476M  0 part
    │ └─md124                                                                                     9:124  0 475.9M  0 raid1 /metal/recovery
    ├─sde2                                                                                        8:66   1  22.8G  0 part
    │ └─md126                                                                                     9:126  0  22.8G  0 raid1 /run/initramfs/live
    ├─sde3                                                                                        8:67   1 139.7G  0 part
    │ └─md125                                                                                     9:125  0 139.6G  0 raid1 /run/initramfs/overlayfs
    └─sde4                                                                                        8:68   1 139.7G  0 part
    └─md127                                                                                     9:127  0 279.1G  0 raid0
        ├─metalvg0-CEPHETC                                                                      254:2    0    10G  0 lvm   /etc/ceph
        ├─metalvg0-CEPHVAR                                                                      254:3    0    60G  0 lvm   /var/lib/ceph
        └─metalvg0-CONTAIN                                                                      254:4    0    60G  0 lvm   /var/lib/containers/storage/overlay
                                                                                                                        /var/lib/containers
    sdf                                                                                           8:80   1 447.1G  0 disk
    ├─sdf1                                                                                        8:81   1   476M  0 part
    │ └─md124                                                                                     9:124  0 475.9M  0 raid1 /metal/recovery
    ├─sdf2                                                                                        8:82   1  22.8G  0 part
    │ └─md126                                                                                     9:126  0  22.8G  0 raid1 /run/initramfs/live
    ├─sdf3                                                                                        8:83   1 139.7G  0 part
    │ └─md125                                                                                     9:125  0 139.6G  0 raid1 /run/initramfs/overlayfs
    └─sdf4                                                                                        8:84   1 139.7G  0 part
    └─md127                                                                                     9:127  0 279.1G  0 raid0
        ├─metalvg0-CEPHETC                                                                      254:2    0    10G  0 lvm   /etc/ceph
        ├─metalvg0-CEPHVAR                                                                      254:3    0    60G  0 lvm   /var/lib/ceph
        └─metalvg0-CONTAIN                                                                      254:4    0    60G  0 lvm   /var/lib/containers/storage/overlay
                                                                                                                        /var/lib/containers
    sdg                                                                                           8:96   0   3.5T  0 disk
    └─ceph--8f54f12c--5fe1--4f4e--9cb0--8102f2134aee-osd--block--6187f807--15d9--4660--8a57--b199110aaf52
                                                                                                254:1    0   3.5T  0 lvm
    sdh                                                                                           8:112  0   3.5T  0 disk
    └─ceph--774fea44--d851--42d0--9d32--148314da8c0f-osd--block--d34f2fc7--6554--414f--8746--6671e2ab3b5e
                                                                                                254:0    0   3.5T  0 lvm
    ```

    In this example, only `/dev/sdg` and `/dev/sdh` are being utilized by Ceph OSDs.
    It is expected that `/dev/sda`, `/dev/sdb`, `/dev/sdc`, `/dev/sdd` would also be utilized by Ceph OSDs.
    In this case, OSDs should be added on the four disks that do not currently have OSDs.

1. (`ncn-s001/2/3#`) If some disks do not have Ceph OSDs on them, continue with this procedure to add them. There are two different paths to add OSDs.
To determine which path to follow, run the following command to see if Ceph finds the available disks.

    ```bash
    ceph orch device ls
    ```

    1. Possible output 1. This output shows that Ceph is not able to discover the disks that are not being used.
    Ceph does not see `/dev/sda`, `/dev/sdb`, `/dev/sdc`, `/dev/sdd`.
    If the output looks like what is below, follow [Manually add OSDs to disks not discovered by Ceph](#manually-add-osds-to-disks-not-discovered-by-ceph).

        ```bash
        HOST      PATH        TYPE  DEVICE ID                                   SIZE  AVAILABLE  REFRESHED  REJECT REASONS
        ncn-s001  /dev/md127  ssd                        299G  No         2m ago     locked
        ncn-s001  /dev/sdg    ssd   SAMSUNG_MZ7LH30215  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s001  /dev/sdh    ssd   SAMSUNG_MZ7LH30231  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s002  /dev/md127  ssd                        299G  No         12m ago    locked
        ncn-s002  /dev/sdg    ssd   SAMSUNG_MZ7LH30394  3840G  No         12m ago    Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s002  /dev/sdh    ssd   SAMSUNG_MZ7LH30395  3840G  No         12m ago    Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s003  /dev/md127  ssd                        299G  No         2m ago     locked
        ncn-s003  /dev/sdg    ssd   SAMSUNG_MZ7LH30329  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s003  /dev/sdh    ssd   SAMSUNG_MZ7LH30412  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ```

    1. Possible output 2. The output below shows that Ceph discovers the devices as available.
    If the output looks like what is below, follow [Add OSDs to disks discovered by Ceph](#add-osds-to-disks-discovered-by-ceph).

        ```bash
        HOST      PATH        TYPE  DEVICE ID            SIZE  AVAILABLE  REFRESHED  REJECT REASONS
        ncn-s001  /dev/md127  ssd                        299G  No         2m ago     locked
        ncn-s001  /dev/sda    ssd                        299G  Yes        2m ago
        ncn-s001  /dev/sdb    ssd                        299G  Yes        2m ago
        ncn-s001  /dev/sdc    ssd                        299G  Yes        2m ago
        ncn-s001  /dev/sdd    ssd                        299G  Yes        2m ago
        ncn-s001  /dev/sdg    ssd   SAMSUNG_MZ7LH30215  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s001  /dev/sdh    ssd   SAMSUNG_MZ7LH30231  3840G  No         2m ago     Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s002  /dev/md127  ssd                        299G  No         12m ago    locked
        ncn-s002  /dev/sda    ssd                        299G  Yes        2m ago
        ncn-s002  /dev/sdb    ssd                        299G  Yes        2m ago
        ncn-s002  /dev/sdc    ssd                        299G  Yes        2m ago
        ncn-s002  /dev/sdd    ssd                        299G  Yes        2m ago
        ncn-s002  /dev/sdg    ssd   SAMSUNG_MZ7LH30394  3840G  No         12m ago    Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s002  /dev/sdh    ssd   SAMSUNG_MZ7LH30395  3840G  No         12m ago    Insufficient space (<10 extents) on vgs, LVM detected, locked
        ncn-s003  /dev/md127  ssd                        299G  No         2m ago     locked
        ...
        ```

### Manually add OSDs to disks not discovered by Ceph

If the disks are not discovered by Ceph, it is likely due to the fact they are marked as removable. This can be checked by running `lsblk` and observing if a value of 1 is seen in the removable column.
In order to add these disks to Ceph, run the `bootstrap_osd_on_removable_disk.sh` script.

1. (`ncn-s#`) Copy the `bootstrap_osd_on_removable_disk.sh` script from `ncn-m001` to the node where the OSD should be added.

    ```bash
    scp ncn-m001:/usr/share/doc/csm/scripts/operations/ceph/bootstrap_osd_on_removable_disk.sh .
    ```

1. (`ncn-s#`) Execute `bootstrap_osd_on_removable_disk.sh` script on the node where the OSD should be added. Pass the device that the OSD should be created on as an argument.

    ```bash
    ./bootstrap_osd_on_removable_disk.sh /dev/<disk>
    ```

    The above command will not create the OSD. It will describe where the OSD will be created as a warning. In order to create the OSD, pass in `--force`.

    ```bash
    ./bootstrap_osd_on_removable_disk.sh /dev/<disk> --force
    ```

The OSD should have been created on the disk. Run the above commands to create OSDs on all disks that are available.

If the OSD is created but does not start after three minutes, run `ceph orch daemon restart osd.<osd_id>`.

**Note:** When adding OSDs to removable disks or disks that are not discovered by Ceph, these OSDs are "unmanaged".
This means that they are not managed by the Ceph orchestrator. This does not impact the operation of the Ceph cluster.
Also note, this script may need to be rerun after the storage node is upgraded or rebuilt to recreate the OSDs.

### Add OSDs to disks discovered by Ceph

1. (`ncn-s001/2/3#`) Add OSDs on all available devices. First, run the `dry-run` to see which disks OSDs will be created on.

    ```bash
    ceph orch apply osd --all-available-devices --dry-run
    ```

1. (`ncn-s001/2/3#`) Create OSDs on all available devices.

    ```bash
    ceph orch apply osd --all-available-devices --dry-run
    ```
