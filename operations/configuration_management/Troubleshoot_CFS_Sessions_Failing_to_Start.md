# Troubleshoot CFS Sessions Failing to Start

Troubleshoot issues where Configuration Framework Service \(CFS\) sessions are being created, but the pods are never created and never run.

## Prerequisites

CFS-batcher is creating automatic sessions, but pods are not starting for those sessions. There are a number of communication reasons this could be happening, so check the `cfs-batcher` and `cfs-operator` logs for these signatures.

CFS-batcher logs should show that it is creating sessions, but giving up waiting for those sessions to start:

```text
2022-08-24 04:09:12,391 - WARNING - batcher.batch - Session batcher-d7f9bf52-e5f6-4742-849b-4086b1d59ab1 is stuck in pending and will be deleted.
2022-08-24 04:09:12,492 - WARNING - batcher.batch - Session batcher-77c3c4d1-df39-4ebc-a6b4-32b8e102bdc5 is stuck in pending and will be deleted.
2022-08-24 04:09:12,638 - WARNING - batcher.batch - Session batcher-f9a513c1-47ad-4539-98cc-b3f418f6b8bd is stuck in pending and will be deleted.
2022-08-24 04:09:12,761 - WARNING - batcher.batch - Session batcher-7a291f2f-0149-46d7-889b-08331a46af2c is stuck in pending and will be deleted.
2022-08-24 04:09:15,144 - WARNING - batcher.batch - Session batcher-b6c35dcc-b8b9-421b-9090-23bfc2a72ac3 is stuck in pending and will be deleted.
```

CFS-operator logs should show that it is attempting to create sessions, but is unable to find the session records.

```text
2022-08-24 05:48:06,476 - INFO    - cray.cfs.operator.events.session_events - EVENT: CREATE batcher-3b78941e-1c06-474c-89fe-bf241f5002e4
2022-08-24 05:48:06,509 - ERROR   - cray.cfs.operator.cfs.sessions - Unexpected response from CFS: 404 Client Error: Not Found for url: http://cray-cfs-api/v2/sessions/batcher-3b78941e-1c06-474c-89fe-bf241f5002e4
```

If these two things are true, then it is likely that CFS is creating new sessions faster than it can keep up with session creation events.

## Procedure

The primary method of handling this problem is the `batcher_max_backoff` option. This will slow automatic session creation in these situations and give the `cfs-operator` a chance to catch up.

(`ncn-mw#`) If this value has been changed from its default value of 3600 (1 hour), then it should be set back to that value:

 ```bash
cray cfs v3 options update --batcher-max-backoff 3600
```

The issue should eventually resolve automatically.

If there is a reason that users cannot wait for the back-off to resolve this automatically, then the following procedure can be used to purge the event queue. This will disrupt CFS operation and may disrupt existing sessions, so caution should be used.

1. (`ncn-mw#`) Disable session creation.

    If any others users or scripts are creating sessions, make sure that they have stopped. `cfs-batcher` should then be disabled.

    ```bash
    cray cfs v3 options update --batcher-disable true
    ```

1. Start a new consumer on the Kafka event queue.

    1. (`ncn-mw#`) Open a shell in a Kafka pod.

        ```bash
        kubectl -n services  exec -it  cray-shared-kafka-kafka-0 -c kafka -- /bin/bash
        ```

    1. (`pod#`) Start a console consumer on the CFS event topic using the `cfs-operator` consumer group.

        ```bash
        bin/kafka-console-consumer.sh --bootstrap-server cray-shared-kafka-kafka-0.cray-shared-kafka-kafka-brokers.services.svc.cluster.local:9092 \
            --topic cfs-session-events --group cfs-operator
        ```

       This command will likely produce not output at first, while Kafka re-balances the consumer group. Leave this command running.

1. (`ncn-mw#`) In a new window, scale down the `cfs-operator`.

    This forces the console consumer to handle the entire event queue.

    ```bash
    kubectl -n services scale --replicas=0 deployment/cray-cfs-operator
    ```

1. (`ncn-mw#`) Wait until the output from the console consumer stops.

    Once the `cfs-operator` is scaled down, there should be a final burst of output from the console consumer. Wait until all output has stopped for at least a minute before continuing.

1. (`pod#`) Cancel the console consumer command and exit the pod shell.

1. (`ncn-mw#`) Restore `cfs-operator`.

    ```bash
    kubectl -n services scale --replicas=1 deployment/cray-cfs-operator
    ```

1. (`ncn-mw#`) Enable `cfs-batcher`.

    ```bash
    cray cfs v3 options update --batcher-disable false
    ```
