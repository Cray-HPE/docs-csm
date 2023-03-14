# Check the Health of etcd Clusters

Check to see if all of the etcd clusters have the correct number of healthy pods and a healthy cluster database.
Any clusters that do not have healthy pods will need to be either restored from backup or rebuilt.

## Prerequisites

This procedure requires root privileges.

## Procedure

1. (`ncn-mw#`) Check the health of the clusters.

    To check the health of the etcd clusters in the services namespace without TLS authentication:

    ```bash
    /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_health_status
    ```

    Example output:

    ```text
    **************************************************************************

    === Check the Health of the Etcd Clusters in all Namespaces. ===
    === Verify a "healthy" Report for Each Etcd Pod. ===
    Fri 10 Mar 2023 07:52:09 PM UTC
    ### cray-bos-bitnami-etcd-0 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 4.166761ms
    ### cray-bos-bitnami-etcd-1 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 4.697124ms
    ### cray-bos-bitnami-etcd-2 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 4.119712ms
    --- PASSED ---

    [...]
    ```

    If any of the etcd clusters are not healthy, refer to [Restore an etcd Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md).

1. (`ncn-mw#`) Check the number of pods in each cluster.

    Each cluster should contain at least three pods.

    ```bash
    /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_cluster_balance
    ```

    Example output:

    ```text
    **************************************************************************
    
    === Check the Number of Pods in Each Cluster. Verify they are Balanced. ===
    === Each cluster should contain at least three pods, but may contain more. ===
    === Ensure that no two pods in a given cluster exist on the same worker node. ===
    Fri 10 Mar 2023 07:54:22 PM UTC
    cray-bos-bitnami-etcd-0                                           2/2     Running     0          22h     10.32.0.76    ncn-w002   <none>           <none>
    cray-bos-bitnami-etcd-1                                           2/2     Running     0          22h     10.40.0.8     ncn-w003   <none>           <none>
    cray-bos-bitnami-etcd-2                                           2/2     Running     0          22h     10.44.0.58    ncn-w001   <none>           <none>
    
     --- PASSED ---
    ```

    If the etcd clusters have fewer than three pods in a 'Running' state, see [Restore an etcd Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md).

    - To check the health of all of the etcd clusters` databases:

        ```bash
        /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_database_health
        ```

        Example output:

        ```text
        **************************************************************************

        === Check the health of Etcd Cluster's database in the Services Namespace. ===
        === PASS or FAIL status returned. ===
        ### cray-bos-bitnami-etcd-0 Etcd Database Check: ###
        PASS: OK foo fooCheck 1
        ### cray-bos-bitnami-etcd-1 Etcd Database Check: ###
        PASS: OK foo fooCheck 1
        ### cray-bos-bitnami-etcd-2 Etcd Database Check: ###
        PASS: OK foo fooCheck 1
        [...]
        ```

    If any of the etcd cluster databases are not healthy, then refer to the following procedures:

    - [Check for and Clear etcd Cluster Alarms](Check_for_and_Clear_etcd_Cluster_Alarms.md)
    - [Clear Space in an etcd Cluster Database](Clear_Space_in_an_etcd_Cluster_Database.md)
