# CFS Global Options

The Configuration Framework Service \(CFS\) provides a global service options endpoint for modifying the base configuration of the service itself.

View the options with the following command:

```bash
ncn# cray cfs options list --format json
```

Example output:

```json
{
  "additionalInventoryUrl": "",
  "batchSize": 25,
  "batchWindow": 60,
  "batcherCheckInterval": 10,
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "defaultBatcherRetryPolicy": 1,
  "defaultPlaybook": "site.yml",
  "hardwareSyncInterval": 10,
  "sessionTTL": "7d"
}
```

The following are the CFS global options:

* **additionalInventoryUrl**

  A Git clone URL to supply additional inventory content to all CFS sessions.

  See [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md) for more information.

* **batchSize**

  This option determines the maximum number of components that will be included in each session created by CFS Batcher.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **batchWindow**

  This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components needing configuration has not reached the `batchSize` limit.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **batcherCheckInterval**

  This option sets how often CFS batcher checks for components waiting to be configured. This value must be lower than batchWindow.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **defaultBatcherRetryPolicy**

  When a component \(node\) requiring configuration fails to configure from a previous configuration session launched by CFS Batcher, the error is logged. defaultBatcherRetryPolicy is the maximum number of failed configurations allowed per component before CFS Batcher will stop attempts to configure the component.

  See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

* **defaultAnsibleConfig**

  See [Set the ansible.cfg for a Session](Set_the_ansible-cfg_for_a_Session.md) for more information.

* **defaultPlaybook**

  Use this value when no playbook is specified in a configuration layer.

* **hardwareSyncInterval**

  The number of seconds between checks to the Hardware State Manager \(HSM\) for new hardware additions to the system. When new hardware is registered with HSM, CFS will add it as a component.

  See [Configuration Management of System Components](Configuration_Management_of_System_Components.md) for more information.

The default values for all CFS global options can be modified with the `cray cfs options update` command.

