# CFS Global Options

The Configuration Framework Service (CFS) provides a global service options endpoint for modifying the base configuration of the service itself.

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

In the [CFS API specification](../../api/cfs.md), these options are defined in the
[`V2Options`](../../api/cfs.md#schemav2options) schema.

The values for all CFS global options can be modified with the `cray cfs options update` command.

The following are the CFS global options, their names in CFS, and their default values.

| *Option*                                | *CFS name*                  | *Default*                   | *Type*  | *Units/format*                         |
| --------------------------------------- | --------------------------- | --------------------------- | ------- | -------------------------------------- |
| [Additional inventory URL][add-url]     | `additionalInventoryUrl`    | `""`                        | string  | Git clone URL                          |
| [Batch size][bat-siz]                   | `batchSize`                 | `25`                        | integer | Components                             |
| [Batch window][bat-win]                 | `batchWindow`               | `60`                        | integer | seconds                                |
| [Batcher check interval][bat-chk]       | `batcherCheckInterval`      | `10`                        | integer | seconds                                |
| [Batcher disable][bat-dis]              | `batcherDisable`            | `false`                     | boolean | -                                      |
| [Batcher maximum backoff][bat-bac]      | `batcherMaxBackoff`         | `3600`                      | integer | seconds                                |
| [Batcher pending timeout][bat-pen]      | `batcherPendingTimeout`     | `300`                       | integer | seconds                                |
| [Default Ansible configuration][ancfg]  | `defaultAnsibleConfig`      | `"cfs-default-ansible-cfg"` | string  | ConfigMap name in `services` namespace |
| [Default batcher retry policy][bat-ret] | `defaultBatcherRetryPolicy` | `3`                         | integer | Component configuration attempts       |
| [Default playbook][pbook]               | `defaultPlaybook`           | `"site.yml"`                | string  | Name of Ansible playbook               |
| [Hardware synchronization interval][hw] | `hardwareSyncInterval`      | `10`                        | integer | seconds                                |
| [Logging level][log-lvl]                | `loggingLevel`              | `"INFO"`                    | string  | Python logging level                   |
| [Session Time-To-Live (TTL)][ses-ttl]   | `sessionTTL`                | `"7d"`                      | string  | Length of time or empty string         |

## Additional inventory URL

A Git clone URL to supply additional inventory content to all CFS sessions.

* Name: `additionalInventoryUrl`
* Default: `""` (empty string)

See [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md) for more information.

## Batch size

This option determines the maximum number of components that will be included in each session created by the
[CFS Batcher](CFS_Batcher.md).

* Name: `batchSize`
* Default: `25` components per session

> **WARNING:** Increasing this value will result in fewer batcher-created sessions, but will also require more resources for
> [Ansible Execution Environment (AEE)](Ansible_Execution_Environments.md) containers to do the configuration.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batch window

This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components
needing configuration has not reached the [batch size][bat-siz] limit.

* Name: `batchWindow`
* Default: `60` seconds

The batch window time-boxes the creation of sessions so no component needs to wait for the queue to fill.

> **WARNING:** Lower values will cause CFS batcher to be more responsive to creating sessions, but values too low may result in
> degraded performance of both the CFS APIs as well as the overall system.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batcher check interval

This option sets how often CFS batcher checks for components waiting to be configured.

* Name: `batcherCheckInterval`
* Default: `10` seconds

This value must be lower than the [batch window][bat-win].

It is not recommended to increase this value during maintenance periods, in order to avoid CFS sessions being scheduled. In that
situation, use the [batcher disable][bat-dis] option.

> **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in
> degraded performance of the CFS APIs on larger systems.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batcher disable

This option specifies whether the CFS batcher service is enabled or disabled.

* Name: `batcherDisable`
* Default: `false`

If set to `true`, CFS batcher will still monitor existing sessions, but will not create new sessions or monitor the desired state of components.
When doing maintenance, disabling batcher is preferred over setting a high [batcher check interval][bat-chk].
This is because the CFS batcher does not check the CFS options while it waits for the check interval to elapse,
meaning that after the maintenance is complete, reducing the check interval may take some time in order to take effect, and
the only alternative to force it to happen sooner is to restart the batcher service. Alternatively, even while batcher is disabled,
it still monitors the CFS options, and will resume its activities when it sees that the disable flag is set to `false`.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batcher maximum backoff

This option specifies the maximum number of seconds that the CFS batcher's back-off will reach.

* Name: `batcherMaxBackoff`
* Default: `3600` seconds

When all sessions are failing, CFS batcher will reduce the frequency with which sessions are created.
This back-off time will continue to increase up to this cap, and will reset to 0 when a new session is successful.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batcher pending timeout

This option specifies the maximum number of seconds that CFS batcher will wait for a new session to enter a running state before deleting the session and trying again.

* Name: `batcherPendingTimeout`
* Default: `300` seconds

This retry helps manage rare communication errors that can cause sessions to be stuck in a pending state.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Default Ansible configuration

The name of the Kubernetes ConfigMap in the `services` namespace that contains the
Ansible configuration to use for CFS sessions when none is explicitly specified.

* Name: `defaultAnsibleConfig`
* Default: `"cfs-default-ansible-cfg"`

See [Set the `ansible.cfg` for a Session](Set_the_ansible-cfg_for_a_Session.md) for more information.

## Default batcher retry policy

The default batcher retry policy is the maximum number of failed configuration attempts allowed per component before CFS batcher will stop attempting to configure the component.

* Name: `defaultBatcherRetryPolicy`
* Default: `3` attempts to configure a component

This value can be overridden on a per component basis.

For more information, see:

* [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md)
* [Configuration Management of System Components](Configuration_Management_of_System_Components.md)

## Default playbook

This value is used when no playbook is specified in a configuration layer.

* Name: `defaultPlaybook`
* Default: `"site.yml"`

For more information on configuration layers, see [Configuration Layers](Configuration_Layers.md).

## Hardware synchronization interval

The number of seconds that the [CFS Hardware Synchronization Agent](CFS_Hardware_Synchronization_Agent.md)
waits between checks to the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for hardware additions to the system.

* Name: `hardwareSyncInterval`
* Default: `10` seconds

When new hardware is registered with HSM, the CFS Hardware Synchronization Agent will make an API call
to create corresponding CFS components.

See [Configuration Management of System Components](Configuration_Management_of_System_Components.md) for more information.

## Logging level

> Do not confuse this with the Ansible verbosity level. For details on how to change that, see [Change the Ansible Verbosity Logs](Change_the_Ansible_Verbosity_Logs.md).

The logging level for all CFS services.

* Name: `loggingLevel`
* Default: `"INFO"`
* Valid values: `"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR"`

This aids debugging by allowing the logging level to be changed dynamically at any time.

## Session Time-To-Live (TTL)

The time-to-live for completed CFS sessions.

* Name: `"sessionTTL"`
* Default: `"7d"`

Running sessions will not be deleted.
Specified in minutes (e.g. `"45m"`), hours (e.g. `"9h"`), days (e.g. `"17d"`), or weeks (e.g. `"57w"`).
Set to an empty string to disable.

For more information, see [Automatic Session Deletion with `sessionTTL`](Automatic_Session_Deletion_with_sessionTTL.md).

<!--- Define the reference-style Markdown links used to reduce the size of the options table. -->

[add-url]: #additional-inventory-url
[bat-siz]: #batch-size
[bat-win]: #batch-window
[bat-chk]: #batcher-check-interval
[bat-dis]: #batcher-disable
[bat-bac]: #batcher-maximum-backoff
[bat-pen]: #batcher-pending-timeout
[ancfg]: #default-ansible-configuration
[bat-ret]: #default-batcher-retry-policy
[pbook]: #default-playbook
[hw]: #hardware-synchronization-interval
[log-lvl]: #logging-level
[ses-ttl]: #session-time-to-live-ttl
