# BOS Operators

* [Overview](#overview)
* [Execution loop](#execution-loop)
* [Options](#options)
* [Kubernetes pods](#kubernetes-pods)
* [Operator list](#operator-list)
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
* [Source](#source)

## Overview

> BOS operators were introduced in BOS v2. They did not exist in BOS v1.

BOS has many different operators.
Each operator is responsible for doing a single basic task -- for example, powering on nodes,
discovering new nodes on the system and creating [BOS components](Components.md) for them,
or initializing a pending [BOS session](Sessions.md).

The work for a BOS session is done by several different operators, all acting independently of each other.
These operators are always running, even when no session is actively underway.
This is a big difference from BOS version 1, where each session created a new dedicated Kubernetes job
that handled everything associated with that session.

## Execution loop

Each operator follows the same basic execution loop:

1. Search the [BOS database](Database.md) (using the [BOS API](API.md))
   for any potential work for this operator.
1. Process that work, if any.
1. Update the [BOS database](Database.md) (using the [BOS API](API.md))
   based on the work that was done, if applicable.
1. Sleep for an interval, then go back to the top of the loop.

## Options

Some [BOS Options](Options.md) apply only to specific operators -- these are noted in
the relevant operator descriptions in the [Operator list](#operator-list).
The following BOS options apply to operators generally:

* [`logging_level`](Options.md#logging_level)
    * This option determines the verbosity of the [BOS operator Kubernetes pod](#kubernetes-pods) logs.
* [`polling_frequency`](Options.md#polling_frequency)
    * This option determines how long the sleep interval is in the [execution loop](#execution-loop).
    * The only operator which is an exception to this is the [`discovery`](#discovery) operator, which
      instead uses the [`discovery_frequency`](Options.md#discovery_frequency) option for its sleep interval.
* [`max_component_batch_size`](Options.md#max_component_batch_size)
    * This option limits the number of nodes included in a single API request (to any service,
      including to BOS itself).
* Service timeout options: [`bss_read_timeout`](Options.md#bss_read_timeout),
  [`cfs_read_timeout`](Options.md#cfs_read_timeout),
  [`hsm_read_timeout`](Options.md#hsm_read_timeout),
  [`ims_read_timeout`](Options.md#ims_read_timeout), and
  [`pcs_read_timeout`](Options.md#pcs_read_timeout)
    * These options determine how long BOS operators will wait for a response to API requests to these services.
    * These options are not specific to any particular operators. However, not all operators call all of these
      services, so some of these options will not impact some operators.

See [Options](Options.md) for more information.

## Kubernetes pods

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

## Operator list

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

This operator clears the `actual_state` field for components when the field has not been updated within a specified time.
This ensures that BOS keeps accurate information on the state of all components.

The time limit is controlled by the [`component_actual_state_ttl`](Options.md#component_actual_state_ttl) option.

> **WARNING**: Unlike the [`cleanup_completed_session_ttl`](Options.md#cleanup_completed_session_ttl) option,
> a zero value for the `component_actual_state_ttl` option will **not** disable the cleanup behavior.
> For details, see [`component_actual_state_ttl`](Options.md#component_actual_state_ttl).

### `configuration`

This operator is responsible for setting the desired [configuration](../configuration_management/CFS_Configurations.md) in the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
for components that are in the `configuring` phase of the boot process.
Because the [`power-on` operator](#power-on) sets the desired configuration prior to booting components,
this is typically only needed when booting to the same boot artifacts, but with a different configuration.

### `discovery`

This operator checks the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
to discover new nodes. If any are found, it creates BOS component records for them.

For its [execution loop](#execution-loop), this operator sets its sleep interval to the
[`discovery_frequency`](Options.md#discovery_frequency) option. See [Options](Options.md) for more information.

### `power-off-forceful`

This operator calls the [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs)
to forcefully power off components when a previous power off action fails to power off the component.

### `power-off-graceful`

This operator calls PCS to gracefully power off components for components that have a `power-off-pending` status.

### `power-on`

This operator calls PCS to power on components for components that have a `power-on-pending` status.

### `session-cleanup`

This operator deletes sessions from BOS that are older than a specified age.

The age is controlled by the [`cleanup_completed_session_ttl`](Options.md#cleanup_completed_session_ttl) option.
If that option has a zero value, then this cleanup behavior is disabled.

### `session-completion`

This operator marks sessions as complete and saves a final status for the session.
This happens when all components that a session is responsible for have been disabled.

### `session-setup`

This operator monitors for pending sessions and moves them into the running state.
It uses the [session template](Session_Templates.md) and the session limit (if any) to determine the target components
for the session. It uses the session template to determine the appropriate boot artifacts and
(optionally) CFS configuration. It then updates the target components with the desired
target state, boot artifacts, and configuration.

Related: [BOS sessions and HSM locks](Sessions.md#bos-sessions-and-hsm-locks).

### `status`

This operator is the workhorse that updates the state of BOS components.
For each component that is enabled in BOS, the status operator uses the
following information to determine the correct state for the component:

* Component desired state
* Component current state
* Node power state (as reported by PCS)
* Node configuration status (as reported by CFS)

This determination is also impacted by the following options:

* [`default_retry_policy`](Options.md#default_retry_policy)
    * This option determines how many times a given action will be attempted for a given component before giving up.
* [`max_boot_wait_time`](Options.md#max_boot_wait_time)
    * This option determines how long to wait for a component to complete booting to the point where the
      [BOS reporter](Reporter.md) on the component has contacted BOS.
    * If this time is exceeded, the boot is considered to have failed.
* [`max_power_off_wait_time`](Options.md#max_power_off_wait_time)
    * This option determines how long to wait for a component to be powered off (as reported by PCS) after issuing a power off request (to PCS).
    * If this time is exceeded, the power off is considered to have failed.
* [`max_power_on_wait_time`](Options.md#max_power_off_wait_time)
    * This option determines how long to wait for a component to be powered on (as reported by PCS) after issuing a power on request (to PCS).
    * If this time is exceeded, the power on is considered to have failed.

## Source

The source for the BOS operators is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
