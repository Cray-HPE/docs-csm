# Clear Space in an etcd Cluster Database

Use this procedure to clear the etcd cluster `NOSPACE` alarm. Once it is set it will remain set. If needed, defrag the database cluster before clearing the `NOSPACE` alarm.

Defragging the database cluster and clearing the etcd cluster `NOSPACE` alarm will free up database space.

## Prerequisites

- This procedure requires root privileges.
- The etcd clusters are in a healthy state.

## Procedure

1. Clear up space when the etcd database space has exceeded and has been defragged, but the `NOSPACE` alarm remains set.

    1. Verify that the attempt to store a new key-value fails.

        Replace `hbtd-ETCD_CLUSTER` before running the following command.
        `hbtd-etcd-h59j42knjv` is an example replacement value.

        ```bash
        ncn-mw# kubectl -n services exec -it hbtd-ETCD_CLUSTER -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl put foo bar"
        ```

        Example output:

        ```text
        {"level":"warn","ts":"2020-10-23T23:56:48.408Z","caller":"clientv3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"endpoint://client-208534eb-2ab4-4c58-8853-58bff088c394/127.0.0.1:2379","attempt":0,"error":"rpc error: code = ResourceExhausted desc = etcdserver: mvcc: database space exceeded"}
        Error: etcdserver: mvcc: database space exceeded
        ```

    1. Check to see if the default 2G disk usage space \(unless defined differently in the Helm chart\) is currently exceeded.

        In the following example, the disk usage is 375.5 M, which means the disk space has not been exceeded.

        Replace `hbtd-ETCD_CLUSTER` before running the following command.
        `hbtd-etcd-h59j42knjv` is an example replacement value.

        ```bash
        ncn-mw# kubectl -n services exec -it hbtd-ETCD_CLUSTER -c etcd -- df -h
        ```

        Example output:

        ```text
        Filesystem                Size      Used Available Use% Mounted on
        overlay                 396.3G     59.6G    316.5G  16% /
        tmpfs                    64.0M         0     64.0M   0% /dev
        tmpfs                   125.7G         0    125.7G   0% /sys/fs/cgroup
        /dev/rbd21                2.9G    375.5M      2.5G  13% /var/etcd.  <------/dev/sdc4               396.3G     22.0G    354.1G   6% /etc/hosts
        /dev/sdc4               396.3G     22.0G    354.1G   6% /dev/termination-log
        /dev/sdc5               396.3G     59.6G    316.5G  16% /etc/hostname
        /dev/sdc5               396.3G     59.6G    316.5G  16% /etc/resolv.conf
        ```

    1. Clear the `NOSPACE` alarm.

        ```bash
        ncn-mw# for pod in $(kubectl get pods -l etcd_cluster=hbtd-etcd \
                             -n services -o jsonpath='{.items[*].metadata.name}')
                do
                    echo "### ${pod} ###"
                    kubectl -n services exec ${pod} -- /bin/sh \
                        -c "ETCDCTL_API=3 etcdctl alarm disarm"
                done
        ```

        Example output:

        ```text
        ### hbtd-etcd-h59j42knjv ###
        memberID:6004340417806974740 alarm:NOSPACE
        memberID:10618826089438871005 alarm:NOSPACE
        memberID:6927946043724325475 alarm:NOSPACE
        ### hbtd-etcd-jfwh9l49lm ###
        ### hbtd-etcd-mhklm4n5qd ###
        ```

    1. Verify that a new key-value can now be successfully stored.

        Replace `hbtd-ETCD_CLUSTER` before running the following command.
        `hbtd-etcd-h59j42knjv` is an example replacement value.

        ```bash
        ncn-mw# kubectl -n services exec -it hbtd-ETCD_CLUSTER -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl put foo bar"
        ```

        Example output:

        ```text
        OK
        ```

