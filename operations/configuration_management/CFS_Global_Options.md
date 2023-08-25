# CFS Global Options

The Configuration Framework Service \(CFS\) provides a global service options endpoint for modifying the base configuration of the service itself.

View the options with the following command:

```bash
cray cfs options list --format json
```

Example output:

```json
{
  "additionalInventoryUrl": "",
  "batchSize": 25,
  "batchWindow": 60,
  "batcherCheckInterval": 10,
  "batcherDisable": false,
  "batcherMaxBackoff": 3600,
  "batcherPendingTimeout": 300,
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "defaultBatcherRetryPolicy": 3,
  "defaultPlaybook": "site.yml",
  "hardwareSyncInterval": 10,
  "loggingLevel": "INFO",
  "sessionTTL": "7d"
}
```

The following are the CFS global options:

* **`additionalInventoryUrl`**

  A Git clone URL to supply additional inventory content to all CFS sessions.

  See [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md) for more information.

* **`batchSize`**

  This option determines the maximum number of components that will be included in each session created by CFS Batcher.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **`batchWindow`**

  This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components needing configuration has not reached the `batchSize` limit.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **`batcherCheckInterval`**

  This option sets how often CFS batcher checks for components waiting to be configured. This value must be lower than `batchWindow`.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **`batcherDisable`**

  This option allows the CFS batcher service to be disabled.
  If set to true, CFS batcher will still monitor existing sessions, but will not create new sessions or monitor the desired state of components.
  This is preferred over setting a high `batcherCheckInterval` when doing maintenance because the CFS batcher continues to monitor the CFS options and will resume when this flag is unset, rather than requiring a restart to refresh the options.

* **`batcherMaxBackoff`**

  This option specifies the maximum number of seconds that the CFS batcher's back-off will reach.
  When all sessions are failing, CFS batcher will reduce the frequency with which sessions are created.
  This back-off time will continue to increase up to this cap, and will reset to 0 when a new session is successful.

* **`batcherPendingTimeout`**

  This option specifies the maximum number of seconds that CFS batcher will wait for a new session to enter a running state before deleting the session and trying again.
  This retry helps manage rare communication errors that can cause sessions to be stuck in a pending state.

* **`defaultAnsibleConfig`**

  See [Set the `ansible.cfg` for a Session](Set_the_ansible-cfg_for_a_Session.md) for more information.

* **`defaultBatcherRetryPolicy`**

  When a component \(node\) requiring configuration fails to configure from a previous configuration session launched by CFS batcher, the error is logged.
  `defaultBatcherRetryPolicy` is the maximum number of failed configurations allowed per component before CFS batcher will stop attempting to configure the component.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **`defaultPlaybook`**

  Use this value when no playbook is specified in a configuration layer.

* **`hardwareSyncInterval`**

  The number of seconds between checks to the Hardware State Manager \(HSM\) for new hardware additions to the system. When new hardware is registered with HSM, CFS will add it as a component.

  See [Configuration Management of System Components](Configuration_Management_of_System_Components.md) for more information.

The default values for all CFS global options can be modified with the `cray cfs options update` command.

* **`loggingLevel`**

  The level that all CFS services will log at.
  This can be changed dynamically to enable or disable debugging at any time.

* **`sessionTTL`**

  The time-to-live for completed CFS sessions.
  Running sessions will not be deleted.
  This can be specified as a number of days (e.g. `7d`) or hours (e.g. `12h`).
