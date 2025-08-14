# `cfs-api` Pods in CLBO State During CSM Install

## Issue description

When installing CSM, `cray-shared-kafka-kafka` Kubernetes pods in the `services` namespace fail to come up which results in
`cfs-api` pods in the `CrashLoopBackOff` state. This happens because of an issue with Zookeeper related to slow DNS.
Zookeeper fails to come up if the DNS is not set up for all hosts at startup. When this happens, the cluster gets stuck with
the Zookeeper pods running, but brokers not coming up.

This problem can be triggered by events such as slow DNS propagation to Kubernetes DNS subsystem.

For more information on the root cause, see [Zookeeper Issue #4708](https://issues.apache.org/jira/browse/ZOOKEEPER-4708).

## Error identification

When the issue occurs, the `cray-shared-kafka-kafka` pods in the `services` namespace fail to come up and will not be present,
and the `cfs-api` pods will be in the CLBO state.

The logs from `strimzi-cluster-operator-*` pod in the `operators` namespace will contain messages similar to the following:

```text
2024-10-04T22:16:54.899932465Z 2024-10-04 22:16:54 ERROR StaticHostProvider:148 - Unable to resolve address: cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc/<unresolved>:2181
2024-10-04T22:16:54.899952739Z java.net.UnknownHostException: cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc: Name or service not known
```

```text
2024-10-04T22:21:54.061164856Z 2024-10-04 22:21:54 ERROR VertxUtil:127 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka):Exceeded timeout of 300000ms while waiting for ZooKeeperAdmin connection to cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-1.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-2.cray-shared-kafka-zookeeper-nodes.services.svc:2181 to be connected
2024-10-04T22:21:54.061644246Z 2024-10-04 22:21:54 WARN  ZookeeperScaler:157 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka): Failed to connect to Zookeeper cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-1.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-2.cray-shared-kafka-zookeeper-nodes.services.svc:2181. Connection was not ready in 300000 ms.
2024-10-04T22:21:54.466771715Z 2024-10-04 22:21:54 WARN  ZooKeeperReconciler:834 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka): Failed to verify Zookeeper configuration
```

## Fix description

(`ncn-mw#`) The workaround is to delete the Zookeeper pods and let them be re-created by the Strimzi operator.

```bash
kubectl delete pods -n services -l strimzi.io/controller-name=cray-shared-kafka-zookeeper
```
