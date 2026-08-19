# BOS Databases

* [Overview](#overview)
* [BOS v2 databases](#bos-v2-databases)
    * [Kubernetes deployment](#kubernetes-deployment)
    * [Data organization](#data-organization)
* [BOS v1 database](#bos-v1-database)
* [Access](#access)
* [Source](#source)

## Overview

BOS v1 and BOS v2 store data in two different databases.
[Session templates](Session_Templates.md) are common between both BOS versions;
they are stored in the [BOS v2 databases](#bos-v2-databases).

## BOS v2 databases

All v2 BOS data is stored in Redis databases.

### Kubernetes deployment

(`ncn-mw#`) The BOS v2 databases are a Kubernetes deployment in the `services` namespace.

```bash
kubectl get deployments -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
cray-bos-db   1/1     1            1           11d
```

(`ncn-mw#`) The Redis database pod runs in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME                           READY   STATUS    RESTARTS   AGE
cray-bos-db-58f4967657-rdj9l   2/2     Running   0          70d
```

### Data organization

Within the Redis pod, the BOS v2 data is divided into 6 databases:

| *Database*                                                                 | *Key*                                                               |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [Components](Components.md)                                                | Component name ([xname](../../glossary.md#xname))                   |
| Boot artifacts (`initrd`, kernel, and kernel parameters)                   | [BSS](../../glossary.md#boot-script-service-bss) token              |
| [Options](Options.md)                                                      | `options`                                                           |
| [Session templates](Session_Templates.md)                                  | Hash based on [tenant](Multi_tenancy_with_BOS.md) and template name |
| [Sessions](Sessions.md)                                                    | Hash based on [tenant](Multi_tenancy_with_BOS.md) and session name  |
| [Session statuses](View_the_Status_of_a_BOS_Session.md#bos-session-status) | Hash based on [tenant](Multi_tenancy_with_BOS.md) and session name  |

* The options database has a single entry with a fixed key. This entry contains a dictionary of current BOS option values.
* BOS sessions and session templates are [name-spaced by tenant](Multi_tenancy_with_BOS.md#tenant-name-spacing),
  which requires their corresponding database keys to include the tenant information.

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

## Access

All access to the BOS databases is done by the [BOS API server](API.md), with two exceptions:

* The [`power-on` operator](Operators.md#power-on) directly writes to the BOS v2 boot artifacts database.
* The [migration job](API.md#migration-job) directly reads from and writes to most of the BOS v1 and v2 databases.
    * The migration job only runs when the `cray-bos` deployment is upgraded.

## Source

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
