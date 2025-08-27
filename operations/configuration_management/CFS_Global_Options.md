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
  "batcherMaxBackoff": 3600,
  "defaultAnsibleConfig": "cfs-default-ansible-cfg",
  "defaultBatcherRetryPolicy": 1,
  "defaultCloneUrl": "https://api-gw-service-nmn.local/vcs/cray/config-management.git",
  "defaultPlaybook": "site.yml",
  "hardwareSyncInterval": 10,
  "sessionTTL": "7d"
}
```

The values for all CFS global options can be modified with the `cray cfs options update` command.

The following are the CFS global options, their names in CFS, and their default values.

| *Option*                                | *CFS name*                  | *Default*                   | *Type*  | *Units/format*                         |
| --------------------------------------- | --------------------------- | --------------------------- | ------- | -------------------------------------- |
| [Additional inventory URL][add-url]     | `additionalInventoryUrl`    | `""`                        | string  | Git clone URL                          |
| [Batch size][bat-siz]                   | `batchSize`                 | `25`                        | integer | Components                             |
| [Batch window][bat-win]                 | `batchWindow`               | `60`                        | integer | seconds                                |
| [Batcher check interval][bat-chk]       | `batcherCheckInterval`      | `10`                        | integer | seconds                                |
| [Batcher maximum backoff][bat-bac]      | `batcherMaxBackoff`         | `3600`                      | integer | seconds                                |
| [Default Ansible configuration][ancfg]  | `defaultAnsibleConfig`      | `"cfs-default-ansible-cfg"` | string  | ConfigMap name in `services` namespace |
| [Default batcher retry policy][bat-ret] | `defaultBatcherRetryPolicy` | `3`                         | integer | Component configuration attempts       |
| [Default clone URL][clo-url]        | `defaultCloneUrl` | `"https://api-gw-service-nmn.local/vcs/cray/config-management.git"` | string | Git clone URL |
| [Default playbook][pbook]               | `defaultPlaybook`           | `"site.yml"`                | string  | Name of Ansible playbook               |
| [Hardware synchronization interval][hw] | `hardwareSyncInterval`      | `10`                        | integer | seconds                                |
| [Session Time-To-Live (TTL)][ses-ttl]   | `sessionTTL`                | `"7d"`                      | string  | Length of time or empty string         |

## Additional inventory URL

A Git clone URL to supply additional inventory content to all CFS sessions.

* Name: `additionalInventoryUrl`
* Default: `""` (empty string)

See [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md) for more information.

## Batch size

This option determines the maximum number of components that will be included in each session created by CFS Batcher.

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

> **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in
> degraded performance of the CFS APIs on larger systems.

See [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md) for more information.

## Batcher maximum backoff

This option specifies the maximum number of seconds that the CFS batcher's back-off will reach.

* Name: `batcherMaxBackoff`
* Default: `3600` seconds

When all sessions are failing, CFS batcher will reduce the frequency with which sessions are created.
This back-off time will continue to increase up to this cap, and will reset to 0 when a new session is successful.

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

## Default clone URL

**NOTE**: This option is deprecated and has no effect. It is removed in CSM 1.2.

* Name: `defaultCloneUrl`
* Default: `"https://api-gw-service-nmn.local/vcs/cray/config-management.git"`

## Default playbook

This value is used when no playbook is specified in a configuration layer.

* Name: `defaultPlaybook`
* Default: `"site.yml"`

For more information on configuration layers, see [Configuration Layers](Configuration_Layers.md).

## Hardware synchronization interval

The number of seconds between checks to the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for new hardware additions to the system.

* Name: `hardwareSyncInterval`
* Default: `10` seconds

When new hardware is registered with HSM, CFS will add it as a component.

See [Configuration Management of System Components](Configuration_Management_of_System_Components.md) for more information.

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
[bat-bac]: #batcher-maximum-backoff
[ancfg]: #default-ansible-configuration
[bat-ret]: #default-batcher-retry-policy
[clo-url]: #default-clone-url
[pbook]: #default-playbook
[hw]: #hardware-synchronization-interval
[ses-ttl]: #session-time-to-live-ttl
