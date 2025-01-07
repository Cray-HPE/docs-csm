# BOS Options

> **`NOTE`** This section is for Boot Orchestration Service \(BOS\) v2 only.

BOS provides a global service options endpoint for modifying the base configuration of the service itself. These options are available only for the BOS v2 API and only affect v2 functionality.

* [Viewing the current option values](#viewing-the-current-option-values)
* [Updating the option values](#updating-the-option-values)
* [BOS options details](#bos-options-details)

## Viewing the current option values

View the options with the following command:

(`ncn-mw#`)

```bash
cray bos v2 options list --format json
```

Example output:

```json
{
  "bss_read_timeout": 20,
  "cfs_read_timeout": 20,
  "cleanup_completed_session_ttl": "7d",
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

## Updating the option values

The values for all BOS global options can be modified with the `cray bos v2 options update` command.

## BOS options details

The following are the BOS global options:

* `bss_read_timeout`

    The amount of time in seconds BOS will wait for a response from BSS to a request. After this time, the request will
    time out. The default is 20 seconds.
    Note: This option is only available as a 'hotfix' in CSM 1.5.

* `cfs_read_timeout`

    The amount of time in seconds BOS will wait for a response from CFS to a request. After this time, the request will
    time out. The default is 20 seconds.
    Note: This option is only available as a 'hotfix' in CSM 1.5.

* `cleanup_completed_session_ttl`

    Delete complete sessions that are older than `cleanup_completed_session_ttl` (in hours). `0h` disables cleanup behavior.

* `clear_stage`

    Allows components staged information to be cleared when the requested staging action has been started. Defaults to false.

* `component_actual_state_ttl`

    The maximum amount of time a component's `actual_state` is considered valid (in hours).
    `0h` disables cleanup behavior for newly booted nodes and instructs `bos-state-reporter` to report once instead of periodically.
    BOS relies on a reporter built into the boot image to determine the actual state.
    If a node boots with a boot image that does not contain a reporter, the node's `actual_state` will not be updated and will be incorrect.
    When the maximum amount of time has been exceeded, BOS clears the `actual_state` so as to trigger a reboot back into the desired image.

* `default_retry_policy`

    The default maximum number of attempts per node for failed actions.

* `disable_components_on_completion`

    Determines if a component will be marked as disabled after its desired state matches its current state.
    If false, BOS will continue to maintain the state of the nodes declaratively.
    This is an experimental feature and is not fully supported.

* `discovery_frequency`

    The frequency with which BOS checks HSM for new components and adds them to the BOS component database.

* `hsm_read_timeout`

    The amount of time in seconds BOS will wait for a response from HSM to a request. After this time, the request will
    time out. The default is 20 seconds.
    Note: This option is only available as a 'hotfix' in CSM 1.5.

* `logging_level`

    The logging level for all BOS services. Valid values for this option are `DEBUG`, `INFO`, and `WARN`.

* `max_boot_wait_time`

    How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds).

* `max_component_batch_size`

    The maximum number of components that BOS will group together in a single API request it makes. This can be used to limit the load
    on other services by forcing BOS to break up its requests into smaller chunks.
    Note: This option is only available as a 'hotfix' in CSM 1.5.

* `max_power_off_wait_time`

    How long BOS will wait for a node to power off before forcefully powering it off (in seconds).

* `max_power_on_wait_time`

    How long BOS will wait for a node to power on before calling power on again (in seconds).

* `pcs_read_timeout`

    The amount of time in seconds BOS will wait for a response from PCS to a request. After this time, the request will
    time out. The default is 20 seconds.
    Note: This option is only available as a 'hotfix' in CSM 1.5.

* `polling_frequency`

    How frequently the BOS operators check component state for needed actions (in seconds).

* `session_limit_required`

    If enabled, BOS sessions cannot be created without specifying the `limit` parameter.
    This can be helpful in avoiding accidental reboots of more components than intended.
    If this option is enabled, it is still possible to effectively create a session with no limit
    by specifying `*` as the limit parameter (if this is done on the command line, it must be
    quoted it in order to prevent it from being interpreted by the shell).
    Note: This option is only available as a 'hotfix' in CSM 1.5.
