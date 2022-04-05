# Check for and Clear etcd Cluster Alarms

Check for any etcd cluster alarms and clear them as needed. An etcd cluster alarm must be manually cleared.

For example, a cluster's database "NOSPACE" alarm is set when database storage space is no longer available. A subsequent defrag may free up database storage space, but writes to the database will continue to fail while the "NOSPACE" alarm is set.


### Prerequisites

-   This procedure requires root privileges.
-   The etcd clusters are in a healthy state.


### Procedure

1.  Check for etcd cluster alarms.

    An empty list will be returned if no alarms are set.

    -   Check if any etcd alarms are set for etcd clusters in the services namespace.

        ```bash
        for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
                             -n services -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Alarms Set: ###"
            kubectl -n services exec ${pod} -- /bin/sh \
                    -c "ETCDCTL_API=3 etcdctl alarm list"
        done
        ```

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l app=etcd -n services \
        -o jsonpath='{.items[*].metadata.name}'); \
        do echo "### ${pod} Alarms Set: ###"; kubectl -n services exec ${pod} -- /bin/sh -c \
        "ETCDCTL_API=3 etcdctl alarm list"; done
        ```

        Example output:

        ```
        ### cray-bos-etcd-7cxq6qrhz5 Alarms Set: ###
        ### cray-bos-etcd-b9m4k5qfrd Alarms Set: ###
        ### cray-bos-etcd-tnpv8x6cxv Alarms Set: ###
        ### cray-bss-etcd-q4k54rbbfj Alarms Set: ###
        ### cray-bss-etcd-r75mlv6ffd Alarms Set: ###
        ### cray-bss-etcd-xprv5ht5d4 Alarms Set: ###
        ### cray-cps-etcd-8hpztfkjdp Alarms Set: ###
        ### cray-cps-etcd-fp4kfsf799 Alarms Set: ###
        ### cray-cps-etcd-g6gz9vmmdn Alarms Set: ###
        ### cray-crus-etcd-6z9zskl6cr Alarms Set: ###
        ### cray-crus-etcd-krp255f97q Alarms Set: ###
        ### cray-crus-etcd-tpclqfln67 Alarms Set: ###
        ### cray-externaldns-etcd-2vnb5t4657 Alarms Set: ###
        ### cray-externaldns-etcd-sc4b88ptg2 Alarms Set: ###

        [...]
        ```

    -   Check if any etcd alarms are set for a particular etcd cluster in the services namespace.

        ```bash
        for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
                             -n services -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Alarms Set: ###"
            kubectl -n services exec ${pod} -- /bin/sh \
                    -c "ETCDCTL_API=3 etcdctl alarm list"
        done
        ```

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
        -n services -o jsonpath='{.items[*].metadata.name}'); do echo "### \
        ${pod} Alarms Set: ###"; kubectl -n services exec ${pod} -- /bin/sh -c \
        "ETCDCTL_API=3 etcdctl alarm list"; done
        ```

        Example output:

        ```
        ### cray-bos-etcd-7cxq6qrhz5 Alarms Set: ###
        ### cray-bos-etcd-b9m4k5qfrd Alarms Set: ###
        ### cray-bos-etcd-tnpv8x6cxv Alarms Set: ###
        ```

2.  Clear any etcd cluster alarms.

    A list of disarmed alarms will be returned. An empty list is returned if no alarms were set.

    -   Clear all etcd alarms set in etcd clusters.

        ```bash
        for pod in $(kubectl get pods -l app=etcd -n services \
                             -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Disarmed Alarms: ###"
            kubectl -n services exec ${pod} -- /bin/sh \
                    -c "ETCDCTL_API=3 etcdctl alarm disarm"
        done
        ```

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l app=etcd -n services -o \
        jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} Disarmed Alarms: \
        ###"; kubectl -n services exec ${pod} -- /bin/sh -c \
        "ETCDCTL_API=3 etcdctl alarm disarm"; done
        ```

        Example output:

        ```
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

    -   Clear all alarms in one particular etcd cluster.

        ```bash
        for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
                             -n services -o jsonpath='{.items[*].metadata.name}')
        do
            echo "### ${pod} Disarmed Alarms:  ###"
            kubectl -n services exec ${pod} -- /bin/sh \
                    -c "ETCDCTL_API=3 etcdctl alarm disarm"
        done
        ```

        ```bash
        ncn-w001# for pod in $(kubectl get pods -l etcd_cluster=cray-bos-etcd \
        -n services -o jsonpath='{.items[*].metadata.name}'); do echo "### ${pod} \
        Disarmed Alarms:  ###"; kubectl -n services exec ${pod} -- /bin/sh \
        -c "ETCDCTL_API=3 etcdctl alarm disarm"; done
        ```

        Example output:

        ```
        ### cray-bos-etcd-7cxq6qrhz5 Disarmed Alarms:  ###
        memberID:14039380531903955557 alarm:NOSPACE
        memberID:10060051157615504224 alarm:NOSPACE
        memberID:9418794810465807950 alarm:NOSPACE
        ### cray-bos-etcd-b9m4k5qfrd Disarmed Alarms:  ###
        ### cray-bos-etcd-tnpv8x6cxv Disarmed Alarms:  ###
        ```

