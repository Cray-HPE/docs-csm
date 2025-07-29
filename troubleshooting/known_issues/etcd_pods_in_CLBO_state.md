# `etcd` Pods in CLBO State

## Issue description

When powering on the management Kubernetes cluster installed with CSM 1.7, or scaling up an `etcd` cluster after being scaled down in CSM 1.7, the `etcd` pods fail to come up and get stuck in the `CrashLoopBackOff` state.
This happens because the upstream image contains a bug that fails to obtain the member information from the existing `etcd` cluster.

## Error identification

When the issue occurs, the `etcd` pods get stuck in the `CrashLoopBackOff` state.

The logs from the `etcd` pod will contain messages similar to the following:

```text
etcd 16:13:34.96 INFO  ==> Detected data from previous deployments
{"level":"warn","ts":"2025-07-29T16:14:06.299785Z","logger":"etcd-client","caller":"v3@v3.5.21/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0001ee000/cray-bss-bitnami-etcd-0.cray-bss-bitnami-etcd-headless.services.svc.cluster.local:2379","attempt":0,"error":"rpc error: code = Unavailable desc = upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: delayed connect error: Connection refused"}
...
{"level":"warn","ts":"2025-07-29T16:14:11.115080Z","logger":"etcd-client","caller":"v3@v3.5.21/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0001ee000/cray-bss-bitnami-etcd-0.cray-bss-bitnami-etcd-headless.services.svc.cluster.local:2379","attempt":29,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
Error: context deadline exceeded
etcd 16:14:11.12 INFO  ==> No member id found
etcd 16:14:21.26 WARN  ==> Cluster not responding!
etcd 16:14:21.28 ERROR ==> There was no snapshot to restore!
```

## Fix description

The workaround is to rebuild the unhealthy `etcd` clusters by following [Rebuild Unhealthy etcd Clusters](../../operations/kubernetes/Rebuild_Unhealthy_etcd_Clusters.md).
