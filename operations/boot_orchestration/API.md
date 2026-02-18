# BOS API

* [Overview](#overview)
* [Server](#server)
* [Kubernetes deployment](#kubernetes-deployment)
* [Specification](#specification)
* [Source](#source)

## Overview

The BOS API is the point of contact for the user and all other services that want to query or update BOS data.
This includes the sub-services of BOS.

## Server

The BOS API server does not do any of the actual core BOS work -- that is, it does not boot or reboot any nodes, it does not
coordinate the progress of sessions, and so on. Its essential purpose is to act as a front-end for the
[BOS database](Database.md), allowing callers to safely create, read, modify, and delete entries in the database.

All of the core BOS work is done by [BOA](index.md#boot-orchestration-agent-boa).

## Kubernetes deployment

The BOS API server is a Kubernetes deployment in the `services` namespace:

```console
ncn-mw# kubectl get deployments -n services -l app.kubernetes.io/name=cray-bos
```

Example output:

```text
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
cray-bos   2/2     2            2           11d
```

The BOS API server runs in multiple Kubernetes pods in the `services` namespace.

```console
ncn-mw# kubectl get pods -n services -l app.kubernetes.io/name=cray-bos
```

Example output:

```text
NAME                       READY   STATUS    RESTARTS   AGE
cray-bos-994fc7c59-298g8   2/2     Running   0          50d
cray-bos-994fc7c59-z2r2q   2/2     Running   0          50d
```

## Specification

For the full OpenAPI specification, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

## Source

For the source for the BOS API server, including its Helm chart, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
