# Differences Between the V2 and V3 CFS APIs

The v3 CFS API contains a number of differences and improvements over the previous v2 API.
For convenience all changes are listed here.

* The v3 API supports paging through records for components, sessions, and configurations.
  See [Paging CFS Records](Paging_CFS_Records.md) for more information.
* The v3 API uses `snake_case` rather than `camelCase` for all parameters in queries and responses.
  This brings the API in line with other CSM APIs.
* The response format has changed for queries listing components, sessions, or configurations.
  Responses are no longer a list of records, and instead contain a key for the record type which
  contains the list of records. (E.g. `{"components":[]}` for the components endpoint).
  Responses also include a `next` section that is used for paging through records.
  See [Paging CFS Records](Paging_CFS_Records.md) for more information.
* The v3 API supports the creation of [CFS Sources](CFS_Sources.md) which allows CFS to use
  configuration and inventory content from external repositories. See
  [Using sources in a configuration layer](CFS_Configurations.md#using-sources-in-a-configuration-layer).
* Component records no longer include the `state` list of applied playbooks by default.
  The `state` can requested with the `state_details` parameter.
* Some fields now have maximum sizes:
    * Configuration names are now limited to 60 characters.
    * Additional inventory URLs are limited to 240 characters.
    * Configuration layer names are limited to 45 characters.
* The v3 API has new global options:
  [Additional inventory source](CFS_Global_Options.md#additional-inventory-source),
  [Default page size](CFS_Global_Options.md#default-page-size),
  [Debug wait time](CFS_Global_Options.md#debug-wait-time), and
  [Include ARA links](CFS_Global_Options.md#include-ara-links).
  See [CFS Global Options](CFS_Global_Options.md) for more information.
* Session and component records now include a `logs` field with a link to the ARA UI with the
  appropriate filter for that session or component.
  For more information, see [Ansible Log Collection](Ansible_Log_Collection.md) and
  [Include ARA links](CFS_Global_Options.md#include-ara-links).
* The `default_playbook` option is now deprecated.
  It can still be read using the v3 API but can not be set using the v3 API.
  Any value set using the v2 API will still be usable by configurations, even v3 configurations,
  until the v2 API is removed.
* Sessions now support a `debug_on_failure` option that will cause sessions that fail during Ansible
  execution to remain up for a limited time so that users can `exec` into the
  [Ansible Execution Environment (AEE)](Ansible_Execution_Environments.md) container and debug
  the problem. See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.
* CFS v3 supports new debugging playbooks which are included by default.
  This can be accessed by specifying `debug_fail`, `debug_facts` or `debug_noop` as the
  configuration for a session if a configuration has not already been created with that name.
  See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.
