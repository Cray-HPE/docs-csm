# Shrink the Ceph Cluster

This procedure describes how to remove a Ceph node from the Ceph cluster. Once the node is removed, the cluster is also rebalanced to account for the changes. Use this procedure to reduce the size of a cluster.

## Prerequisites

* This procedure requires administrative privileges.
* 3 ssh sessions.
  * 1 to monitor the cluster.
  * 1 to perform ***cluster wide*** actions from a ceph-mon node.
  * 1 to perform ***node only*** actions on the node being removed.

## IMPORTANT NOTES

* Permanent removal of `ncn-s001`, `ncn-s002`, or `ncn-s003` is **NOT SUPPORTED**. They can only be rebuilt in place or replaced with new hardware.
    * This is due to the Ceph mon and mgr processes running on them.
* Always ensure you have the free capacity to remove the node(s) prior to performing this task.
* When removing a node other than `ncn-s001`, `ncn-s002`, or `ncn-s003`, the SMF pools quotas must be adjusted accordingly.
* Removal of more than one node at a time is **NOT SUPPORTED** because the SMA telemetry pool only has 2 copies.

## Procedure

1. Log in as `root` on `ncn-s001`, `ncn-s002`, `ncn-s003`, or a master node.

1. Monitor the progress of the OSDs that have been added.

    ```bash
    ncn# watch ceph -s
    ```

1. View the status of each OSD and see where they reside.

    ```bash
    ncn# ceph osd tree
    ```

1. Set the `NODE` variable.

   ```bash
   ncn# export NODE=<node being removed>
   ```

1. Reweigh the OSD\(s\) ***on the node being removed*** to rebalance the cluster.

    Run from `ncn-s001`, `ncn-s002`, or `ncn-s003`:

    1. Change the weight and CRUSH weight of the OSD being removed to 0.

        ```bash
        ncn-s# for osd in $(ceph osd ls-tree $NODE); do
                  ceph osd reweight osd.$osd 0;
                  ceph osd crush reweight osd.$osd 0;
               done
        ```

    1. Watch the `ceph -s` output until the cluster status is `HEALTH_OK` and the **Rebalancing** has completed.

1. Remove the OSD after the reweighing work is complete.

    Run from `ncn-s001`, `ncn-s002`, or `ncn-s003`:

    ```bash
    ncn-s# for osd in $(ceph osd ls-tree $NODE); do
              ceph osd down osd.$osd;
              ceph osd destroy osd.$osd --force;
              ceph osd purge osd.$osd --force;
           done
    ```

1. Remove the Ceph configuration from the node

   On the ***node being removed***

    ```bash
    ncn-s# cephadm rm-cluster --fsid $(cephadm ls|jq -r .[1].fsid) --force
    ```

1. Remove the node from the CRUSH map.

    Run from `ncn-s001`, `ncn-s002`, or `ncn-s003`:

    ```bash
    ncn-s# ceph osd crush rm $NODE
    ```

1. In the output from `ceph -s`, verify that the status is `HEALTH_OK`.
