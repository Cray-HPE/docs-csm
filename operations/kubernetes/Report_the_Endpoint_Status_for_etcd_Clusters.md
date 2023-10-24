# Report the Endpoint Status for etcd Clusters

Report etcd cluster end point status. The report includes a cluster's endpoint, database size, and leader status.

This procedure provides the ability to view the etcd cluster endpoint status.

## Prerequisites

- This procedure requires root privileges.
- The etcd clusters are in a healthy state.

## Procedure

1. Report the endpoint status for all etcd clusters in a namespace.

    The following example is for the services namespace.

    ```bash
    ncn-mw# for pod in $(kubectl get pods -l app=etcd -n services -o jsonpath='{.items[*].metadata.name}'); do
                echo "### ${pod} Endpoint Status: ###"
                kubectl -n services exec ${pod} -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl endpoint status -w table"
            done
    ```

    Example output:

    ```text
    ### cray-bos-etcd-7cxq6qrhz5 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | e57d42e2a85763bb |  3.3.22 |  139 kB |      true |        26 |      78360 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bos-etcd-b9m4k5qfrd Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | 355baed6cb6e3022 |  3.3.22 |  139 kB |     false |        26 |      78360 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bos-etcd-tnpv8x6cxv Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | 78949579ff08b422 |  3.3.22 |  139 kB |     false |        26 |      78360 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bss-etcd-q4k54rbbfj Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | cbeb570f568c6ca6 |  3.3.22 |   70 kB |      true |        29 |      41321 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bss-etcd-r75mlv6ffd Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | 7343edb17d8e6fd4 |  3.3.22 |   70 kB |     false |        29 |      41321 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bss-etcd-xprv5ht5d4 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | d7404ad66483bd37 |  3.3.22 |   70 kB |     false |        29 |      41321 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ...
    ```

1. Report the endpoint status for a singe etcd cluster in a namespace.

    The following example is for the `services` namespace.

    ```bash
    ncn-mw# for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd -n services -o jsonpath='{.items[*].metadata.name}'); do
                echo "### ${pod} Endpoint Status: ###"
                kubectl -n services exec ${pod} -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl endpoint status -w table"
            done
    ```

    Example output:

    ```text
    ### cray-bos-etcd-7cxq6qrhz5 Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | e57d42e2a85763bb |  3.3.22 |  139 kB |      true |        26 |      78333 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bos-etcd-b9m4k5qfrd Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | 355baed6cb6e3022 |  3.3.22 |  139 kB |     false |        26 |      78333 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ### cray-bos-etcd-tnpv8x6cxv Endpoint Status: ###
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    |    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    | 127.0.0.1:2379 | 78949579ff08b422 |  3.3.22 |  139 kB |     false |        26 |      78333 |
    +----------------+------------------+---------+---------+-----------+-----------+------------+
    ```
