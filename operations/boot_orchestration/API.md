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
[BOS database](Database.md), allowing callers to safely create, read, modify, and delete entries in the database.
All of the core BOS work is done by the [BOS operators](Operators.md) and the [BOS reporter](Reporter.md).

> Other than the API server, there are only two parts of BOS that ever directly access the BOS databases.
> See [BOS database access](Database.md#access) for details.

See also: [Race Conditions in BOS and CFS](../../troubleshooting/known_issues/Race_Conditions_in_BOS_and_CFS.md).

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

Although many of the [BOS Options](Options.md) do not impact the behavior of the API server,
the following options do:

* [`logging_level`](Options.md#logging_level)
    * This option determines the verbosity of BOS logging, including the BOS API server.
    * The server logs can be viewed by looking at the logs of the pods in the server
      [Kubernetes deployment](#kubernetes-deployment).
* [`ims_read_timeout`](Options.md#ims_read_timeout)
    * This option determines how long the BOS API server will wait for a response to API requests to IMS.
    * BOS has other service-specific timeout options; these options would also apply to the BOS API server,
      but the API server does not make calls to any of those other services.
* [`ims_errors_fatal`](Options.md#ims_errors_fatal) and
  [`ims_images_must_exist`](Options.md#ims_images_must_exist)
    * These options control how BOS deals with IMS issues during
      [boot set validation](Session_Templates.md#boot-set-validation).
* [`session_limit_required`](Options.md#session_limit_required)
    * This option determines whether or not a [session limit](Limit_the_Scope_of_a_BOS_Session.md)
      is required when creating a new [session](Sessions.md).
* [`reject_nids`](Options.md#reject_nids)
    * During [boot set validation](Session_Templates.md#boot-set-validation), this option controls whether
      [NIDs](../../glossary.md#node-id-nid) in the [`node_list`](Session_Templates.md#node-list)
      field is a fatal error.
    * This option controls whether NIDs in the [session limit](Limit_the_Scope_of_a_BOS_Session.md)
      is a fatal error when creating a new [session](Sessions.md).

See [Options](Options.md) for more information.

## Migration job

When the `cray-bos` [Kubernetes deployment](#kubernetes-deployment) is upgraded, the `cray-bos-migration`
job runs in the `services` namespace. It checks data in the [BOS databases](Database.md) and fixes some
cases of invalid data (for example, session template names that are not legal under the API
[Specification](#specification).

The migration job pods first wait until all of the databases are accessible. In some cases, this will time
out before the databases are ready, and the pod will exit in failure. The job migration automatically
retries when the pod fails; in most cases, the databases are ready in time when the next migration job pod runs.

## Specification

For a user-friendly summary of the BOS API specification, see [Boot Orchestration Service API](../../api/bos.md).
For the full OpenAPI specification, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

## Source

For the source for the BOS API server, including its Helm chart, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
