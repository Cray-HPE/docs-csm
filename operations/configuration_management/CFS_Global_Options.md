# CFS Global Options

The Configuration Framework Service \(CFS\) provides a global service options endpoint for modifying the base configuration of the service itself.

View the options with the following command:

```bash
cray cfs v3 options list --format json
```

Example output:

```json
{
  "additional_inventory_url": "",
  "batch_size": 25,
  "batch_window": 60,
  "batcher_check_interval": 10,
  "batcher_disable": false,
  "batcher_max_backoff": 3600,
  "batcher_pending_timeout": 300,
  "debug_wait_time": 3600,
  "default_ansible_config": "cfs-default-ansible-cfg",
  "default_batcher_retry_policy": 3,
  "default_page_size": 1000,
  "default_playbook": "site.yml",
  "hardware_sync_interval": 10,
  "include_ara_links": true,
  "logging_level": "INFO",
  "session_ttl": "7d"
}
```

The default values for all CFS global options can be modified with the `cray cfs options update` command.

The following are the CFS global options:

* **`additional_inventory_url`**

  A Git clone URL to supply additional inventory content to all CFS sessions.

  See [Adding Additional Inventory](Adding_Additional_Inventory.md) for more information.

* **`batch_size`**

  This option determines the maximum number of components that will be included in each session created by CFS Batcher.

  The default value is 25 components per session.

  > **WARNING:** Increasing this value will result in fewer batcher-created sessions, but will also require more resources for
  > Ansible Execution Environment \(AEE\) containers to do the configuration.

  See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information.

* **`batch_window`**

  This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components needing configuration has not reached the `batch_size` limit.
  The `batch_window` time-boxes the creation of sessions so no component needs to wait for the queue to fill.

  The default value is 60 seconds.
  
  > **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in
  > degraded performance of both the CFS APIs as well as the overall system.

  See [Configuration Management with the CFS Batcher](Automatic_Configuration_Management.md) for more information.

* **`batcher_check_interval`**

  This option sets how often CFS batcher checks for components waiting to be configured. This value must be lower than `batch_window`.

  The default value is 10 seconds.

  > **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in
  > degraded performance of the CFS APIs on larger systems.

  See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information.

* **`batcher_disable`**

  This option allows the CFS batcher service to be disabled.
  If set to true, CFS batcher will still monitor existing sessions, but will not create new sessions or monitor the desired state of components.
  This is preferred over setting a high `batcher_check_interval` when doing maintenance because the CFS batcher continues to monitor the CFS options and will resume when this flag is unset, rather than requiring a restart to refresh the options.

* **`batcher_max_backoff`**

  This option specifies the maximum number of seconds that the CFS batcher's back-off will reach.
  When all sessions are failing, CFS batcher will reduce the frequency with which sessions are created.
  This back-off time will continue to increase up to this cap, and will reset to 0 when a new session is successful.

  See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information.

* **`batcher_pending_timeout`**

  This option specifies the maximum number of seconds that CFS batcher will wait for a new session to enter a running state before deleting the session and trying again.
  This retry helps manage rare communication errors that can cause sessions to be stuck in a pending state.

* **`debug_wait_time`**

  Any sessions that have failed while using the `debug_on_failure` option will wait for this many seconds before automatically terminating if the the completion flag
  is not touched.

* **`default_ansible_config`**

  See [Configure Ansible](Configure_Ansible.md) for more information.

* **`default_batcher_retry_policy`**

  When a component requiring configuration fails to configure, the error is logged.
  `default_batcher_retry_policy` is the maximum number of failed configurations allowed per component before CFS batcher will stop attempting to configure the component.
  This value can be overridden on a per component basis.

  See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information.

* **`default_page_size`**

  > **`NOTE`** This option is only available in the v3 CFS API.

  When list listing component, session or configuration records, CFS will only return a limited number of records.
  If the `limit` parameter is not specified in the call, the `default_page_size` is what will be used for the maximum number of records returned in one call.
  See [Paging CFS Records](Paging_CFS_Records.md) for more information on paging.

  This parameter has a secondary purpose in the v2 API.
  Calls that exceed this number of records will instead return an error stating that the response is too large.
  In this case users should switch to the v3 API to take advantage of paging.
  This number can be increased through the v3 API to allow more records to be returned through the v2 API, but this risks causing calls to fail due to memory constraints.

* **`default_playbook`**

  > **WARNING:** This option is deprecated and read-only in the v3 CFS API. It can only be modified using CFS v2.

  Use this value when no playbook is specified in a configuration layer.

* **`hardware_sync_interval`**

  The number of seconds between checks to the Hardware State Manager \(HSM\) for new hardware additions to the system. When new hardware is registered with HSM, CFS will add it as a component.

  For more information on configuration management of system components, see [CFS Components](CFS_Components.md).

* **`include_ara_links`**

  > **NOTE:** This option is only available in the v3 CFS API.

  Links to the ARA Records Ansible (ARA) UI with filters for specific sessions or components are returned when querying CFS for session or component records via the v3 API.
  This feature can be disabled with this option.
  See [Ansible Log Collection](Ansible_Log_Collection.md) for more information.

* **`logging_level`**

  The level that all CFS services will log at.
  This aids debugging by allowing the logging level to be changed dynamically at any time.

* **`session_ttl`**

  The time-to-live for completed CFS sessions.
  Running sessions will not be deleted.
  This can be specified as a number of days (e.g. `7d`) or hours (e.g. `12h`).
