# BOS database

* [Overview](#overview)
* [Access](#access)
* [Source](#source)

## Overview

All BOS data is stored in an etcd database running in pods in the `services` namespace.

```console
ncn-mw# kubectl get pods -n services -l app.kubernetes.io/instance=cray-bos,app.kubernetes.io/name=etcd
```

Example output:

```text
NAME              READY   STATUS    RESTARTS   AGE
cray-bos-etcd-0   2/2     Running   0          4d
cray-bos-etcd-1   2/2     Running   0          4d
cray-bos-etcd-2   2/2     Running   0          4d
```

## Access

All access to the BOS database is done by the [BOS API server](API.md).

## Source

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
