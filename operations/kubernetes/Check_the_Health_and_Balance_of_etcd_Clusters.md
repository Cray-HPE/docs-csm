# Check the Health and Balance of etcd Clusters

Check to see if all of the etcd clusters have healthy pods, are balanced, and have a healthy cluster database.
A balanced etcd cluster has at least three pods which are running on different worker nodes.

Any clusters that do not have healthy pods will need to be rebuilt. Kubernetes cluster data will not be stored as efficiently when etcd clusters are not balanced.

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
    ***************************************************************************
    === Check the Health of the Etcd Clusters in the Services Namespace. ===
    === Verify a "healthy" Report for Each Etcd Pod. ===
    Tue 06 Feb 2024 12:22:52 AM UTC
    ### cray-bos-etcd-4jzztgq6r2 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.655262ms
    ### cray-bos-etcd-65g79k7lwn ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.574994ms
    ### cray-bos-etcd-cxf2j9mc2h ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 3.371937ms
    ### cray-bss-etcd-7nqbkzv8cm ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 3.242291ms
    ### cray-bss-etcd-qxdjlbh2gf ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 3.07309ms
    ### cray-bss-etcd-vrhlrxs2bd ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.816625ms
    ### cray-cps-etcd-fqmgpbfddn ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.512889ms
    ### cray-cps-etcd-fs9tkqsd8q ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.420555ms
    ### cray-cps-etcd-qs9zps8p4d ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 3.283223ms
 
    [...]

     --- PASSED --- 
    ```

    If any of the etcd clusters are not healthy, refer to [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

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
    Tue 06 Feb 2024 12:25:57 AM UTC
    cray-bos-etcd-4jzztgq6r2                                          1/1     Running           4          159d    10.45.0.102     ncn-w003   <none>           <none>
    cray-bos-etcd-65g79k7lwn                                          1/1     Running           5          154d    10.38.128.91    ncn-w004   <none>           <none>
    cray-bos-etcd-cxf2j9mc2h                                          1/1     Running           1          10h     10.34.0.77      ncn-w001   <none>           <none>

    cray-bss-etcd-7nqbkzv8cm                                          1/1     Running           5          159d    10.45.0.111     ncn-w003   <none>           <none>
    cray-bss-etcd-qxdjlbh2gf                                          1/1     Running           4          154d    10.38.128.78    ncn-w004   <none>           <none>
    cray-bss-etcd-vrhlrxs2bd                                          1/1     Running           1          10h     10.34.0.83      ncn-w001   <none>           <none>

    [...]

     --- PASSED --- 
    ```

    If the etcd clusters are not balanced, see [Rebalance Healthy etcd Clusters](Rebalance_Healthy_etcd_Clusters.md).

    If the etcd clusters have fewer than three pods in a 'Running' state, see [Restore an etcd Cluster from a Backup](Restore_an_etcd_Cluster_from_a_Backup.md).

1. (`ncn-mw#`) Check the health of all etcd clusters' databases.

    ```bash
    /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_database_health
    ```

    Example output:

    ```text
    **************************************************************************

    === Check the health of Etcd Cluster's database in the Services Namespace. ===
    === PASS or FAIL status returned. ===
    ### cray-bos-etcd-4jzztgq6r2 Etcd Database Check: ###
    PASS: OK foo fooCheck 1
    ### cray-bos-etcd-65g79k7lwn Etcd Database Check: ###
    PASS: OK foo fooCheck 1
    ### cray-bos-etcd-cxf2j9mc2h Etcd Database Check: ###
    PASS: OK foo fooCheck 1
    ### cray-bss-etcd-7nqbkzv8cm Etcd Database Check: ###
    PASS: OK foo fooCheck 1
    ### cray-bss-etcd-qxdjlbh2gf Etcd Database Check: ###
    PASS: OK foo fooCheck 1
    ### cray-bss-etcd-vrhlrxs2bd Etcd Database Check: ###
    PASS: OK foo fooCheck 1

    [...]

     --- PASSED --- 
    ```

    If any of the etcd cluster databases are not healthy, then refer to the following procedures:

    - [Check for and Clear etcd Cluster Alarms](Check_for_and_Clear_etcd_Cluster_Alarms.md)
    - [Clear Space in an etcd Cluster Database](Clear_Space_in_an_etcd_Cluster_Database.md)
