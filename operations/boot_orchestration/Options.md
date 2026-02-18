# BOS Options

> **`NOTE`** This section is for Boot Orchestration Service (BOS) v2 only.

BOS provides a global service options endpoint for modifying the base configuration of the service itself.
These options are available only for the BOS v2 API and only affect v2 functionality.

* [View options](#view-options)
* [Update options](#update-options)
* [Individual option details](#individual-option-details)
    * [`bss_read_timeout`](#bss_read_timeout)
    * [`cfs_read_timeout`](#cfs_read_timeout)
    * [`cleanup_completed_session_ttl`](#cleanup_completed_session_ttl)
    * [`clear_stage`](#clear_stage)
    * [`component_actual_state_ttl`](#component_actual_state_ttl)
    * [`default_retry_policy`](#default_retry_policy)
    * [`disable_components_on_completion`](#disable_components_on_completion)
    * [`discovery_frequency`](#discovery_frequency)
    * [`hsm_read_timeout`](#hsm_read_timeout)
    * [`logging_level`](#logging_level)
    * [`max_boot_wait_time`](#max_boot_wait_time)
    * [`max_component_batch_size`](#max_component_batch_size)
    * [`max_power_off_wait_time`](#max_power_off_wait_time)
    * [`max_power_on_wait_time`](#max_power_on_wait_time)
    * [`pcs_read_timeout`](#pcs_read_timeout)
    * [`polling_frequency`](#polling_frequency)
    * [`session_limit_required`](#session_limit_required)

## View options

(`ncn-mw#`) View the current option values with the following command:

```bash
cray bos v2 options list --format json
```

Example output:

```json
{
  "bss_read_timeout": 20,
  "cfs_read_timeout": 20,
  "cleanup_completed_session_ttl": "7d",
  "clear_stage": false,
  "component_actual_state_ttl": "4h",
  "default_retry_policy": 3,
  "disable_components_on_completion": true,
  "discovery_frequency": 300,
  "hsm_read_timeout": 20,
  "logging_level": "INFO",
  "max_boot_wait_time": 600,
  "max_component_batch_size": 1800,  
  "max_power_off_wait_time": 180,
  "max_power_on_wait_time": 30,
  "pcs_read_timeout": 20,
  "polling_frequency": 60,
  "session_limit_required": false
}
```

> Not all options shown above are available in every patch version of CSM 1.5.
> For any such options, their entry in the [Individual option details](#individual-option-details)
> section indicates the earliest patch version of CSM 1.5 in which they are available.

## Update options

(`ncn-mw#`) The values for all BOS global options can be modified with the `cray bos v2 options update` command.
For example:

```bash
cray bos v2 options update --polling-frequency 12 --format json
```

Example output:

```json
{
  "bss_read_timeout": 20,
  "cfs_read_timeout": 20,
  "cleanup_completed_session_ttl": "7d",
  "clear_stage": false,
  "component_actual_state_ttl": "4h",
  "default_retry_policy": 3,
  "disable_components_on_completion": true,
  "discovery_frequency": 300,
  "hsm_read_timeout": 20,
  "logging_level": "INFO",
  "max_boot_wait_time": 600,
  "max_component_batch_size": 1800,  
  "max_power_off_wait_time": 180,
  "max_power_on_wait_time": 30,
  "pcs_read_timeout": 20,
  "polling_frequency": 12,
  "session_limit_required": false
}
```

## Individual option details

### `bss_read_timeout`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

The amount of time in seconds that BOS will wait for API responses from the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss).
After this time, the request will time out. The default is 20 seconds.

### `cfs_read_timeout`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

The amount of time in seconds that BOS will wait for API responses from the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs).
After this time, the request will time out. The default is 20 seconds.

### `cleanup_completed_session_ttl`

The amount of time that a completed [BOS session](Sessions.md) can exist without being
cleaned up by the [`session-cleanup` operator](Operators.md#session-cleanup).

The value can either be `0` or else be a non-negative integer following by a character indicating the
units: minutes (`m`or `M`), hours (`h` or `H`), days (`d` or `D`), or weeks (`w` or `W`).
For example, `3d` means three days.

The cleanup behavior is disabled if the option is set to `0`, `0m`, `0h`, `0d`, or `0w`.

### `clear_stage`

Allows staged information for [BOS components](Components.md) to be cleared when the requested staging action has been started. Defaults to false.

For more information on staging, see [Stage Changes with BOS](Stage_Changes_with_BOS.md).

### `component_actual_state_ttl`

This option defines two things:

* The amount of time that a component's `actual_state` is considered valid; if the actual state was last
  updated longer ago than this time, then the [`actual-state-cleanup` operator](Operators.md#actual-state-cleanup)
  will clear the actual state of the component.
* 4/3 (133%) of the amount of time that the [BOS reporter](Reporter.md) waits between sending state updates to BOS.
    * The BOS reporter does not read the BOS options during its execution, so changes to this
      option will not be reflected in the behavior of the BOS reporter on booted nodes.
    * For more details, see [Reporting interval](Reporter.md#reporting-interval).

The value can either be `0` or else be a non-negative integer following by a character indicating the
units: minutes (`m`or `M`), hours (`h` or `H`), days (`d` or `D`), or weeks (`w` or `W`).
For example, `3d` means three days.

> **WARNING**:
> Unlike [`cleanup_completed_session_ttl`](#cleanup_completed_session_ttl), a zero value for this
> option will **not** disable the cleanup behavior; instead it will result in undesirable behavior. Specifically,
> component actual states will be cleared every time the `actual-state-cleanup` operator runs, and the
> BOS reporter will have no pauses between reporting the component status to BOS. This will effectively
> render BOS unable to properly manage the nodes.
>
> To avoid problems, **never set this option to a value less than 1 hour**.

### `default_retry_policy`

The default maximum number of attempts per node for failed actions.

### `disable_components_on_completion`

> This is an experimental feature and is not fully supported.
> This option is [removed in CSM 1.7](../../introduction/deprecated_features/README.md#removed-in-csm-17).

Determines if a component will be marked as disabled after its desired state matches its current state.
If false, BOS will continue to maintain the state of the nodes declaratively.

### `discovery_frequency`

The frequency with which BOS checks the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for new components and adds them to the BOS component database.

### `hsm_read_timeout`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

The amount of time in seconds that BOS will wait for API responses from HSM.
After this time, the request will time out. The default is 10 seconds.

### `logging_level`

The logging level for the [BOS API](API.md) server and the [BOS Operators](Operators.md).
Valid values for this option are `DEBUG`, `INFO`, and `WARN`.

### `max_boot_wait_time`

How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds).

### `max_component_batch_size`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

The maximum number of components that BOS will group together in a single API request it makes. This can be used to limit the load
on other services by forcing BOS to break up its requests into smaller chunks.

### `max_power_off_wait_time`

How long BOS will wait for a node to power off before forcefully powering it off (in seconds).

### `max_power_on_wait_time`

How long BOS will wait for a node to power on before calling power on again (in seconds).

### `pcs_read_timeout`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

The amount of time in seconds that BOS will wait for API responses from the
[Power Control Service (PCS)](../../glossary.md#power-control-service-pcs).
After this time, the request will time out. The default is 10 seconds.

### `polling_frequency`

How frequently the BOS operators check component state for needed actions (in seconds).

### `session_limit_required`

> This option is added in CSM 1.5.3; in earlier patch versions of CSM 1.5, it is only available as a hotfix.

If enabled, then BOS v2 sessions cannot be created without specifying a
[session limit](Limit_the_Scope_of_a_BOS_Session.md).

This can be helpful in avoiding accidental reboots of more components than intended.

If this option is enabled, it is still possible to effectively create a session with no limit
by specifying `*` as the limit parameter (if this is done on the command line, it must be
quoted it in order to prevent it from being interpreted by the shell).

This option does NOT have an effect on:

* BOS v2 sessions that were created prior to the option being enabled (even if they have not yet started)
* BOS v1 sessions
