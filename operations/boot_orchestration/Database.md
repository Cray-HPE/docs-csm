# BOS databases

* [Overview](#overview)
* [BOS v2 database](#bos-v2-database)
* [BOS v1 database](#bos-v1-database)
* [Source](#source)

## Overview

BOS v1 and BOS v2 store data in two different databases.
[Session templates](Session_Templates.md) are common between both BOS versions;
they are stored in the [BOS v2 database](#bos-v2-database).

## BOS v2 database

(`ncn-mw#`) All BOS v2 data is stored in a Redis database running in a pod in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME                           READY   STATUS    RESTARTS   AGE
cray-bos-db-58f4967657-rdj9l   2/2     Running   0          70d
```

## BOS v1 database

(`ncn-mw#`) All BOS v1 session data is stored in an etcd database running in pods in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/instance=cray-bos,app.kubernetes.io/name=etcd
```

Example output:

```text
NAME                      READY   STATUS    RESTARTS   AGE
cray-bos-bitnami-etcd-0   2/2     Running   0          4d
cray-bos-bitnami-etcd-1   2/2     Running   0          4d
cray-bos-bitnami-etcd-2   2/2     Running   0          4d
```

## Source

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
