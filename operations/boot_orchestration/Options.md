# BOS Options

> **`NOTE`** This section is for BOS V2 only.

The Boot Orchestration Service \(BOS\) provides a global service options endpoint for modifying the base configuration of the service itself.  These options are available only for the BOS v2 API and only affect v2 functionality.

## Viewing the current option values

View the options with the following command:

(`ncn-mw#`)

```bash
cray bos v2 options list --format json
```

Example output:

```json
{
  "cleanup_completed_session_ttl": "7d",
  "component_actual_state_ttl": "4h",
  "default_retry_policy": 3,
  "disable_components_on_completion": true,
  "discovery_frequency": 300,
  "logging_level": "INFO",
  "max_boot_wait_time": 600,
  "max_power_off_wait_time": 180,
  "max_power_on_wait_time": 30,
  "polling_frequency": 60
}
```

## Updating the option values

The values for all BOS global options can be modified with the `cray bos v2 options update` command.

## BOS options details

The following are the BOS global options:

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

* `logging_level`

    The logging level for all BOS services.  Valid values for this option are `DEBUG`, `INFO`, and `WARN`.

* `max_boot_wait_time`

    How long BOS will wait for a node to boot into a usable state before rebooting it again (in seconds).

* `max_power_off_wait_time`

    How long BOS will wait for a node to power off before forcefully powering it off (in seconds).

* `max_power_on_wait_time`

    How long BOS will wait for a node to power on before calling power on again (in seconds).

* `polling_frequency`

    How frequently the BOS operators check component state for needed actions (in seconds).
