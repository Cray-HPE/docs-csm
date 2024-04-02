# Hang Listing BOS Sessions

* [Overview](#overview)
* [Symptoms](#symptoms)
* [Remedy](#remedy)
* [Prevention](#prevention)

## Overview

BOS v1 loses the ability to list its sessions after too many of them exist in its
database. This has only been observed happening when the total number of
sessions in the database is well over 1000.

## Symptoms

When this situation occurs, attempts to list BOS sessions using the API or CLI will
hang. This may also be noticed when performing the
[Validate CSM Health](../../operations/validate_csm_health.md) procedure -- the `cmsdev`
test tool will exhibit the same hang when it tries to query BOS for a session list.

In order to confirm that these hangs are the result of this problem, run the
following command:

```bash
ncn-mw# kubectl -n services logs --max-log-requests 50 -l app.kubernetes.io/name=cray-bos | \
            grep -C4 'Received message larger than max'
```

If the problem being described on this page is happening on the system, then the output
should contain something similar to the following:

```text
WARNING:bos.server.dbclient:Connect failed to cray-bos-etcd-client.  Caught <_InactiveRpcError of RPC that terminated with:
        status = StatusCode.RESOURCE_EXHAUSTED
        details = "Received message larger than max (4870618 vs. 4194304)"
        debug_error_string = "{"created":"@1682101300.469469814","description":"Error received from peer ipv4:10.26.231.219:2379","file":"src/core/lib/surface/call.cc","file_line":966,"grpc_message":"Received message larger than max (4870618 vs. 4194304)","grpc_status":8}"
```

## Remedy

The remedy to the situation is to manually delete the BOS v1 sessions from the underlying BOS etcd database.

1. Identify the name of a BOS etcd pod.

    ```bash
    ncn-mw# BOS_ETCD_POD=$(kubectl get pods -n services -l app=etcd,etcd_cluster=cray-bos-etcd \
                            | grep Running | head -1 | awk '{ print $1 }')
    ncn-mw# echo "${BOS_ETCD_POD}"
    ```

    Example output:

    ```text
    cray-bos-etcd-hwb88pqklg
    ```

1. Optionally, list the number of entries in the BOS v1 session database.

    > Note: This number does not equal the number of BOS v1 sessions, because each session creates
    > multiple entries in the database.

    ```bash
    ncn-mw# kubectl exec -n services -it "${BOS_ETCD_POD}" -c etcd -- sh -c \
                'ETCDCTL_API=3 etcdctl get /session/ --prefix --keys-only' | grep "^/session/" | wc -l
    ```

    Example output:

    ```text
    10836
    ```

1. (Delete all of the BOS v1 sessions from its database.

    The output of this command is the number of entries deleted from the database.

    ```bash
    ncn-mw# kubectl exec -n services -it ${BOS_ETCD_POD} -c etcd -- sh -c \
                'ETCDCTL_API=3 etcdctl del /session/ --prefix'
    ```

    Example output:

    ```text
    10836
    ```

1. Verify that BOS v1 sessions are now able to be listed.

    ```bash
    ncn-mw# cray bos session list --format json
    ```

    Expected output:

    ```json
    []
    ```

## Prevention

This situation can be prevented by periodically deleting completed BOS v1 sessions.

In CSM 1.3.0 and later, using BOS v2 will also prevent the problem, because BOS v2 is not
subject to this limitation; in addition, BOS v2 includes automatic cleanup of old completed sessions.
