# Shrink Ceph OSDs

This procedure describes how to remove an OSD\(s\) from a Ceph cluster. Once the OSD is removed, the cluster is also rebalanced to account for the changes. Use this procedure to reduce the size of a cluster or to replace hardware.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Log in as `root` on the first master node \(`ncn-m001`\).

1. Monitor the progress of the OSDs that have been added.

    ```bash
    ncn-m001# ceph -s
    ```

1. View the status of each OSD and see where they reside.

    ```bash
    ncn-m001# ceph osd tree
    ```

1. Reweigh the OSD\(s\) being removed to rebalance the cluster.

    The first two substeps below can be skipped if there is a down drive and OSD.

    1. Change the weight of the OSD being removed to 0.

        The OSD\_ID value should be replaced with the ID of the OSD being removed. For example, if the ID is osd.1, the OSD\_ID value would be 1 in the command below.

        ```bash
        ncn-m001# ceph osd reweight osd.OSD_ID 0
        ```

    1. Change the weight in the CRUSH map to 0.

        ```bash
        ncn-m001# ceph osd crush reweight osd.OSD_ID 0
        ```

    1. Prevent the removed OSD from getting marked up.

        ```bash
        ncn-m001# ceph osd set noup
        ```

1. Remove the OSD after the reweighing work is complete.

    1. Take down the OSD being removed.

        ```bash
        ncn-m001# ceph osd down osd.OSD_ID
        ```

    1. Destroy the OSD.

        ```bash
        ncn-m001# ceph osd destroy osd.OSD_ID
        ```

    1. Remove the OSD authentication key.

        ```bash
        ncn-m001# ceph auth rm osd.OSD_ID
        ```

    1. Remove the OSD.

        ```bash
        ncn-m001# ceph osd rm osd.OSD_ID
        ```

    1. Remove the OSD from the CRUSH map.

        ```bash
        ncn-m001# ceph osd crush rm osd.OSD_ID
        ```

    1. Remove references to the OSDs on the storage node\(s\) they were located on.

        The following commands must be run on the storage node\(s\) that held the OSDs being removed.

        ```bash
        ncn-s001# umount /var/lib/ceph/osd/ceph-OSD_ID
        ncn-s001# rm -rf /var/lib/ceph/osd/ceph-OSD_ID
        ```

1. Clear the flags that were set earlier in the procedure.

    ```bash
    ncn-m001# ceph osd unset noup
    ```

1. Monitor the cluster until the rebalancing is complete.

    ```bash
    ncn-m001# ceph -s
    ```


