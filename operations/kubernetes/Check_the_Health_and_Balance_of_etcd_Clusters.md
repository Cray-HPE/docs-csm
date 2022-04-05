# Check the Health and Balance of etcd Clusters

Check to see if all of the etcd clusters have healthy pods, are balanced, and have a healthy cluster database. There needs to be the same number of pods running on each worker node for the etcd clusters to be balanced. If the number of pods is not the same for each worker node, the cluster is not balanced.

Any clusters that do not have healthy pods will need to be rebuilt. Kubernetes cluster data will not be stored as efficiently when etcd clusters are not balanced.


### Prerequisites

This procedure requires root privileges.


### Procedure

1.  Check the health of the clusters.

    To check the health of the etcd clusters in the services namespace without TLS authentication:

    ```bash
    ncn-w001# for pod in $(kubectl get pods -l app=etcd -n services \
    -o jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} ###"; \
    kubectl -n services exec ${pod} -- /bin/sh -c "ETCDCTL_API=3 etcdctl endpoint health"; done
    ```

    Example output:

    ```
    ### cray-bos-etcd-6nkn6dzhv7 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.670457ms
    ### cray-bos-etcd-6xtp2gqs64 ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 954.462µs
    ### cray-bos-etcd-gnt9rxcbvl ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.313505ms
    ### cray-bss-etcd-4jsn7p49rj ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.054509ms
    ### cray-bss-etcd-9q6xf5wl5q ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.174929ms
    ### cray-bss-etcd-ncwkjmlq8b ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.632738ms
    ### cray-cps-etcd-8ml5whzhjh ###
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.792795ms

    [...]
    ```

    If any of the etcd clusters are not healthy, refer to [Rebuild Unhealthy etcd Clusters](Rebuild_Unhealthy_etcd_Clusters.md).

