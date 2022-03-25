# Add NCNs and UANs to External DNS

Edit the cray-externaldns-coredns ConfigMap to associate names with the Customer Access Network \(CAN\) IP addresses for non-compute nodes \(NCNs\) and User Access Nodes \(UANs\) in external DNS.

The cray-externaldns-coredns file contains the configuration files for external DNS' CoreDNS instance.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  View the existing cray-externaldns-coredns ConfigMap.

    ```bash
    ncn-w001# kubectl -n services get configmap cray-externaldns-coredns -o jsonpath='{.data}'
    ```

    Example output:

    ```
    map[Corefile:.:53 {
        errors
        health
        log
        ready
        kubernetes cluster.local
        k8s_external internal.shasta
        prometheus 0.0.0.0:9153
        etcd SYSTEM_DOMAIN_NAME {
            stubzones
            path /skydns
            endpoint http://cray-externaldns-etcd-client:2379
        }
    }]
    ```

2.  Edit the cray-externaldns-coredns ConfigMap to add support for a static hosts file.

    ```bash
    ncn-w001# kubectl -n services edit configmaps cray-externaldns-coredns
    ```

    Add a "hosts" file configuration \(analogous to /etc/hosts\) and update the Corefile configuration so CoreDNS uses it. For example:

    ```bash
    data:
      Corefile: |-
        .:53 {
            errors
            health
            log
            ready
            kubernetes cluster.local
            k8s_external internal.shasta
            prometheus 0.0.0.0:9153
            hosts /etc/coredns/hosts {
               fallthrough
            }
            etcd SYSTEM_DOMAIN_NAME {
                stubzones
                path /skydns
                endpoint http://cray-externaldns-etcd-client:2379
            }
        }
      hosts: |-
        # IP FQDN short
        10.99.1.51 dn07.SYSTEM_DOMAIN_NAME dn07
    ```

3.  Restart the CoreDNS pods once the ConfigMap is updated.

    ```bash
    ncn-w001# kubectl -n services rollout status deployment cray-externaldns-coredns
    ```

    Example output:

    ```
    Waiting for deployment "cray-externaldns-coredns" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-externaldns-coredns" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-externaldns-coredns" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-externaldns-coredns" rollout to finish: 1 of 2 updated replicas are available...
    deployment "cray-externaldns-coredns" successfully rolled out
    ```

