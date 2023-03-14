# Clear Space in an etcd Cluster Database

Use this procedure to clear the etcd cluster `NOSPACE` alarm. Once it is set it will remain set. If needed, defrag the database cluster before clearing the `NOSPACE` alarm.

Defragging the database cluster and clearing the etcd cluster `NOSPACE` alarm will free up database space.

## Prerequisites

- This procedure requires root privileges
- The etcd clusters are in a healthy state

## Procedure

1. (`ncn-mw#`) Clear up space when the etcd database space has exceeded and has been defragged, but the `NOSPACE` alarm remains set.

    1. Determine if any clusters are failing to store a new key-value.

        ```bash
        /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_database_health
        ```

        Example output:

        ```text
        **************************************************************************

        === Check the health of Etcd Cluster's database in the Services Namespace. ===
        === PASS or FAIL status returned. ===
        ### cray-bos-bitnami-etcd-0 Etcd Database Check: ###
        FAILED DATABASE CHECK - EXPECTED: OK foo fooCheck 1
        {"level":"warn","ts":"2020-10-23T23:56:48.408Z","caller":"clientv3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"endpoint://client-208534eb-2ab4-4c58-8853-58bff088c394/127.0.0.1:2379","attempt":0,"error":"rpc error: code = ResourceExhausted desc = etcdserver: mvcc: database space exceeded"}
        Error: etcdserver: mvcc: database space exceeded
        ### cray-bos-bitnami-etcd-1 Etcd Database Check: ###
        PASS: OK foo fooCheck 1
        ### cray-bos-bitnami-etcd-2 Etcd Database Check: ###
        PASS: OK foo fooCheck 1
         --- PASSED ---
        ```

    1. Check to see if the default 3G disk usage space \(unless defined differently in the Helm chart\) is currently exceeded. `all_clusters` can be substituted with a cluster name (`cray-bss`) for an individual cluster

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh pvc_usage all_clusters
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd14   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-1 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd11   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-2 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd10   7.8G   123M   7.7G   2%   /bitnami/etcd
        ```

    1. Clear the `NOSPACE` alarm. The example below will clear alarms for all clusters. `all_clusters` can be substituted with a cluster name (`cray-bss`) for an individual cluster:

       ```bash
       /opt/cray/platform-utils/etcd/etcd-util.sh clear_alarms all_clusters
       ```

       Example output:

       ```text
       ### cray-bos-bitnami-etcd-0 Disarmed Alarms: ###
       memberID:6004340417806974740 alarm:NOSPACE
       memberID:10618826089438871005 alarm:NOSPACE
       memberID:6927946043724325475 alarm:NOSPACE
       ### cray-bos-bitnami-etcd-1 Disarmed Alarms: ###
       ### cray-bos-bitnami-etcd-2 Disarmed Alarms: ###
       ```

    1. Verify that a new key-value can now be successfully stored.

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
         --- PASSED ---
        ```

1. (`ncn-mw#`) Clear the `NOSPACE` alarm. If the database needs to be defragged, then the alarm will be reset.

    1. Check to see if the default 3G disk usage space \(unless defined differently in the Helm chart\) is currently exceeded. `all_clusters` can be substituted with a cluster name (`cray-bss`) for an individual cluster

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh pvc_usage all_clusters
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd14   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-1 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd11   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-2 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd10   7.8G   123M   7.7G   2%   /bitnami/etcd
        ```

    1. Resolve the space issue by either increasing the frequency of how often the `etcd-defrag` cron job is run, or by triggering it manually.

        Select one of the following options:

        - Increase the frequency of the `kube-etcd-defrag` from every 24 hours to 12 hours.

            ```bash
            kubectl edit -n services cronjob.batch/kube-etcd-defrag
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

            [...]
            ```

        - Trigger the job manually.

            ```bash
            kubectl -n services create job --from=cronjob/kube-etcd-defrag kube-etcd-defrag
            ```

    1. Check the log messages after the defrag job is triggered

        ```bash
        kubectl logs -n services $(kubectl get po -n services -l 'service.istio.io/canonical-name=kube-etcd-defrag' --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
        ```

        Example output:

        ```text
        Running etcd defrag for: all
        Skip defrag for: cray-hbtd-etcd
        Skipping defrag for: cray-hbtd-etcd
        Defragging cray-bos-bitnami-etcd-0
        Defragging cray-bos-bitnami-etcd-1
        Defragging cray-bos-bitnami-etcd-2

        [...]
        ```

    1. Verify that the disk space is less than the size limit.

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh pvc_usage all_clusters
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd14   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-1 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd11   7.8G   123M   7.7G   2%   /bitnami/etcd

        ### cray-bos-bitnami-etcd-2 PVC Usage: ###
        Filesystem   Size   Used   Avail   Use%   Mounted   on
        /dev/rbd10   7.8G   123M   7.7G   2%   /bitnami/etcd
        ```

    1. Turn off the `NOSPACE` alarm. The example below will clear alarms for all clusters. `all_clusters` can be substituted with a cluster name (`cray-bss`) for an individual cluster:

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh clear_alarms all_clusters
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 Disarmed Alarms: ###
        memberID:6004340417806974740 alarm:NOSPACE
        memberID:10618826089438871005 alarm:NOSPACE
        memberID:6927946043724325475 alarm:NOSPACE
        ### cray-bos-bitnami-etcd-1 Disarmed Alarms: ###
        ### cray-bos-bitnami-etcd-2 Disarmed Alarms: ###
        ```
