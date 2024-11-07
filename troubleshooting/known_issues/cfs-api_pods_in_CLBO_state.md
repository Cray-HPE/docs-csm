# `CFS-API` pods in CLBO state during CSM install

## Issue Description

When installing CSM 1.6, `cray-shared-kafka-kafka-*` pods in the services namespace fail to come up which results in `CFS-API` pods in CLBO state. This happens because of an issue with Zookeeper related to slow DNS.
Zookeeper fails to come up if the DNS is not set up for all hosts at startup. When this happens, the cluster gets stuck at Zookeeper pods running, but brokers not coming up.

### Related Issue

- [Zookeeper Issue #4708](https://issues.apache.org/jira/browse/ZOOKEEPER-4708)

## Error Identification

When the issue occurs, the `cray-shared-kafka-kafka-*` pods in the services namespace fail to come up and will not be present.
Also, `CFS-API` pods will be in CLBO state.

The logs from `strimzi-cluster-operator-*` pod in the operators namespace will be throwing errors as follows:

```text
2024-10-04T22:16:54.899932465Z 2024-10-04 22:16:54 ERROR StaticHostProvider:148 - Unable to resolve address: cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc/<unresolved>:2181
2024-10-04T22:16:54.899952739Z java.net.UnknownHostException: cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc: Name or service not known

2024-10-04T22:21:54.061164856Z 2024-10-04 22:21:54 ERROR VertxUtil:127 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka):Exceeded timeout of 300000ms while waiting for ZooKeeperAdmin connection to cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-1.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-2.cray-shared-kafka-zookeeper-nodes.services.svc:2181 to be connected
2024-10-04T22:21:54.061644246Z 2024-10-04 22:21:54 WARN  ZookeeperScaler:157 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka): Failed to connect to Zookeeper cray-shared-kafka-zookeeper-0.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-1.cray-shared-kafka-zookeeper-nodes.services.svc:2181,cray-shared-kafka-zookeeper-2.cray-shared-kafka-zookeeper-nodes.services.svc:2181. Connection was not ready in 300000 ms.
2024-10-04T22:21:54.466771715Z 2024-10-04 22:21:54 WARN  ZooKeeperReconciler:834 - Reconciliation #1(watch) Kafka(services/cray-shared-kafka): Failed to verify Zookeeper configuration
```

## Error Conditions

This problem can be triggered by events like:

- Slow DNS propagation to Kubernetes DNS subsystem

## Fix Description

The workaround is to delete the zookeeper pods and let them be re-created by the Strimzi operator.

```bash
kubectl delete pods -n services -l strimzi.io/controller-name=cray-shared-kafka-zookeeper
```
