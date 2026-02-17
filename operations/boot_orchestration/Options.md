# BOS Options

BOS provides a global service options endpoint for modifying the base configuration of the service itself.

* [View options](#view-options)
* [Update options](#update-options)
* [Individual option details](#individual-option-details)
    * [`bss_read_timeout`](#bss_read_timeout)
    * [`cfs_read_timeout`](#cfs_read_timeout)
    * [`cleanup_completed_session_ttl`](#cleanup_completed_session_ttl)
    * [`clear_stage`](#clear_stage)
    * [`component_actual_state_ttl`](#component_actual_state_ttl)
    * [`default_retry_policy`](#default_retry_policy)
    * [`discovery_frequency`](#discovery_frequency)
    * [`hsm_read_timeout`](#hsm_read_timeout)
    * [`ims_errors_fatal`](#ims_errors_fatal)
    * [`ims_images_must_exist`](#ims_images_must_exist)
    * [`ims_read_timeout`](#ims_read_timeout)
    * [`logging_level`](#logging_level)
    * [`max_boot_wait_time`](#max_boot_wait_time)
    * [`max_component_batch_size`](#max_component_batch_size)
    * [`max_power_off_wait_time`](#max_power_off_wait_time)
    * [`max_power_on_wait_time`](#max_power_on_wait_time)
    * [`pcs_read_timeout`](#pcs_read_timeout)
    * [`polling_frequency`](#polling_frequency)
    * [`reject_nids`](#reject_nids)
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
  "discovery_frequency": 300,
  "hsm_read_timeout": 20,
  "ims_errors_fatal": false,
  "ims_images_must_exist": false,
  "ims_read_timeout": 20,
  "logging_level": "DEBUG",
  "max_boot_wait_time": 1200,
  "max_component_batch_size": 1800,
  "max_power_off_wait_time": 300,
  "max_power_on_wait_time": 120,
  "pcs_read_timeout": 20,
  "polling_frequency": 15,
  "reject_nids": false,
  "session_limit_required": false
}
```

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
  "discovery_frequency": 300,
  "hsm_read_timeout": 20,
  "ims_errors_fatal": false,
  "ims_images_must_exist": false,
  "ims_read_timeout": 20,
  "logging_level": "DEBUG",
  "max_boot_wait_time": 1200,
  "max_component_batch_size": 1800,
  "max_power_off_wait_time": 300,
  "max_power_on_wait_time": 120,
  "pcs_read_timeout": 20,
  "polling_frequency": 12,
  "reject_nids": false,
  "session_limit_required": false
}
```

## Individual option details

### `bss_read_timeout`

The amount of time in seconds that BOS will wait for API responses from the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss).
After this time, the request will time out. The default is 20 seconds.

### `cfs_read_timeout`

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

### `discovery_frequency`

The frequency with which BOS checks the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for new components and adds them to the BOS component database.

### `hsm_read_timeout`

The amount of time in seconds that BOS will wait for API responses from HSM.
After this time, the request will time out. The default is 20 seconds.

### `ims_errors_fatal`

This option modifies how BOS behaves when validating the architecture of a boot image
during [boot set validation](Session_Templates.md#boot-set-validation).
Specifically, this option comes into play when BOS needs data from the
[Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
in order to do this validation, but IMS is unreachable.

In the above situation, if this option is true, then the validation will fail.
Otherwise, if the option is false, then a warning will be logged, but the validation will not
be failed because of this.

### `ims_images_must_exist`

This option modifies how BOS behaves when performing [boot set validation](Session_Templates.md#boot-set-validation)
on a [boot set](Session_Templates.md#boot-sets) whose boot image appears to be from IMS.
Specifically, this option comes into play when the image does not actually exist in IMS.

In the above situation, if this option is true, then the validation will fail.
Otherwise, if the option is false, then a warning will be logged, but the validation will not
be failed because of this.

Note: If `ims_images_must_exist` is true but `ims_errors_fatal` is false, then
a failure to determine whether or not an image is in IMS will NOT result in a fatal error.

### `ims_read_timeout`

The amount of time in seconds that BOS will wait for API responses from IMS.
After this time, the request will time out. The default is 20 seconds.

### `logging_level`

The logging level for the [BOS API](API.md) server and the [BOS Operators](Operators.md).
Valid values for this option are `DEBUG`, `INFO`, and `WARN`.

### `max_boot_wait_time`

How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds).

### `max_component_batch_size`

The maximum number of components that BOS will group together in a single API request it makes. This can be used to limit the load
on other services by forcing BOS to break up its requests into smaller chunks.

### `max_power_off_wait_time`

How long BOS will wait for a node to power off before forcefully powering it off (in seconds).

### `max_power_on_wait_time`

How long BOS will wait for a node to power on before calling power on again (in seconds).

### `pcs_read_timeout`

The amount of time in seconds that BOS will wait for API responses from the
[Power Control Service (PCS)](../../glossary.md#power-control-service-pcs).
After this time, the request will time out. The default is 20 seconds.

### `polling_frequency`

How frequently the BOS operators check component state for needed actions (in seconds).

### `reject_nids`

Regardless of the value of this option,
BOS does not support the use of [NIDs](../../glossary.md#node-id-nid) to identify nodes -- only
component names ([xnames](../../glossary.md#xname)).
If the `reject_nids` option is enabled, then BOS will prevent creation of [sessions](Sessions.md) and
[session templates](Session_Templates.md) that appear to reference NIDs.
Specifically, if this option is enabled, then:

* During [boot set validation](Session_Templates.md#boot-set-validation), if a
  [boot set](Session_Templates.md#boot-sets) has
  a [`node_list`](Session_Templates.md#node-list) that appears to contain a NID, then the validation will fail.
* When creating a session, if the [session limit](Limit_the_Scope_of_a_BOS_Session.md) appears to contain NID
  values, then the creation will fail.

This option does NOT have an effect on sessions that were created prior to it being enabled (even if they have not yet started).

### `session_limit_required`

If enabled, then BOS sessions cannot be created without specifying a
[session limit](Limit_the_Scope_of_a_BOS_Session.md).
This can be helpful in avoiding accidental reboots of more components than intended.

If this option is enabled, it is still possible to effectively create a session with no limit
by specifying `*` as the limit parameter (if this is done on the command line, it must be
quoted it in order to prevent it from being interpreted by the shell).

This option does NOT have an effect on sessions that were created prior to it being enabled (even if they have not yet started).
