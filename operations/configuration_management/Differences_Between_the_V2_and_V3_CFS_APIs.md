# Differences Between the V2 and V3 CFS APIs

The v3 CFS API contains a number of differences and improvements over the previous v2 API.
For convenience all changes are listed here.

* [Parameter naming changed](#parameter-naming-changed)
* [Paginated responses](#paginated-responses)
* [Field length limits](#field-length-limits)
* [ARA links](#ara-links)
* [Component configuration state layers](#component-configuration-state-layers)
    * [Configuration state not listed by default](#configuration-state-not-listed by-default)
    * [Configuration layer status has dedicated field](#configuration-layer-status-has-dedicated-field)
* [Global options](#global-options)
    * [New global options](#new-global-options)
    * [Default playbook deprecated](#default-playbook-deprecated)
* [Session debugging](#session-debugging)
    * [Debug on failure](#debug-on-failure)
    * [Debugging playbooks](#debugging-playbooks)
* [CFS sources](#cfs-sources)

## Parameter naming changed

The v3 API uses `snake_case` rather than `camelCase` for all parameters in queries and responses.
This brings the API in line with other CSM APIs.

## Paginated responses

CFS v3 supports paging through records for [components](CFS_Components.md),
[configurations](CFS_Configurations.md), and
[sessions](CFS_Sessions.md).

The response format has changed for queries listing these records.
Responses are no longer a list of records, and instead contain a key for the record type which
contains the list of records. (E.g. `{"components":[]}` for the components endpoint).
Responses also include a `next` section that is used for paging through records.

See [Paging CFS Records](Paging_CFS_Records.md) for more information.

## Field length limits

Some fields now have maximum sizes:

* Configuration names are now limited to 60 characters.
* [Additional inventory](Adding_Additional_Inventory.md) URLs are limited to 240 characters.
* Configuration layer names are limited to 45 characters.

## ARA links

Session and component records now include a `logs` field with a link to the ARA UI with the
appropriate filter for that session or component.

For more information, see:

* [Ansible Log Collection](Ansible_Log_Collection.md)
* [Include ARA links](CFS_Global_Options.md#include-ara-links)

## Component configuration state layers

### Configuration state not listed by default

Component records no longer include the `state` list of applied playbooks by default.
The `state` can requested with the `state_details` parameter.

### Configuration layer status has dedicated field

In CFS v2, the configuration layer status is embedded as part of the `commit` field.
In CFS v3, this is no longer the case; there is a dedicated `status` field for each layer.

## Global options

[CFS Global Options](CFS_Global_Options.md) control various aspects of CFS.
CFS v3 includes some changes to these options.

### New global options

* [Additional inventory source](CFS_Global_Options.md#additional-inventory-source)
* [Default page size](CFS_Global_Options.md#default-page-size)
* [Debug wait time](CFS_Global_Options.md#debug-wait-time)
* [Include ARA links](CFS_Global_Options.md#include-ara-links)

### Default playbook deprecated

The [Default playbook](CFS_Global_Options.md#default-playbook) option is now deprecated.
It can still be read using the v3 API but can not be set using the v3 API.
Any value set using the v2 API will still be usable by configurations, even v3 configurations,
until the v2 API is removed.

## Session debugging

### Debug on failure

Sessions now support a `debug_on_failure` option that will cause sessions that fail during Ansible
execution to remain up for a limited time so that users can `exec` into the
[Ansible Execution Environment (AEE)](Ansible_Execution_Environments.md) container and debug
the problem.

See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.

### Debugging playbooks

CFS v3 supports new debugging playbooks which are included by default.
This can be accessed by specifying `debug_fail`, `debug_facts` or `debug_noop` as the
configuration for a session if a configuration has not already been created with that name.

See [Troubleshoot CFS Issues](Troubleshoot_CFS_Issues.md) for more information.

## CFS sources

The CFS v3 supports the creation of [CFS Sources](CFS_Sources.md).
Sources allow CFS to use configuration and inventory content from external repositories.

For more information, see:

* [CFS Sources](CFS_Sources.md)
* [Using sources in a configuration layer](CFS_Configurations.md#using-sources-in-a-configuration-layer)
* [Using sources in additional inventory](Adding_Additional_Inventory.md#using-sources-in-additional-inventory)
