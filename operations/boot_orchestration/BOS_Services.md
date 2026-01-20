# BOS Services

The Boot Orchestration Service (BOS) consists of many different micro-services and other components.

* [BOS API](#bos-api)
* [BOS database](#bos-database)
* [Boot Orchestration Agent (BOA)](#boot-orchestration-agent-boa)
* [BOS operators](#bos-operators)
    * [`actual-state-cleanup`](#actual-state-cleanup)
    * [`configuration`](#configuration)
    * [`discovery`](#discovery)
    * [`power-off-forceful`](#power-off-forceful)
    * [`power-off-graceful`](#power-off-graceful)
    * [`power-on`](#power-on)
    * [`session-cleanup`](#session-cleanup)
    * [`session-completion`](#session-completion)
    * [`session-setup`](#session-setup)
    * [`status`](#status)
* [BOS reporter](#bos-reporter)

## BOS API

The API is the point of contact for the user and all other services, including BOS' own services, that want to query or update BOS data.

The BOS API server does not do any of the actual core BOS work -- that is, it does not boot or reboot any nodes, it does not
coordinate the progress of sessions, and so on. Its essential purpose is to act as a front-end for the
[BOS database](#bos-database), allowing callers to safely create, read, modify, and delete entries in the database.
All of the core BOS work is done by the [BOS operators](#bos-operators) and the [BOS reporter](#bos-reporter).

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

For a user-friendly summary of the BOS API, see [Boot Orchestration Service API](../../api/bos.md).
For the full BOS API specification and the source for the BOS API server, see the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

## BOS database

(`ncn-mw#`) All BOS data is stored in a Redis database running in a pod in the `services` namespace.

```bash
kubectl get pods -n services -l app.kubernetes.io/name=cray-bos-db
```

Example output:

```text
NAME                           READY   STATUS    RESTARTS   AGE
cray-bos-db-58f4967657-rdj9l   2/2     Running   0          70d
```

The Helm chart for the BOS database is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

## Boot Orchestration Agent (BOA)

BOA was a feature of BOS v1 only. It was a Kubernetes job that was responsible for tracking all of the components in a BOS session and taking actions against them.

The source for BOA is located in the
[`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) open source GitHub repository.

## BOS operators

The BOS operators were introduced in BOS v2.
BOS has many different operators, each of which follows the same basic loop:

1. Search the [BOS database](#bos-database) (using the [BOS API](#bos-api))
   for any potential work for this operator.
1. Process that work, if any.
1. Update the [BOS database](#bos-database) (using the [BOS API](#bos-api))
   based on the work that was done, if applicable.
1. Sleep for an interval, then go back to the top of the loop.

Each operator is responsible for doing a single basic task -- for example, powering on nodes,
discovering new nodes on the system, or initializing a new session.

* [`actual-state-cleanup`](#actual-state-cleanup)
* [`configuration`](#configuration)
* [`discovery`](#discovery)
* [`power-off-forceful`](#power-off-forceful)
* [`power-off-graceful`](#power-off-graceful)
* [`power-on`](#power-on)
* [`session-cleanup`](#session-cleanup)
* [`session-completion`](#session-completion)
* [`session-setup`](#session-setup)
* [`status`](#status)

The work for a BOS session is done by several different operators, all acting independently of each other.
These operators are always running, even when no BOS session is actively underway.
This is a big difference from BOS version 1, where each session created a new dedicated Kubernetes job
that handled everything associated with that session.

(`ncn-mw#`) The BOS operators run in Kubernetes pods in the `services` namespace.

```bash
kubectl get pods -n services | grep '^cray-bos-operator-'
```

Example output:

```text
cray-bos-operator-actual-state-cleanup-596dc4766c-xsdg2           2/2     Running             0              50d
cray-bos-operator-configuration-865f95f7d7-2j2tf                  2/2     Running             0              50d
cray-bos-operator-discovery-698b44f9f9-fhs9c                      2/2     Running             0              50d
cray-bos-operator-power-off-forceful-666f76c98f-mx5vb             2/2     Running             0              50d
cray-bos-operator-power-off-graceful-6489689c99-wch2p             2/2     Running             0              50d
cray-bos-operator-power-on-7d778c67cc-8vbrj                       2/2     Running             0              50d
cray-bos-operator-session-cleanup-68c4cdbcc-qfvvr                 2/2     Running             0              50d
cray-bos-operator-session-completion-756b4ddfb5-584bk             2/2     Running             0              50d
cray-bos-operator-session-setup-654544c589-9t9rr                  2/2     Running             0              50d
cray-bos-operator-status-7665867877-gcj59                         2/2     Running             0              50d
```

The source for the BOS operators is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.

### `actual-state-cleanup`

This operator clears the `actual_state` field for components when the field has not been updated with the `component_actual_state_ttl` time.
This ensures that BOS keeps accurate information on the state of all components.
See [Options](Options.md) for more information on setting `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.

### `configuration`

This operator is responsible for setting the desired configuration in CFS for components that are in the `configuring` phase of the boot process.
Because the `power-on` sets the desired configuration prior to booting components, this is typically only needed when booting to the same boot artifacts, but with a different configuration.

### `discovery`

This operator periodically checks with HSM to discover new components and create the component records for BOS.

### `power-off-forceful`

This operator calls PCS to forcefully power off components when a previous power off action fails to power off the component.

### `power-off-graceful`

This operator calls PCS to gracefully power off components for components that have a `power-off-pending` status.

### `power-on`

This operator calls PCS to power on components for components that have a `power-on-pending` status.

### `session-cleanup`

This operator deletes sessions from BOS that are older than the `cleanup_completed_session_ttl` value.

### `session-completion`

This operator marks sessions as complete and saves a final status for the session when all components that a session is responsible for have been disabled.

### `session-setup`

This operator monitors for pending sessions, and translates the session template into a list of components and the boot artifacts and configuration to be set as the desired state for those components.

Related: [BOS sessions and HSM locks](Sessions.md#bos-sessions-and-hsm-locks).

### `status`

This operator monitors all components that are enabled in BOS and sets their `phase` based on the components desired and current state in BOS, the components power state as reported by HSM, and the component's configuration status as reported by CFS.

## BOS reporter

The `bos-reporter` was introduced in BOS v2.
It runs on all components managed by BOS and periodically reports back the actual state of the component it runs on.
This is installed as a package at image customization time.
See [Options](Options.md) for more information on setting `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.

The `bos-reporter` RPM must be installed on nodes in order for BOS to operate on them properly.
It is responsible for reporting the current state and boot artifacts for a node. This is necessary for BOS
to know when a node has successfully been booted into the correct state.

The reporting is done using the [BOS API](#bos-api). Because of this, the reporting will not work on a node without
network access to the [BOS API](#bos-api).

The BOS reporter is somewhat analogous to the [CFS](../../glossary.md#configuration-framework-service-cfs) state reporter.

The location of the BOS reporter source code depends on its version. Prior to version 3.0.0,
the source for the BOS reporter is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
Starting in version 3.0.0, the source for the BOS reporter is located in the
[`Cray-HPE/bos-reporter`](https://github.com/Cray-HPE/bos-reporter/) open source GitHub repository.
