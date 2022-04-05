# Shrink the Ceph Cluster

This procedure describes how to remove a Ceph node from the Ceph cluster. Once the node is removed, the cluster is also rebalanced to account for the changes. Use this procedure to reduce the size of a cluster.

## Prerequisites

* This procedure requires administrative privileges.
* 3 ssh sessions.
  * 1 to monitor the cluster.
  * 1 to perform ***cluster wide*** actions from a ceph-mon node.
  * 1 to perform ***node only*** actions on the node being removed.

**IMPORTANT NOTES:**

> * Permanent removal of `ncn-s001, `ncn-s002`, or `ncn-s003` is **NOT SUPPORTED**. They can only be rebuilt in place or replaced with new hardware.
>   * This is due to the ceph mon and mgr processes running on them.
> * Always ensure you have the free capacity to remove the node(s) prior to performing this task.
> * When removing a node other than ncn-s001/2/3, then you will have to adjust the SMF pools quotas accordingly.
> * Removal of more than one node at a time is **NOT SUPPORTED** due to the SMA telemetry pool only having 2 copies.

## Procedure

1. Log in as `root` on one of the first three storage nodes (ncn-s001/2/3) or a master node.

2. Monitor the progress of the OSDs that have been added.

    ```bash
    watch ceph -s
    ```

3. View the status of each OSD and see where they reside.

    ```bash
    ceph osd tree
    ```

4. Set the `NODE` variable

   ```bash
   export NODE=<node being removed>
   ```

5. Reweigh the OSD\(s\) ***on the node being removed*** to rebalance the cluster.


    1. Change the weight and crush weight of the OSD being removed to 0.

        ```bash
        for osd in $(ceph osd ls-tree $NODE);
        do
          ceph osd reweight osd.$osd 0;
          ceph osd crush reweight osd.$osd 0;
        done
        ```

    2. Watch the session running your watch `ceph -s` until the cluster status is **HEALTH_OK**

6. Remove the OSD after the reweighing work is complete.

    ```bash
    for osd in $(ceph osd ls-tree $NODE);
    do
      ceph osd down osd.$osd;
      ceph osd destroy osd.$osd --force;
      ceph osd purge osd.$osd --force;
    done
    ```

7. Remove the ceph configuration from the node

   On the ***node being removed***

    ```bash
    cephadm rm-cluster --fsid $(cephadm ls|jq -r .[1].fsid) --force
    ```

8. Remove the node from the crush map

   ```bash
   ceph osd crush rm $NODE
   ```

9. On session running `ceph -s` verify that the status is HEALTH_OK, if so, then you are finished.
