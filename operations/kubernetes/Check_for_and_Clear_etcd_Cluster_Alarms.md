# Check for and Clear etcd Cluster Alarms

Check for any etcd cluster alarms and clear them as needed. An etcd cluster alarm must be manually cleared.

For example, a cluster's database `NOSPACE` alarm is set when database storage space is no longer available. A subsequent defrag may free up database storage space, but writes to the database will continue to fail while the `NOSPACE` alarm is set.

## Prerequisites

- This procedure requires root privileges.
- The etcd clusters are in a healthy state.

## Procedure

1. (`ncn-mw#`) Check for etcd cluster alarms.

    An empty list will be returned if no alarms are set.

    Check if any etcd alarms are set for any etcd clusters.

    ```bash
    /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_alarm_check

    ```

    Example output:

    ```text
    **************************************************************************

    === Check if any "alarms" are set for any of the Etcd Clusters in the Services Namespace. ===
    === An empty list is returned if no alarms are set ===
    ### cray-bos-etcd-4jzztgq6r2 Alarms Set: ###
    ### cray-bos-etcd-65g79k7lwn Alarms Set: ###
    ### cray-bos-etcd-cxf2j9mc2h Alarms Set: ###
    ### cray-bss-etcd-7nqbkzv8cm Alarms Set: ###
    ### cray-bss-etcd-qxdjlbh2gf Alarms Set: ###
    ### cray-bss-etcd-vrhlrxs2bd Alarms Set: ###
    ### cray-cps-etcd-fqmgpbfddn Alarms Set: ###
    ### cray-cps-etcd-fs9tkqsd8q Alarms Set: ###
    ### cray-cps-etcd-qs9zps8p4d Alarms Set: ###

    [...]

     --- PASSED --- 
    ```

1. (`ncn-mw#`) Clear any etcd cluster alarms.

    A list of disarmed alarms will be returned. An empty list is returned if no alarms were set.

    - Clear all etcd alarms set in etcd clusters.

        ```bash
        for pod in $(kubectl get pods -l app=etcd -n services \
                             -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Disarmed Alarms: ###"
            kubectl -n services exec ${pod} -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl alarm disarm"
        done
        ```

        Example output:

        ```text
        ### cray-bos-etcd-7cxq6qrhz5 Disarmed Alarms: ###
        ### cray-bos-etcd-b9m4k5qfrd Disarmed Alarms: ###
        ### cray-bos-etcd-tnpv8x6cxv Disarmed Alarms: ###
        ### cray-bss-etcd-q4k54rbbfj Disarmed Alarms: ###
        ### cray-bss-etcd-r75mlv6ffd Disarmed Alarms: ###
        ### cray-bss-etcd-xprv5ht5d4 Disarmed Alarms: ###
        ### cray-cps-etcd-8hpztfkjdp Disarmed Alarms: ###
        ### cray-cps-etcd-fp4kfsf799 Disarmed Alarms: ###

        [...]
        ```

    - Clear all alarms in one particular etcd cluster.

        ```bash
        for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
                             -n services -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Disarmed Alarms:  ###"
            kubectl -n services exec ${pod} -c etcd -- /bin/sh -c "ETCDCTL_API=3 etcdctl alarm disarm"
        done
        ```

        Example output:

        ```text
        ### cray-bos-etcd-7cxq6qrhz5 Disarmed Alarms:  ###
        memberID:14039380531903955557 alarm:NOSPACE
        memberID:10060051157615504224 alarm:NOSPACE
        memberID:9418794810465807950 alarm:NOSPACE
        ### cray-bos-etcd-b9m4k5qfrd Disarmed Alarms:  ###
        ### cray-bos-etcd-tnpv8x6cxv Disarmed Alarms:  ###
        ```
