# BOS Services

The Boot Orchestration Service \(BOS\) consists of many different micro-services and other components, including the API, operators, and the BOS state reporter.

* [BOS API](#bos-api)
* [Boot Orchestration Agent \(BOA\)](#boot-orchestration-agent-boa)
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
* [BOS state reporter](#bos-state-reporter)

## BOS API

The API is the point of contact for the user and all other services, including BOS' own services, that want to query or update BOS data.

## Boot Orchestration Agent \(BOA\)

BOA is a feature of BOS v1 only. It is a Kubernetes job that is responsible for tracking all of the components in a BOS session and taking actions against them.

## BOS operators

The BOS operators are a v2 feature only.
Rather than relying on a single actor to handle all components and actions, the actions are broken up against several operators that monitor for components that require a specific action and handle only those components.

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

This operator calls CAPMC to forcefully power off components when a previous power off action fails to power off the component.

### `power-off-graceful`

This operator calls CAPMC to gracefully power off components for components that have a `power-off-pending` status.

### `power-on`

This operator calls CAPMC to power on components for components that have a `power-on-pending` status.

### `session-cleanup`

This operator deletes session from BOS that are older than the `cleanup_completed_session_ttl` value.

### `session-completion`

This operator marks sessions as complete and saves a final status for the session when all components that a session is responsible for have been disabled.

### `session-setup`

This operator monitors for pending sessions, and translates the session template into a list of components and the boot artifacts and configuration to be set as the desired state for those components.

### `status`

This operator monitors all components that are enabled in BOS and sets their `phase` based on the components desired and current state in BOS, the components power state as reported by HSM, and the component's configuration status as reported by CFS.

## BOS state reporter

The `bos-state-reporter` is a v2 feature only. It runs on all components managed by BOS and periodically reports back the actual state of the component it runs on.
This is installed as a package at image customization time.
See [Options](Options.md) for more information on setting `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.
