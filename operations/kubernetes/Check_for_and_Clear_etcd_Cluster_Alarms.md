# Check for and Clear etcd Cluster Alarms

Check for any etcd cluster alarms and clear them as needed. An etcd cluster alarm must be manually cleared.

For example, a cluster's database `NOSPACE` alarm is set when database storage space is no longer available. A subsequent defrag may free up database storage space, but writes to the database will continue to fail while the `NOSPACE` alarm is set.

## Prerequisites

- This procedure requires root privileges.
- The etcd clusters are in a healthy state.

## Procedure

1. (`ncn-mw#`) Check for etcd cluster alarms.

    An empty list will be returned if no alarms are set.

    - Check if any etcd alarms are set for any etcd clusters.

        ```bash
        /opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_alarm_check
        ```

        Example output:

        ```text
        **************************************************************************

        === Check if any "alarms" are set for any of the Etcd Clusters in all Namespaces. ===
        === An empty list is returned if no alarms are set ===
        ### cray-bos-bitnami-etcd-0 Alarms Set: ###
        ### cray-bos-bitnami-etcd-1 Alarms Set: ###
        ### cray-bos-bitnami-etcd-2 Alarms Set: ###
         --- PASSED ---
        ```

1. (`ncn-mw#`) Clear any etcd cluster alarms.

    A list of disarmed alarms will be returned. An empty list is returned if no alarms were set.

    - Clear all etcd alarms set in etcd clusters.

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh clear_alarms all_clusters
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 Disarmed Alarms: ###
        ### cray-bos-bitnami-etcd-1 Disarmed Alarms: ###
        ### cray-bos-bitnami-etcd-2 Disarmed Alarms: ###
        ### cray-bss-bitnami-etcd-0 Disarmed Alarms: ###
        ### cray-bss-bitnami-etcd-1 Disarmed Alarms: ###
        ### cray-bss-bitnami-etcd-2 Disarmed Alarms: ###

        [...]
        ```

    - Clear all alarms in one particular etcd cluster.

        ```bash
        /opt/cray/platform-utils/etcd/etcd-util.sh clear_alarms cray-bos
        ```

        Example output:

        ```text
        ### cray-bos-bitnami-etcd-0 Disarmed Alarms: ###
        memberID:14039380531903955557 alarm:NOSPACE
        memberID:10060051157615504224 alarm:NOSPACE
        memberID:9418794810465807950 alarm:NOSPACE
        ### cray-bos-bitnami-etcd-1 Disarmed Alarms: ###
        ### cray-bos-bitnami-etcd-2 Disarmed Alarms: ###
        ```
