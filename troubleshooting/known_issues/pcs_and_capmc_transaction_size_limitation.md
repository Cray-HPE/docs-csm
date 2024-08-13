# Transaction Size Limitation for PCS and CAPMC

The Power Control Service (PCS) and Cray Advanced Platform Monitoring and Control (CAPMC) cannot handle large requests. The maximum number of nodes in a single request is approximately 2500 nodes.

## Identifying the issue

When the request is too large `cray power` will return the following message.

```text
Error: Internal Server Error:  etcdserver: request is too large
```

The logs for the `cray-power-control` pods will contain text like the following.

```text
level=error msg="etcdserver: request too large" func="github.com/Cray-HPE/hps-power-control/internal/storage.("ETCDStorage).TASTransiation" file="/go/src/github.com/Cray-HPE/hps-power-control/internal/storage etcd impl.go:520"
```

## Solution

Reduce the number of nodes in each request by running multiple `cray power` or `cray capmc` commands.
