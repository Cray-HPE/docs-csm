# BOS Operators

* [Overview](#overview)
* [Execution loop](#execution-loop)
* [Options](#options)
* [Kubernetes deployment](#kubernetes-deployment)
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

> BOS operators are a feature of BOS v2 only.

BOS v2 has many different operators.
Each operator is responsible for doing a single basic task -- for example, powering on nodes,
discovering new nodes on the system and creating [BOS components](Components.md) for them,
or initializing a pending BOS v2 [session](Sessions.md).

The work for a BOS v2 session is done by several different operators, all acting independently of each other.
These operators are always running, even when no v2 session is actively underway.
This is a big difference from BOS v1, where each session created a new dedicated Kubernetes job
that handled everything associated with that v1 session.

## Execution loop

Each operator follows the same basic execution loop:

1. Search the [BOS v2 database](Database.md#bos-v2-databases) (using the [BOS API](API.md))
   for any potential work for this operator.
1. Process that work, if any.
1. Update the [BOS v2 database](Database.md#bos-v2-databases) (using the [BOS API](API.md))
   based on the work that was done, if applicable.
1. Sleep for an interval, then go back to the top of the loop.

## Options

Some [BOS Options](Options.md) apply only to specific operators -- these are noted in
the relevant operator descriptions in the [Operator list](#operator-list).
The following BOS options apply to operators generally:

* [`logging_level`](Options.md#logging_level)
    * This option determines the verbosity of BOS logging, including the BOS operator logs.
    * The operator logs can be viewed by looking at the logs of the pods in the operator
      [Kubernetes deployment](#kubernetes-deployment).
* [`polling_frequency`](Options.md#polling_frequency)
    * This option determines how long the sleep interval is in the [execution loop](#execution-loop).
    * The only operator which is an exception to this is the [`discovery`](#discovery) operator, which
      instead uses the [`discovery_frequency`](Options.md#discovery_frequency) option for its sleep interval.
* [`max_component_batch_size`](Options.md#max_component_batch_size)
    * This option limits the number of nodes included in a single API request (to any service,
      including to BOS itself).
* Service timeout options: [`bss_read_timeout`](Options.md#bss_read_timeout),
  [`cfs_read_timeout`](Options.md#cfs_read_timeout),
  [`hsm_read_timeout`](Options.md#hsm_read_timeout), and
  [`pcs_read_timeout`](Options.md#pcs_read_timeout)
    * These options determine how long BOS operators will wait for a response to API requests to these services.
    * These options are not specific to any particular operators. However, not all operators call all of these
      services, so some of these options will not impact some operators.

See [Options](Options.md) for more information.

## Kubernetes deployment

(`ncn-mw#`) Each BOS operator has its own Kubernetes deployment in the `services` namespace.

```bash
kubectl get deployments -n services -l app.kubernetes.io/instance=cray-bos | grep '^cray-bos-operator-'
```

Example output:

```text
cray-bos-operator-actual-state-cleanup   1/1     1            1           11d
cray-bos-operator-configuration          1/1     1            1           11d
cray-bos-operator-discovery              1/1     1            1           11d
cray-bos-operator-power-off-forceful     1/1     1            1           11d
cray-bos-operator-power-off-graceful     1/1     1            1           11d
cray-bos-operator-power-on               1/1     1            1           11d
cray-bos-operator-session-cleanup        1/1     1            1           11d
cray-bos-operator-session-completion     1/1     1            1           11d
cray-bos-operator-session-setup          1/1     1            1           11d
cray-bos-operator-status                 1/1     1            1           11d
```

(`ncn-mw#`) The BOS operator pods run in the `services` namespace.

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

Typically, this operator has nothing to do, because the [`power-on` operator](#power-on) sets the desired configuration prior
to booting components. The exception is when a node is already booted and configured, and a BOS session is created to boot
(*not* reboot) the node using the same boot artifacts, but a different CFS configuration. In this case, the `power-on` operator
will never be called, and instead the `configuration` operator will take care of it.

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

For each enabled BOS component that has a `power-on-pending` status, this operator does the following:

1. Writes the kernel, kernel parameters, and `initrd` to [BSS](../../glossary.md#boot-script-service-bss)
   and records the `bss-referral-token` that is sent back by BSS.

    For more information on the information that is being written to BSS, see
    [Upload Node Boot Information to Boot Script Service (BSS)](Upload_Node_Boot_Information_to_Boot_Script_Service_BSS.md).

1. Patches the node in CFS to disable it, clear its state, and set its desired configuration.

1. Calls PCS to power on the node.

> Unlike almost all parts of BOS other than the [API server](API.md), this operator directly accesses a
> [BOS database](Database.md). Specifically, after the BSS step in the above procedure,
> the operator writes an entry in the boot artifacts database. The key for the entry is the BSS
> token. The value of the entry is a dictionary containing the kernel, kernel, parameters, and `initrd`.
> This is the only case where this operator directly interacts with any BOS database; all other
> interactions go through the BOS API, like usual.

### `session-cleanup`

This operator deletes completed v2 sessions from BOS that are older than a specified age.

The age is controlled by the [`cleanup_completed_session_ttl`](Options.md#cleanup_completed_session_ttl) option.
If that option has a zero value, then this cleanup behavior is disabled.

### `session-completion`

For each running BOS v2 session, this operator checks to see if any BOS components are associated with
that session and still have work (or [staged work](Stage_Changes_with_BOS.md)) to be done.
If not, then it marks the session as complete and saves a final status for the session.

More specifically, for a given running session, the operator looks for all components which meet
either of the following criteria:

* The component is enabled and its `session` field is set to the name of the session
    * These represent components that BOS is still working to get into their desired state
* The component has its `staged_state`.`session` field set to the name of the session
    * These represent components that have been staged in BOS

If the [`clear_stage`](Options.md#clear_stage) is set to true, then BOS will not clear the staged
state of nodes after [applying the staged state](Stage_Changes_with_BOS.md#apply-a-staged-state). This in turn
will mean that the associated staged session will never be marked complete by the `session-completion` operator.

The `session-completion` operator is not properly aware of [multi-tenancy](Multi_tenancy_with_BOS.md).
The algorithm described above only uses the name of a session to determine which components are associated
with it, even though multiple sessions may have the same name because of
[tenant name-spacing](Multi_tenancy_with_BOS.md#tenant-name-spacing). For more information, see
[Sessions with tenancy](Multi_tenancy_with_BOS.md#sessions-with-tenancy).

### `session-setup`

This operator monitors for pending v2 sessions and moves them into the running state.
For each pending session found, the following procedure is performed by the operator:

1. Contact HSM to get the following:

    * A list of the node membership for all [groups](../hardware_state_manager/Component_Groups_and_Partitions.md),
      [roles, and subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md).
    * Information on every node, such as its hardware architecture and whether it is enabled or disabled in HSM.

1. For each [boot set](Session_Templates.md#boot-sets) in the [session template](Session_Templates.md), the operator
   does the following steps:

    1. The target node list for the boot set starts empty.

    1. If the boot set [`node_list`](Session_Templates.md#node-list) field is set, add those components to the target list.

    1. If this session is on behalf of a tenant, and if any nodes were found in the previous
       step, make sure that all of them belong to the tenant. If not, raise an error.

       See [Session templates with tenancy](Multi_tenancy_with_BOS.md#session-templates-with-tenancy).

    1. For any HSM groups specified in the [`node_groups`](Session_Templates.md#node-groups) field of the boot set,
       add the associated components to the target list.

    1. For any HSM roles or subroles specified in the [`node_roles_groups`](Session_Templates.md#node-roles-groups) field,
       add the associated components to the target list.

    1. If a [session limit](Limit_the_Scope_of_a_BOS_Session.md) was specified, apply it to the target list,
       removing any components which do not match the limit.

    1. If this session is on behalf of a tenant, remove any components that do not belong to the tenant (according to
       [TAPMS](../../glossary.md#tenant-and-partition-management-system-tapms).

    1. Remove any components whose hardware architecture in HSM does not match the
       [boot set architecture](Session_Templates.md#architecture).

    1. If the session `include_disabled` field is false, then remove any components that are disabled in HSM.

       See [Optional session creation arguments](Manage_a_BOS_Session.md#optional-session-creation-arguments).

    1. For each target component, determine what target state it should have in BOS. This is based on the session operation, the
       CFS settings in the session template, and the boot artifacts in the boot set.

        * If this is a non-staged session (`staged` field is false), then this will be used to determine the desired state.

        * If this is a [staged session](Stage_Changes_with_BOS.md), then this will be used to determine the staged state.

1. For each component that was identified in the previous step, the BOS component record will be patched with the following changes:

    * Set the target state (as described in the final substep of the previous step).
    * Clear the error field.

    If this is not a staged session, then the patch will also include the following:

    * If this is a reboot operation, clear the actual state.
    * Set the session field to the name of the session.
    * Set [enabled](Components.md#enabled) to true.
    * Set the last action field to `session_setup`.

1. Patch the BOS session record to make the following changes:

    * Set `status`.`status` field to `running`.
    * Set `components` field to a comma-separated list of the target components.

Related: [BOS v2 sessions and HSM locks](Sessions.md#bos-sessions-and-hsm-locks).

### `status`

This operator is the workhorse that updates the status of components in BOS.
For each component that is enabled in BOS, the status operator collects the
following information:

* Component desired state
* Component current state
* Node power state (as reported by PCS)
* Node configuration status (as reported by CFS)

The above information is used to determine whether or not the component
should be disabled in BOS, and what the new component status should be.
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
* [`disable_components_on_completion`](Options.md#disable_components_on_completion)
    * This experimental option controls whether the status operator disables components in BOS when they have reached their desired session state.
    * This is false by default, which means that after the component has reached its desired session state, BOS will take no further action on
      that component until a new BOS session is initiated.
    * If this is set to true, then BOS will take action to ensure that the component remains in its desired state. For example, if the node is
      manually booted to a different image, BOS would reboot it back to the previous image.
    * Setting this option to true is not recommended in a production environment.
    * This option is removed from BOS in CSM 1.7.

## Source

The source for the BOS operators is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
