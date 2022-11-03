# Troubleshoot Ceph-Mon Processes Stopping and Exceeding Max Restarts

Troubleshoot an issue where all of the ceph-mon processes stop and exceed their maximum amount of attempts at restarting. This bug corrupts the health of the Ceph cluster.

Return the Ceph cluster to a healthy state by resolving issues with ceph-mon processes.

## Prerequisites

This procedure requires admin privileges.

## Procedure

See [Collect Information about the Ceph Cluster](Collect_Information_About_the_Ceph_Cluster.md) for more information on how to interpret the output of the Ceph commands used in this procedure.

1. Log on to the manager nodes via `ssh`.

    The commands in the next step will need to be run on each manager node.

1. Verify the ceph-mon process is running as expected.

    1. Check to see if the ceph-mon process is running on all of the manager nodes.

        This command needs to be run on each manager node to determine where the issues are occurring. Make a note of which nodes do not have the ceph-mon process running.

        ```bash
        ncn-m001# ps -ef |grep ceph-mon
        ```

        Example output:

        ```
        root     24465 24175  0 10:04 pts/0    00:00:00 grep ceph-mon
        ceph     33480     1  0 Jan15 ?        00:11:36 /usr/bin/ceph-mon -f --cluster ceph --id ncn-m001 --setuser ceph --setgroup ceph  <<-- If missing, it is not running
        ```

    1. Restart the ceph-mon process on any node where it was not running.

        This is expected to crash again, but this is a good way to verify there is an issue.

        ```bash
        ncn-s00(1/2/3)# systemctl daemon-reload
        ncn-s00(1/2/3)# ceph orch daemon restart mon.<hostname>
        ```

1. Check the health of the Ceph cluster on one of the manager nodes.

    This command will report a HEALTH\_WARN status. There will be a message below this warning indicating that a ceph-mon node or multiple ceph-mon nodes are out of quorum.

    ```bash
    ncn-s00(1/2/3)# ceph -s
    ```

    To watch nodes that drop out of quorum, run the following command:

    ```bash
    ncn-s00(1/2/3)# ceph -ws
    ```

    Once it is clear that the ceph-mon processes keep crashing across all of the manager nodes, proceed to the next step. If only a single ceph-mon process on a manager node is having issues, then a different issue is occurring.

1. Restart the ceph-mds services on all manager nodes.

    ```bash
    ncn-s00(1/2/3)# ceph orch daemon restart mds.cephfs.<container id>
    ```

1. Restart the ceph-mon process on all manager nodes.

    ```bash
    ncn-m001# systemctl daemon-reload
    ncn-s00(1/2/3)# ceph orch daemon restart mon.<hostname>
    ```

1. Monitor the cluster to ensure the ceph-mon processes are running on all manager nodes.

    The health status should return to reporting as HEALTH\_OK. Monitor the health of the cluster over the next 30 minutes to ensure the debugging was successful.

    ```bash
    ncn-s00(1/2/3)# ceph -s
    ```
