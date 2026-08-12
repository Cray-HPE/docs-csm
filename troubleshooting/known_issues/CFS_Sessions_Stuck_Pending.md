# CFS Sessions Stuck Pending

Troubleshoot issues where [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
[sessions](../../operations/configuration_management/Configuration_Sessions.md) are being created
but remain in the `pending` state, with no Kubernetes jobs or pods created.

## Symptoms

The signature of this issue is found in the CFS Operator logs.

The CFS Operator logs should show that it is attempting to create sessions, but is unable to find the session records.

```console
ncn-mw# kubectl logs -n services -l app.kubernetes.io/instance=cray-cfs-operator
```

If this issue is happening, then messages like the following should be in the logs:

```text
2022-08-24 05:48:06,476 - INFO    - cray.cfs.operator.events.session_events - EVENT: CREATE batcher-3b78941e-1c06-474c-89fe-bf241f5002e4
2022-08-24 05:48:06,509 - ERROR   - cray.cfs.operator.cfs.sessions - Unexpected response from CFS: 404 Client Error: Not Found for url: http://cray-cfs-api/v2/sessions/batcher-3b78941e-1c06-474c-89fe-bf241f5002e4
```

## Explanation

This issue can happen in cases where CFS sessions are being created too fast for the CFS Operator to keep up with.

This issue is most often seen with sessions created by
CFS Batcher.
If that is happening, then the CFS Batcher logs should show that it is creating
sessions, but giving up waiting for those sessions to start:

```console
ncn-mw# kubectl logs -n services -l app.kubernetes.io/instance=cray-cfs-batcher
```

Example output:

```text
2022-08-24 04:09:12,391 - WARNING - batcher.batch - Session batcher-d7f9bf52-e5f6-4742-849b-4086b1d59ab1 is stuck in pending and will be deleted.
2022-08-24 04:09:12,492 - WARNING - batcher.batch - Session batcher-77c3c4d1-df39-4ebc-a6b4-32b8e102bdc5 is stuck in pending and will be deleted.
2022-08-24 04:09:12,638 - WARNING - batcher.batch - Session batcher-f9a513c1-47ad-4539-98cc-b3f418f6b8bd is stuck in pending and will be deleted.
2022-08-24 04:09:12,761 - WARNING - batcher.batch - Session batcher-7a291f2f-0149-46d7-889b-08331a46af2c is stuck in pending and will be deleted.
2022-08-24 04:09:15,144 - WARNING - batcher.batch - Session batcher-b6c35dcc-b8b9-421b-9090-23bfc2a72ac3 is stuck in pending and will be deleted.
```

## Fix

This issue exists in all CSM versions prior to CSM 1.7.0.

## Remediation

If the rapid CFS session creation is being done by an administrator (as opposed to being done automatically by CFS Batcher),
then the rate of session creation should be reduced until the problem is no longer observed.

If the rapid CFS session creation is being done by CFS Batcher, then the easiest method to resolve the issue is by setting the
[`batcherMaxBackoff` option](../../operations/configuration_management/CFS_Global_Options.md#batcher-maximum-backoff)
to a higher value. This will slow automatic session creation in these situations and give the CFS Operator a chance to catch up.
In most cases, the default value of `3600` (1 hour) is sufficient to prevent this problem.

The following command sets the option back to the default value.

```console
ncn-mw# cray cfs options update --batcher-max-backoff 3600
```

The issue should eventually resolve automatically.

If there is a reason that users cannot wait for the back-off to resolve this automatically,
then the following procedure can be used to purge the event queue. This will disrupt CFS
operation and may disrupt existing sessions, so caution should be used.

1. If any others users or scripts are creating sessions, make sure that they have stopped.

1. Disable CFS Batcher session creation, if it is not already disabled.

    1. Check the [CFS options](../../operations/configuration_management/CFS_Global_Options.md) to see if it is already disabled.

        If the following command displays `false`, then CFS Batcher is enabled.

        ```console
        ncn-mw# cray cfs options list --format json | jq '.batcher_disable'
        ```

    1. Disable CFS Batcher, if it is enabled.

        ```console
        ncn-mw# cray cfs options update --batcher-disable true
        ```

1. Start a new consumer on the Kafka event queue.

    1. Open a shell in a Kafka pod.

        ```console
        ncn-mw# kubectl -n services  exec -it  cray-shared-kafka-kafka-0 -c kafka -- /bin/bash
        ```

    1. Start a console consumer on the CFS event topic using the `cfs-operator` consumer group.

        ```console
        pod# bin/kafka-console-consumer.sh --bootstrap-server cray-shared-kafka-kafka-0.cray-shared-kafka-kafka-brokers.services.svc.cluster.local:9092 \
                 --topic cfs-session-events --group cfs-operator
        ```

       This command will likely produce not output at first, while Kafka re-balances the consumer group. Leave this command running.

1. In a new window, scale down the `cfs-operator`.

    This forces the console consumer to handle the entire event queue.

    ```console
    ncn-mw# kubectl -n services scale --replicas=0 deployment/cray-cfs-operator
    ```

1. Wait until the output from the console consumer stops.

    Once the `cfs-operator` is scaled down, there should be a final burst of output from the console consumer. Wait until all output has stopped for at least a minute before continuing.

1. Cancel the console consumer command and exit the pod shell.

1. Restore `cfs-operator`.

    ```console
    ncn-mw# kubectl -n services scale --replicas=1 deployment/cray-cfs-operator
    ```

1. Enable `cfs-batcher` (if it was originally enabled).

    ```console
    ncn-mw# cray cfs options update --batcher-disable false
    ```
