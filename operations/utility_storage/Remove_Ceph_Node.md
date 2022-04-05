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

1. Regenerate Rados-GW Load Balancer Configuration.

    Run from `ncn-s001`, `ncn-s002`, or `ncn-s003`:

    1. Update the existing HAProxy configuration to remove the node from the configuration.

        ```bash
        ncn-s# vi /etc/haproxy/haproxy.cfg
        ```

        This example removes `ncn-s004` from the `backend rgw-backend`.

        ```
        ...
        backend rgw-backend
            option forwardfor
            balance static-rr
            option httpchk GET /
                server server-ncn-s001-rgw0 10.252.1.6:8080 check weight 100
                server server-ncn-s002-rgw0 10.252.1.5:8080 check weight 100
                server server-ncn-s003-rgw0 10.252.1.4:8080 check weight 100
                server server-ncn-s004-rgw0 10.252.1.13:8080 check weight 100   <--- Line to remove
        ...
        ```

    1. Copy the HAproxy configuration from `ncn-s001` to all the storage nodes. Adjust the command based on the number of storage nodes.

        ```bash
        ncn-s001# pdcp -w ncn-s00[2-(end node number)] /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
        ```

   1. Restart the services on all the storage nodes, and stop it on the node that is being removed.

        ```bash
        ncn# pdsh -w ncn-s00[1-(end node number)] -f 2 'systemctl restart haproxy.service'
        ncn# pdsh -w $NODE 'systemctl stop haproxy.service'
        ```

    1. Redeploy the Rados Gateway containers to adjust the placement group.

        ```bash
        ncn-ms# ceph orch apply rgw site1 zone1 --placement="<num-daemons> <node1 node2 node3 node4 ... >" --port=8080
        ```

        For example:

        ```bash
        ncn-ms# ceph orch apply rgw site1 zone1 --placement="3 ncn-s001 ncn-s002 ncn-s003" --port=8080
        ```

    1. Verify the Rados Gateway is running on the desired nodes.

        ```bash
        ncn-ms# ceph orch ps --daemon_type rgw
        ```

        Example output:

        ```
        NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                         IMAGE ID      CONTAINER ID
        rgw.site1.zone1.ncn-s001.kvskqt  ncn-s001  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   6e323878db46
        rgw.site1.zone1.ncn-s002.tisuez  ncn-s002  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   278830a273d3
        rgw.site1.zone1.ncn-s003.nnwuqy  ncn-s003  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   a9706e6d7a69
        ```
  
1. Remove the node from the cluster.

    Run from `ncn-s001`, `ncn-s002`, or `ncn-s003`:

    ```bash
    ncn-s# ceph orch host rm $NODE
    ```

1. Remove the Ceph configuration from the node.

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