2.  Check the number of pods in each cluster and verify they are balanced.

    Each cluster should contain at least three pods, but may contain more. Ensure that no two pods in a given cluster exist on the same worker node.

    ```bash
    ncn-w001# kubectl get pod -n services -o wide | head -n 1; for cluster in \
    $(kubectl get etcdclusters.etcd.database.coreos.com -n services | grep -v NAME | \
    awk '{print $1}'); do kubectl get pod -n services -o wide | grep $cluster; echo ""; done
    ```

    Example output:

    ```
    NAME                                    READY   STATUS    RESTARTS AGE   IP            NODE       NOMINATED NODE  READINESS GATE
    cray-bos-etcd-7gl9dccmrq                1/1     Running   0        8d    10.40.0.88    ncn-w003   <none>          <none>
    cray-bos-etcd-g65fjhhlbg                1/1     Running   0        8d    10.42.0.36    ncn-w002   <none>          <none>
    cray-bos-etcd-lbsppj5kt7                1/1     Running   0        20h   10.47.0.98    ncn-w001   <none>          <none>

    cray-bss-etcd-dbhxvz824w                1/1     Running   0        8d    10.42.0.45    ncn-w002   <none>          <none>
    cray-bss-etcd-hzpbrcn2pb                1/1     Running   0        20h   10.47.0.99    ncn-w001   <none>          <none>
    cray-bss-etcd-kpc64v64wd                1/1     Running   0        8d    10.40.0.43    ncn-w003   <none>          <none>

    cray-cps-etcd-8ndvn4dlx4                1/1     Running   0        20h   10.47.0.100   ncn-w001   <none>          <none>
    cray-cps-etcd-gvlql48gwk                1/1     Running   0        8d    10.40.0.89    ncn-w003   <none>          <none>
    cray-cps-etcd-wsvhmp4f7p                1/1     Running   0        8d    10.42.0.64    ncn-w002   <none>          <none>

    cray-crus-etcd-2wvb2bpczb               1/1     Running   0        20h   10.47.0.117   ncn-w001   <none>          <none>
    cray-crus-etcd-fhbcvknghh               1/1     Running   0        8d    10.42.0.34    ncn-w002   <none>          <none>
    cray-crus-etcd-nrxqzftrzr               1/1     Running   0        8d    10.40.0.45    ncn-w003   <none>          <none>

    cray-externaldns-etcd-7skqmr825d        1/1     Running   0        20h   10.47.0.119   ncn-w001   <none>          <none>
    cray-externaldns-etcd-gm2s7nkjgl        1/1     Running   0        8d    10.42.0.13    ncn-w002   <none>          <none>
    cray-externaldns-etcd-ttnchdrwjl        1/1     Running   0        8d    10.40.0.22    ncn-w003   <none>          <none>

    cray-fas-etcd-29qcrd8qdt                1/1     Running   0        20h   10.47.0.102   ncn-w001   <none>          <none>
    cray-fas-etcd-987c87m4mv                1/1     Running   0        8d    10.40.0.66    ncn-w003   <none>          <none>
    cray-fas-etcd-9fxbzkzrsv                1/1     Running   0        8d    10.42.0.43    ncn-w002   <none>          <none>

    cray-hbtd-etcd-2sf24nw5zs               1/1     Running   0        8d    10.40.0.78    ncn-w003   <none>          <none>
    cray-hbtd-etcd-5r6mgvjct8               1/1     Running   0        20h   10.47.0.105   ncn-w001   <none>          <none>
    cray-hbtd-etcd-t78x5wqkjt               1/1     Running   0        8d    10.42.0.51    ncn-w002   <none>          <none>

    cray-hmnfd-etcd-99j5zt5ln6              1/1     Running   0        8d    10.40.0.74    ncn-w003   <none>          <none>
    cray-hmnfd-etcd-h9gnvvs7rs              1/1     Running   0        8d    10.42.0.39    ncn-w002   <none>          <none>
    cray-hmnfd-etcd-lj72f8xjkv              1/1     Running   0        20h   10.47.0.103   ncn-w001   <none>          <none>

    cray-reds-etcd-97wr66d4pj               1/1     Running   0        20h   10.47.0.129   ncn-w001   <none>          <none>
    cray-reds-etcd-kmggscpzrf               1/1     Running   0        8d    10.40.0.64    ncn-w003   <none>          <none>
    cray-reds-etcd-zcwrhm884l               1/1     Running   0        8d    10.42.0.53    ncn-w002   <none>          <none>

    cray-uas-mgr-etcd-7gmh92t2hx            1/1     Running   0        20h   10.47.0.94    ncn-w001   <none>          <none>
    cray-uas-mgr-etcd-7m4qmtgp6t            1/1     Running   0        8d    10.42.0.67    ncn-w002   <none>          <none>
    cray-uas-mgr-etcd-pldlkpr48w            1/1     Running   0        8d    10.40.0.94    ncn-w003   <none>          <none>
    ```

    If the etcd clusters are not balanced, see [Rebalance Healthy etcd Clusters](Rebalance_Healthy_etcd_Clusters.md).

