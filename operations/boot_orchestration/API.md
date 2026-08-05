# BOS API

* [Overview](#overview)
* [Server](#server)
* [Kubernetes deployment](#kubernetes-deployment)
* [Options](#options)
* [Migration job](#migration-job)
* [Specification](#specification)
* [Source](#source)

## Overview

The BOS API is the point of contact for the user and all other services that want to query or update BOS data.
This includes the sub-services of BOS.

## Server

The BOS API server does not do any of the actual core BOS work -- that is, it does not boot or reboot any nodes, it does not
coordinate the progress of sessions, and so on. Its essential purpose is to act as a front-end for the
[BOS databases](Database.md), allowing callers to safely create, read, modify, and delete entries in the databases.

All of the core BOS v2 work is done by the [BOS operators](Operators.md) and the [BOS reporter](Reporter.md).
For BOS v1, the work is done by [BOA](README.md#boot-orchestration-agent-boa).

> Other than the API server, there are only two parts of BOS that ever directly access the BOS databases.
> See [BOS database access](Database.md#access) for details.

## Kubernetes deployment

(`ncn-mw#`) The BOS API server is a Kubernetes deployment in the `services` namespace:

```bash
kubectl get deployments -n services -l app.kubernetes.io/name=cray-bos
```

Example output:

```text
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
cray-bos   2/2     2            2           11d
```

(`ncn-mw#`) The BOS API server runs in multiple Kubernetes pods in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos
```

Example output:

```text
NAME                       READY   STATUS    RESTARTS   AGE
cray-bos-994fc7c59-298g8   2/2     Running   0          50d
cray-bos-994fc7c59-z2r2q   2/2     Running   0          50d
```

## Options

Although many of the [BOS v2 Options](Options.md) do not impact the behavior of the API server,
the [`logging_level`](Options.md#logging_level) option does.
This option determines the verbosity of BOS logging, including the BOS API server.
This option also impacts the logging level for the BOS v1 portions of the API server.
The server logs can be viewed by looking at the logs of the pods in the server
[Kubernetes deployment](#kubernetes-deployment).

See [Options](Options.md) for more information.

> See also: [BOS Log Level Change Not Dynamic](../../troubleshooting/known_issues/BOS_Log_Level_Change_Not_Dynamic.md).

## Migration job

When the `cray-bos` [Kubernetes deployment](#kubernetes-deployment) is upgraded, the `cray-bos-migration`
job runs in the `services` namespace. It checks data in the [BOS databases](Database.md) and
for each [session template](Session_Templates.md) found in the BOS v1 session templates database, it
does the following:

1. Converts the BOS v1 template to follow the BOS v2 format.
1. Adds the converted template to the BOS v2 session templates database.
1. Removes the original template from the BOS v1 session templates database.

## Specification

For the full OpenAPI specification, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

## Source

For the source for the BOS API server, including its Helm chart, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
