# Report the Endpoint Status for etcd Clusters

Report etcd cluster end point status. The report includes a cluster's endpoint, database size, and leader status.

This procedure provides the ability to view the etcd cluster endpoint status.

## Prerequisites

- This procedure requires root privileges.
- The etcd clusters are in a healthy state.

## Procedure

1. Report the endpoint status for all etcd clusters.

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh endpoint_status all_clusters
    ```

    Example output:

    ```text
    ### cray-bos-bitnami-etcd-1 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 6a95fcc74f1f8616 |   3.5.7 |   25 kB |     false |      false |         7 |        420 |                420 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ### cray-bos-bitnami-etcd-2 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 2b4984dc5c79bd55 |   3.5.7 |   25 kB |      true |      false |         7 |        424 |                424 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ### cray-bos-bitnami-etcd-0 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 75c23b83965f55de |   3.5.7 |   25 kB |     false |      false |         7 |        424 |                424 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

    [...]
    ```

2. Report the endpoint status for a singe etcd cluster.

    The following example is for the services namespace.

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh endpoint_status cray-bos
    ```

    Example output:

    ```text
    ### cray-bos-bitnami-etcd-1 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 6a95fcc74f1f8616 |   3.5.7 |   25 kB |     false |      false |         7 |        420 |                420 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ### cray-bos-bitnami-etcd-2 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 2b4984dc5c79bd55 |   3.5.7 |   25 kB |      true |      false |         7 |        424 |                424 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ### cray-bos-bitnami-etcd-0 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | 127.0.0.1:2379 | 75c23b83965f55de |   3.5.7 |   25 kB |     false |      false |         7 |        424 |                424 |        |
    +----------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```