3.  Check the health of an etcd cluster database.

    -   To check the health of an etcd cluster's database in the services namespace:

        ```bash
        for pod in $(kubectl get pods -l app=etcd -n services \
                             -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Etcd Database Check: ###"
            dbc=$(kubectl -n services exec ${pod} -- /bin/sh \
                          -c "ETCDCTL_API=3 etcdctl put foo fooCheck && \
                          ETCDCTL_API=3 etcdctl get foo && \
                          ETCDCTL_API=3 etcdctl del foo && \
                          ETCDCTL_API=3 etcdctl get foo" 2>&1)
            echo $dbc | awk '{ if ( $1=="OK" && $2=="foo" && \
                               $3=="fooCheck" && $4=="1" && $5=="" ) print \
            "PASS:  " PRINT $0;
            else \
            print "FAILED DATABASE CHECK - EXPECTED: OK foo fooCheck 1 \
            GOT: " PRINT $0 }'
        done
        ```

        Example of command being entered:

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l app=etcd -n services -o \
        jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} \
        Etcd Database Check: ###"; dbc=$(kubectl -n services exec ${pod} \
        -- /bin/sh -c "ETCDCTL_API=3 etcdctl put foo fooCheck && ETCDCTL_API=3 \
        etcdctl get foo && ETCDCTL_API=3 etcdctl del foo && ETCDCTL_API=3 \
        etcdctl get foo" 2>&1); echo $dbc | awk '{ if ( $1=="OK" && \
        $2=="foo" && $3=="fooCheck" && $4=="1" && $5=="" ) print "PASS:  \
        " PRINT $0; else print "FAILED DATABASE CHECK - \
        EXPECTED: OK foo fooCheck 1   GOT: " PRINT $0 \}'; done
        ```

        Example output:

        ```
        ### cray-bos-etcd-7cxq6qrhz5 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bos-etcd-b9m4k5qfrd Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bos-etcd-tnpv8x6cxv Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bss-etcd-q4k54rbbfj Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bss-etcd-r75mlv6ffd Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bss-etcd-xprv5ht5d4 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-cps-etcd-8hpztfkjdp Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-cps-etcd-fp4kfsf799 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-cps-etcd-g6gz9vmmdn Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-crus-etcd-6z9zskl6cr Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-crus-etcd-krp255f97q Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-crus-etcd-tpclqfln67 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-externaldns-etcd-2vnb5t4657 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1

        [...]
        ```

    -   To check one cluster:

        ```bash
        for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd -n services \
                             -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Etcd Database Check: ###"
            dbc=$(kubectl -n services exec ${pod} -- /bin/sh \
                          -c "ETCDCTL_API=3 etcdctl put foo fooCheck && \
                          ETCDCTL_API=3 etcdctl get foo && \
                          ETCDCTL_API=3 etcdctl del foo && \
                          ETCDCTL_API=3 etcdctl get foo" 2>&1)
            echo $dbc | awk '{ if ( $1=="OK" && $2=="foo" && \
                               $3=="fooCheck" && $4=="1" && $5=="" ) print \
            "PASS:  " PRINT $0;
            else \
            print "FAILED DATABASE CHECK - EXPECTED: OK foo fooCheck 1 \
            GOT: " PRINT $0 }'
        done
        ```

        Example of command being entered:

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
        -n services -o jsonpath='{.items[*].metadata.name}'); do echo \
        "### ${pod} Etcd Database Check: ###";  dbc=$(kubectl -n \
        services exec ${pod} -- /bin/sh -c "ETCDCTL_API=3 etcdctl \
        put foo fooCheck && ETCDCTL_API=3 etcdctl get foo && \
        ETCDCTL_API=3 etcdctl del foo && ETCDCTL_API=3 etcdctl get \
        foo" 2>&1); echo $dbc | awk '{ if ( $1=="OK" && $2=="foo" && \
        $3=="fooCheck" && $4=="1" && $5=="" ) print "PASS:  " PRINT $0; \
        else print "FAILED DATABASE CHECK - EXPECTED: \
        OK foo fooCheck 1   GOT: " PRINT $0 }'; done
        ```

        Example output:

        ```
        ### cray-bos-etcd-7cxq6qrhz5 Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bos-etcd-b9m4k5qfrd Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ### cray-bos-etcd-tnpv8x6cxv Etcd Database Check: ###
        PASS:  OK foo fooCheck 1
        ```

    If any of the etcd cluster databases are not healthy, refer to the following procedures:

    - Refer to [Check for and Clear etcd Cluster Alarms](Check_for_and_Clear_etcd_Cluster_Alarms.md)
    - Refer to [Clear Space in an etcd Cluster Database](Clear_Space_in_an_etcd_Cluster_Database.md)