1. Clear the `NOSPACE` alarm. If the database needs to be defragged, then the alarm will be reset.

    1. Confirm that the "database space exceeded" message is present.

        ```bash
        ncn-mw# kubectl logs -n services --tail=-1 --prefix=true -l "app.kubernetes.io/name=cray-hbtd" -c cray-hbtd | grep "x3005c0s19b1n0"
        ```

        Example output:

        ```text
        [pod/cray-hbtd-56bc4f6fdb-92bqx/cray-hbtd] 2020/09/15 20:00:44 INTERNAL ERROR storing key  {"Component":"x3005c0s19b1n0","Last_hb_rcv_time":"5f611d6c","Last_hb_timestamp":"2020-09-15T15:00:44.878876-06:00","Last_hb_status":"OK","Had_warning":""} :  etcdserver: mvcc: database space exceeded
        [pod/cray-hbtd-56bc4f6fdb-92bqx/cray-hbtd] 2020/09/15 20:00:47 INTERNAL ERROR storing key  {"Component":"x3005c0s19b1n0","Last_hb_rcv_time":"5f611d6f","Last_hb_timestamp":"2020-09-15T15:00:47.893757-06:00","Last_hb_status":"OK","Had_warning":""} :  etcdserver: mvcc: database space exceeded
        [pod/cray-hbtd-56bc4f6fdb-92bqx/cray-hbtd] 2020/09/15 20:00:53 INTERNAL ERROR storing key  {"Component":"x3005c0s19b1n0","Last_hb_rcv_time":"5f611d75","Last_hb_timestamp":"2020-09-15T15:00:53.926195-06:00","Last_hb_status":"OK","Had_warning":""} :  etcdserver: mvcc: database space exceeded
        [pod/cray-hbtd-56bc4f6fdb-92bqx/cray-hbtd] 2020/09/15 20:01:02 INTERNAL ERROR storing key  {"Component":"x3005c0s19b1n0","Last_hb_rcv_time":"5f611d7e","Last_hb_timestamp":"2020-09-15T15:01:02.970168-06:00","Last_hb_status":"OK","Had_warning":""} :  etcdserver: mvcc: database space exceeded
        [pod/cray-hbtd-56bc4f6fdb-92bqx/cray-hbtd] 2020/09/15 20:01:05 INTERNAL ERROR storing key  {"Component":"x3005c0s19b1n0","Last_hb_rcv_time":"5f611d81","Last_hb_timestamp":"2020-09-15T15:01:05.983828-06:00","Last_hb_status":"OK","Had_warning":""} :  etcdserver: mvcc: database space exceeded
        ```

    1. Check if the default 2G \(unless defined differently in the Helm chart\) disk usage has been exceeded.

        Replace `ETCD_CLUSTER_NAME` before running the following command.
        For example, `cray-hbtd-etcd-6p4tc4jdgm` could be used.

        ```bash
        ncn-mw# kubectl exec -it -n services ETCD_CLUSTER_NAME -c etcd -- df -h
        ```

        Example output:

        ```text
        Filesystem                Size      Used Available Use% Mounted on
        overlay                 439.1G     15.2G    401.5G   4% /
        tmpfs                    64.0M         0     64.0M   0% /dev
        tmpfs                   125.7G         0    125.7G   0% /sys/fs/cgroup
        /dev/rbd3                 7.8G      2.4G      5.4G  31% /var/etcd
        ```

    1. Resolve the space issue by either increasing the frequency of how often the `etcd-defrag` cron job is run, or by triggering it manually.

        Select one of the following options:

        - Increase the frequency of the `kube-etcd-defrag` from every 24 hours to 12 hours.

            ```bash
            ncn-mw# kubectl edit -n operators cronjob.batch/kube-etcd-defrag
            ```

            Example output:

            ```text
            [...]

                          name: etcd-defrag
                        name: etcd-defrag
              schedule: 0 */12 * * *
              successfulJobsHistoryLimit: 1
              suspend: false
            status:
            ...
            ...
            ```

        - Trigger the job manually.

            ```bash
            ncn-mw# kubectl -n operators create job --from=cronjob/kube-etcd-defrag kube-etcd-defrag
            ```

    1. Check the log messages after the defrag job is triggered.

        ```bash
        ncn-mw# kubectl logs -f -n operators pod/kube-etcd-defrag-1600171200-fxpn7
        ```

        Example output:

        ```text
        Defragging cray-bos-etcd-j7czpr9pbr
        Defragging cray-bos-etcd-k4qtjtgqjb
        Defragging cray-bos-etcd-wcm8cs7dvc
        Defragging cray-bss-etcd-2h6k4l4j2g
        Defragging cray-bss-etcd-5dqwvrdtnf
        Defragging cray-bss-etcd-zlwmzkcjhz
        Defragging cray-cps-etcd-6cqw8sw5k6
        Defragging cray-cps-etcd-psjm9lpw66
        Defragging cray-cps-etcd-rp6fp94ccv
        Defragging cray-crus-etcd-228mdpm2h6
        Defragging cray-crus-etcd-hldtxr6f9s
        Defragging cray-crus-etcd-sfsckpv4vw
        Defragging cray-externaldns-etcd-6l772b2cdv
        Defragging cray-externaldns-etcd-khbgl45pf7
        Defragging cray-externaldns-etcd-qphz6lmhns
        Defragging cray-fas-etcd-7ktd4h47jv
        Defragging cray-fas-etcd-b27mknzs2q
        Defragging cray-fas-etcd-vccgfhcnnt
        Defragging cray-hbtd-etcd-6p4tc4jdgm
        Defragging cray-hbtd-etcd-j4xs7zj6v5
        Defragging cray-hbtd-etcd-pb9tnrj6bw
        Defragging cray-hmnfd-etcd-558sqc22lw
        Defragging cray-hmnfd-etcd-prt7k224br
        Defragging cray-hmnfd-etcd-rf2x7sth84
        Defragging cray-reds-etcd-h94pq6w7cv
        Defragging cray-reds-etcd-hgxdbgc65j
        Defragging cray-reds-etcd-qxfh756zhm
        Defragging cray-uas-mgr-etcd-5548zzfw8w
        Defragging cray-uas-mgr-etcd-ngbm48qz2g
        Defragging cray-uas-mgr-etcd-qnrlg6r4n6
        ```

    1. Verify that the disk space is less than the size limit.

        Replace `ETCD_CLUSTER_NAME` before running the following command.
        For example, `cray-hbtd-etcd-6p4tc4jdgm` could be used.

        ```bash
        ncn-mw# kubectl exec -it -n services ETCD_CLUSTER_NAME -c etcd -- df -h
        ```

        Example output:

        ```text
        Filesystem                Size      Used Available Use% Mounted on
        overlay                 439.1G     15.2G    401.5G   4% /
        tmpfs                    64.0M         0     64.0M   0% /dev
        tmpfs                   125.7G         0    125.7G   0% /sys/fs/cgroup
        /dev/rbd3                 7.8G    403.0M      7.4G   5% /var/etcd.
        ```

    1. Turn off the `NOSPACE` alarm.

        Replace `ETCD_CLUSTER_NAME` before running the following command.
        For example, `cray-hbtd-etcd-6p4tc4jdgm` could be used.

        ```bash
        ncn-mw# kubectl exec -it -n services ETCD_CLUSTER_NAME -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl alarm disarm"
        ```

        Example output:

        ```text
        memberID:14039380531903955557 alarm:NOSPACE
        memberID:10060051157615504224 alarm:NOSPACE
        memberID:9418794810465807950 alarm:NOSPACE
        ```
