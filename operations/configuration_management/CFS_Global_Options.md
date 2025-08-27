# CFS Global Options

The Configuration Framework Service \(CFS\) provides a global service options endpoint for modifying the base configuration of the service itself.

View the options with the following command:

```bash
cray cfs v3 options list --format json
```

Example output:

```json
{
  "additional_inventory_source": "",
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

In the [CFS API specification](../../api/cfs.md), these options are defined in the
[`V3Options`](../../api/cfs.md#schemav3options) and
[`V2Options`](../../api/cfs.md#schemav2options) schemas.

The values for all CFS global options can be modified with the `cray cfs options update` command.

The following are the CFS global options, their names in CFS v2 and v3, and their default values.

| *Option*                                | *v3 name*                      | *v2 name*                   | *Default*                   | *Type*  | *Units/format*                         |
| --------------------------------------- | ------------------------------ | --------------------------- | --------------------------- | ------- | -------------------------------------- |
| [Additional inventory source][add-src]  | `additional_inventory_source`  | -                           | `""`                        | string  | CFS source name                        |
| [Additional inventory URL][add-url]     | `additional_inventory_url`     | `additionalInventoryUrl`    | `""`                        | string  | Git clone URL                          |
| [Batch size][bat-siz]                   | `batch_size`                   | `batchSize`                 | `25`                        | integer | Components                             |
| [Batch window][bat-win]                 | `batch_window`                 | `batchWindow`               | `60`                        | integer | seconds                                |
| [Batcher check interval][bat-chk]       | `batcher_check_interval`       | `batcherCheckInterval`      | `10`                        | integer | seconds                                |
| [Batcher disable][bat-dis]              | `batcher_disable`              | `batcherDisable`            | `false`                     | boolean | -                                      |
| [Batcher maximum backoff][bat-bac]      | `batcher_max_backoff`          | `batcherMaxBackoff`         | `3600`                      | integer | seconds                                |
| [Batcher pending timeout][bat-pen]      | `batcher_pending_timeout`      | `batcherPendingTimeout`     | `300`                       | integer | seconds                                |
| [Debug wait time][dbg]                  | `debug_wait_time`              | -                           | `3600`                      | integer | seconds                                |
| [Default Ansible configuration][ancfg]  | `default_ansible_config`       | `defaultAnsibleConfig`      | `"cfs-default-ansible-cfg"` | string  | ConfigMap name in `services` namespace |
| [Default batcher retry policy][bat-ret] | `default_batcher_retry_policy` | `defaultBatcherRetryPolicy` | `3`                         | integer | Component configuration attempts       |
| [Default page size][pag-siz]            | `default_page_size`            | -                           | `1000`                      | integer | List entries                           |
| [Default playbook][pbook]               | `default_playbook`             | `defaultPlaybook`           | `"site.yml"`                | string  | Name of Ansible playbook               |
| [Hardware synchronization interval][hw] | `hardware_sync_interval`       | `hardwareSyncInterval`      | `10`                        | integer | seconds                                |
| [Include ARA links][ara-lnk]            | `include_ara_links`            | -                           | `true`                      | boolean | -                                      |
| [Logging level][log-lvl]                | `logging_level`                | `loggingLevel`              | `"INFO"`                    | string  | Python logging level                   |
| [Session Time-To-Live (TTL)][ses-ttl]   | `session_ttl`                  | `sessionTTL`                | `"7d"`                      | string  | Length of time or empty string         |

## Additional inventory source

> **`NOTE`** This option is only available in the v3 CFS API.

The name of a CFS source to supply additional inventory content to all CFS sessions.

* v3 name: `additional_inventory_source`
* Default: `""` (empty string)

For more information, see [CFS Sources](CFS_Sources.md).

## Additional inventory URL

A Git clone URL to supply additional inventory content to all CFS sessions.

* v3 name: `additional_inventory_url`
* v2 name: `additionalInventoryUrl`
* Default: `""` (empty string)

See [Adding Additional Inventory](Adding_Additional_Inventory.md) for more information.

## Batch size

This option determines the maximum number of components that will be included in each session created by CFS Batcher.

* v3 name: `batch_size`
* v2 name: `batchSize`
* Default: `25` components per session

> **WARNING:** Increasing this value will result in fewer batcher-created sessions, but will also require more resources for
> [Ansible Execution Environment (AEE)](Ansible_Execution_Environments.md) containers to do the configuration.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Batch window

This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components
needing configuration has not reached the [batch size][bat-siz] limit.

* v3 name: `batch_window`
* v2 name: `batchWindow`
* Default: `60` seconds

The batch window time-boxes the creation of sessions so no component needs to wait for the queue to fill.
  
> **WARNING:** Lower values will cause CFS batcher to be more responsive to creating sessions, but values too low may result in
> degraded performance of both the CFS APIs as well as the overall system.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Batcher check interval

This option sets how often CFS batcher checks for components waiting to be configured.

* v3 name: `batcher_check_interval`
* v2 name: `batcherCheckInterval`
* Default: `10` seconds

This value must be lower than the [batch window][bat-win].

It is not recommended to increase this value during maintenance periods, in order to avoid CFS sessions being scheduled. In that
situation, use the [batcher disable][bat-dis] option.

> **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in
> degraded performance of the CFS APIs on larger systems.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Batcher disable

This option specifies whether the CFS batcher service is enabled or disabled.

* v3 name: `batcher_disable`
* v2 name: `batcherDisable`
* Default: `false`

If set to `true`, CFS batcher will still monitor existing sessions, but will not create new sessions or monitor the desired state of components.
When doing maintenance, disabling batcher is preferred over setting a high [batcher check interval][bat-chk].
This is because the CFS batcher does not check the CFS options while it waits for the check interval to elapse,
meaning that after the maintenance is complete, reducing the check interval may take some time in order to take effect, and
the only alternative to force it to happen sooner is to restart the batcher service. Alternatively, even while batcher is disabled,
it still monitors the CFS options, and will resume its activities when it sees that the disable flag is set to `false`.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Batcher maximum backoff

This option specifies the maximum number of seconds that the CFS batcher's back-off will reach.

* v3 name: `batcher_max_backoff`
* v2 name: `batcherMaxBackoff`
* Default: `3600` seconds

When all sessions are failing, CFS batcher will reduce the frequency with which sessions are created.
This back-off time will continue to increase up to this cap, and will reset to 0 when a new session is successful.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Batcher pending timeout

This option specifies the maximum number of seconds that CFS batcher will wait for a new session to enter a running state before deleting the session and trying again.

* v3 name: `batcher_pending_timeout`
* v2 name: `batcherPendingTimeout`
* Default: `300` seconds

This retry helps manage rare communication errors that can cause sessions to be stuck in a pending state.

See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Debug wait time

> **`NOTE`** This option is only available in the v3 CFS API.

Any sessions that have failed while using the `debug_on_failure` option will wait for this many seconds before automatically terminating if the the completion flag
is not touched.

* v3 name: `debug_wait_time`
* Default: `3600` seconds

## Default Ansible configuration

The name of the Kubernetes ConfigMap in the `services` namespace that contains the
Ansible configuration to use for CFS sessions when none is explicitly specified.

* v3 name: `default_ansible_config`
* v2 name: `defaultAnsibleConfig`
* Default: `"cfs-default-ansible-cfg"`

See [Configure Ansible](Configure_Ansible.md) for more information.

## Default batcher retry policy

The default batcher retry policy is the maximum number of failed configuration attempts allowed per component before CFS batcher will stop attempting to configure the component.

* v3 name: `default_batcher_retry_policy`
* v2 name: `defaultBatcherRetryPolicy`
* Default: `3` attempts to configure a component

This value can be overridden on a per component basis.

See [CFS Components](CFS_Components.md) for more information on per-component retry policies.
See [Automatic Configuration Management](Automatic_Configuration_Management.md) for more information on CFS batcher.

## Default page size

> **`NOTE`** This option is only available in the v3 CFS API.

When list listing component, session, or configuration records, CFS will by default return a maximum of this many records.

* v3 name: `default_page_size`
* Default: `1000` entries in the list

If the `limit` parameter is not specified in the call, then the default page size is what will be used for the maximum number of records returned in one call.
See [Paging CFS Records](Paging_CFS_Records.md) for more information on paging.

This parameter has a secondary purpose in the v2 API.
Calls that exceed this number of records will instead return an error stating that the response is too large.
In this case users should switch to the v3 API to take advantage of paging.
This number can be increased through the v3 API to allow more records to be returned through the v2 API, but this risks causing calls to fail due to memory constraints.

On CSM 1.5.0 systems, also see [CFS V2 Failures On Large Systems](../../troubleshooting/known_issues/CFS_V2_Failures_On_Large_Systems.md).

## Default playbook

> **WARNING:** This option is deprecated and read-only in the v3 CFS API. It can only be modified using CFS v2.

This value is used when no playbook is specified in a configuration layer.

* v3 name: `default_playbook`
* v2 name: `defaultPlaybook`
* Default: `"site.yml"`

For more information on configuration layers, see [CFS Configurations](CFS_Configurations.md).

## Hardware synchronization interval

The number of seconds between checks to the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for new hardware additions to the system.

* v3 name: `hardware_sync_interval`
* v2 name: `hardwareSyncInterval`
* Default: `10` seconds

When new hardware is registered with HSM, CFS will add it as a component.

For more information on configuration management of system components, see [CFS Components](CFS_Components.md).

## Include ARA links

> **NOTE:** This option is only available in the v3 CFS API.

Specifies whether ARA Records Ansible (ARA) links are included when querying CFS for sessions or components using CFS v3.

* v3 name: `include_ara_links`
* Default: `true`

The included links are to the ARA UI with filters for the specific session or component.
See [Ansible Log Collection](Ansible_Log_Collection.md) for more information.

## Logging level

> Do not confuse this with the Ansible verbosity level. For details on how to change that, see [Change the Ansible Verbosity](Change_the_Ansible_Verbosity.md).

The logging level for all CFS services.

* v3 name: `logging_level`
* v2 name: `loggingLevel`
* Default: `"INFO"`
* Valid values: `"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR"`

This aids debugging by allowing the logging level to be changed dynamically at any time.

## Session Time-To-Live (TTL)

The time-to-live for completed CFS sessions.

* v3 name: `session_ttl`
* v2 name: `"sessionTTL"`
* Default: `"7d"`

Running sessions will not be deleted.
Specified in minutes (e.g. `"45m"`), hours (e.g. `"9h"`), days (e.g. `"17d"`), or weeks (e.g. `"57w"`).
Set to an empty string to disable.

For more information, see [Automatic Session Deletion with `session_ttl`](Automatic_Session_Deletion_with_session_ttl.md).

<!--- Define the reference-style Markdown links used to reduce the size of the options table. -->

[add-src]: #additional-inventory-source
[add-url]: #additional-inventory-url
[bat-siz]: #batch-size
[bat-win]: #batch-window
[bat-chk]: #batcher-check-interval
[bat-dis]: #batcher-disable
[bat-bac]: #batcher-maximum-backoff
[bat-pen]: #batcher-pending-timeout
[dbg]: #debug-wait-time
[ancfg]: #default-ansible-configuration
[bat-ret]: #default-batcher-retry-policy
[pag-siz]: #default-page-size
[pbook]: #default-playbook
[hw]: #hardware-synchronization-interval
[ara-lnk]: #include-ara-links
[log-lvl]: #logging-level
[ses-ttl]: #session-time-to-live-ttl
