# Kafka Failure after CSM 1.2 Upgrade

Occasionally the `cray-shared-kafka-kafka` pods will be restarted before the
`cray-shared-kafka-zookeeper` pods are ready. If this happens then the shared
`kafka` cluster will start to fail.

## Error Messages

### `cray-shared-kafka-kafka-#` pods

```text
2022-05-20 19:43:02,242 INFO Socket connection established to localhost/127.0.0.1:2181, initiating session (org.apache.zookeeper.ClientCnxn) [main-SendThread(localhost:2181)]
2022-05-20 19:43:02,245 WARN Session 0x1001ec4c0730001 for server localhost/127.0.0.1:2181, unexpected error, closing socket connection and attempting reconnect (org.apache.zookeeper.ClientCnxn) [main-SendThread(localhost:2181)]
java.io.IOException: Connection reset by peer
```

### `cray-shared-kafka-zookeeper-#` pods

```text
2022.05.20 19:44:06 LOG3[1:139846453499648]: SSL_connect: 1408F10B: error:1408F10B:SSL routines:SSL3_GET_RECORD:wrong version number
cray-shared-kafka-zookeeper-# logs:
io.netty.handler.codec.DecoderException: javax.net.ssl.SSLHandshakeException: Client requested protocol TLSv1 is not enabled or supported in server context
```

### `strimzi-cluster-operator` pod

```text
Caused by: org.apache.kafka.common.errors.TimeoutException: Timed out waiting for a node assignment. Call: listTopics
2022-05-20 19:43:47 INFO  KafkaRoller:292 - Reconciliation #1395(timer) Kafka(services/cray-shared-kafka): Could not roll pod 1, giving up after 10 attempts. Total delay between attempts 127750ms
io.strimzi.operator.cluster.operator.resource.KafkaRoller$ForceableProblem: An error while trying to determine rollability
```

## Solution

Run the `kafka-restart.sh` script to fix this issue

```bash
ncn# /usr/share/doc/csm/upgrade/1.2/scripts/strimzi/kafka-restart.sh

```
