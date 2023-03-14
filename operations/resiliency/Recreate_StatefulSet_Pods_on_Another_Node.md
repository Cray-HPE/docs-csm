# Recreate StatefulSet Pods on Another Node

Some pods are members of StatefulSets, meaning that there is a very specific number of them, each likely running on a
different node. Similar to DaemonSets, these pods will never be recreated on another node as long as they are sitting in
a `Terminating` state.

**Warning:** This procedure should only be done for pods that are known to no longer be running. Corruption may occur if
the worker node is still running when deleting the StatefulSet pod in a `Terminating` state.

The design of StatefulSet pods prohibits the creation of new pods on another node. This is the expected behavior for
StatefulSet pods. In many cases, the StatefulSet is a set of only one pod. If a StatefulSet pod needs to be recreated on
another node, the `Terminating` pod needs to be force deleted then it will automatically recreate.

This procedure prevents services from being taken out of service when a node goes down.

## Prerequisites

- A StatefulSet pod failed to be moved to another healthy non-compute node \(NCN\) acting as a worker node.
- If the network is being brought down temporarily during testing, ignore any issues with StatefulSet pods until the
  testing is complete. These errors should be ignored because the nodes could have the network restored, and then
  the `Terminating` pod may go `ACTIVE` temporarily \(causing a race and corruption\) if it comes up at the same time as
  another StatefulSet running the pod. This is much more likely to occur during testing of a network outage.

## Procedure

1. View the StatefulSet pods on the system.

   Any of the pods with `x/1` in the READY column could be on a node that goes down, at which point that service will no
   longer be available.

   ```bash
   kubectl get StatefulSets -A
   ```

   Example output:

   ```text
   NAMESPACE        NAME                                                   READY              AGE
   backups          benji-k8s-postgresql                                   1/1                2d14h
   nexus            nexus                                                  1/1                2d14h
   services         cray-dhcp-kea-postgres                                 3/3                2d14h
   services         cray-hms-badger-postgres                               3/3                2d14h
   services         cray-keycloak                                          3/3                2d14h
   services         cray-rm-pals-postgres                                  3/3                2d14h
   services         cray-shared-kafka-kafka                                3/3                2d14h
   services         cray-shared-kafka-zookeeper                            3/3                2d14h
   services         cray-sls-postgres                                      3/3                2d14h
   services         cray-smd-postgres                                      3/3                2d14h
   services         gitea-vcs-postgres                                     1/1                2d14h
   services         keycloak-postgres                                      3/3                2d14h
   services         slingshot-controllers-kafka                            3/3                2d14h
   services         slingshot-controllers-zookeeper                        3/3                2d14h
   sma              cluster-kafka                                          3/3                2d14h
   sma              cluster-zookeeper                                      3/3                2d14h
   sma              elasticsearch-master                                   3/3                2d14h
   sma              mysql                                                  1/1                2d14h
   sma              sma-ldms-aggr-compute                                  1/1                2d14h
   sma              sma-ldms-aggr-ncn                                      1/1                2d14h
   sma              sma-monasca-agent                                      1/1                2d14h
   sma              sma-monasca-mysql                                      1/1                2d14h
   sma              sma-monasca-notification                               1/1                2d14h
   sma              sma-monasca-zoo-entrance                               1/1                2d14h
   sma              sma-postgres-cluster                                   2/2                96s
   sysmgmt-health   alertmanager-cray-sysmgmt-health-kube-p-alertmanager   1/1                2d14h
   sysmgmt-health   prometheus-cray-sysmgmt-health-kube-p-prometheus       1/1                2d14h
   vault            cray-vault                                             3/3                2d14h
   ```

1. Describe a service to find the StatefulSet pod name.

   The StatefulSet pod will have a name in the `StatefulSet-0` format. Vault is the service being described in the example
   below. The StatefulSet pod name is `cray-vault-0`.

   ```bash
   kubectl get pods -A -o wide | grep SERVICE_NAME
   ```

   Example output:

   ```text
   operators   cray-vault-operator-57dbbb7db5-9lr6z       1/1     Running        0    5d18h   10.40.0.11    ncn-w002   <none>  <none>
   services    cray-meds-vault-loader-bzgbd               0/2     Completed      0    5d18h   10.40.0.24    ncn-w002   <none>  <none>
   services    cray-reds-vault-loader-d9cn9               0/2     Completed      0    5d18h   10.40.0.25    ncn-w002   <none>  <none>
   vault       cray-vault-0                               4/4     Terminating    7    5d18h   10.42.0.21    ncn-w003   <none>  <none>
   vault       cray-vault-configurer-68754d5b69-knrsc     2/2     Running        0    92m     10.40.0.103   ncn-w002   <none>  <none>
   vault       cray-vault-configurer-68754d5b69-mwmlr     2/2     Terminating    0    5d18h   10.42.0.22    ncn-w003   <none>  <none>
   vault       cray-vault-etcd-4b2t84tp79                 1/1     Terminating    0    5d18h   10.42.0.27    ncn-w003   <none>  <none>
   vault       cray-vault-etcd-699ncq8s9c                 1/1     Running        0    5d18h   10.40.0.17    ncn-w002   <none>  <none>
   vault       cray-vault-etcd-hvmtrwjpsw                 1/1     Running        0    92m     10.47.0.110   ncn-w001   <none>  <none>
   vault       cray-vault-etcd-mx8qc596t9                 1/1     Running        0    5d18h   10.47.0.23    ncn-w001   <none>  <none>
   ```

1. Delete the StatefulSet pod in a `Terminating` state.

   The StatefulSet \(the controller\) will recreate the pod on a working node when the pod or the node it sits on is
   deleted. The command below assumes the pod is located on the downed node and is currently in a `Terminating` state.

   ```bash
   kubectl delete pod -n NAMESPACE POD_NAME --force --grace-period 0
   ```

   For example:

   ```bash
   kubectl delete pod -n vault cray-vault-0 --force --grace-period 0
   ```

   The StatefulSet will then recreate `cray-vault-0` on a node that is in `Ready` state.
