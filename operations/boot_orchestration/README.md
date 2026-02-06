# Boot Orchestration Service (BOS)

* [Overview](#overview)
* [Terminology](#terminology)
* [Services](#services)
    * [API](#api)
    * [Database](#database)
    * [Operators](#operators)
    * [Reporter](#reporter)
    * [Boot Orchestration Agent (BOA)](#boot-orchestration-agent-boa)
* [CLI](#cli)
* [Versions](#versions)
    * [BOS v1](#bos-v1)
    * [BOS v2](#bos-v2)
* [Dependencies](#dependencies)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service (BOS) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions.

BOS users create a BOS session template, and then create a BOS session, which applies an action to the session template.
The available actions are boot, reboot, shutdown, and configure.
The session can be monitored to determine the status of the request.

> The configure action is only available in [BOS v1](#bos-v1) sessions.

For more information, see [BOS Workflows](BOS_Workflows.md).

## Terminology

* [Component](Components.md): A node (such as a [compute node](../../glossary.md#compute-node-cn) or [UAN](../../glossary.md#user-access-node-uan)).
    * Components are only used in BOS v2.
    * Although [management nodes](../../glossary.md#management-nodes) have corresponding BOS components, BOS should not be used on them.
* [Options](Options.md): Adjustable parameters to control how BOS operates.
    * These options were introduced in BOS v2.
    * The options can only be viewed or modified using BOS v2.
    * Most of the options only impact the behavior of BOS v2 and not BOS v1.
* [Session](Sessions.md): A request for BOS to perform an action on a specified set of components, bringing them to a specified desired state.
    * Sessions exist in both v1 and v2, but they are significantly different.
* [Session template](Session_Templates.md): A collection of metadata for a group of nodes and their desired boot artifacts and configuration.
    * The same set of session templates is used for both v1 and v2. In general, fields that are specific to one BOS version are ignored when
      the template is used for a session of the other BOS version.

## Services

BOS is made up of a number of different sub-services that combine to provide its functionality.

* [API](#api)
* [Database](#database)
* [Operators](#operators)
* [Reporter](#reporter)
* [Boot Orchestration Agent (BOA)](#boot-orchestration-agent-boa)

### API

The API is the point of contact for the user and all other services that want to query or update BOS data.
This includes other BOS sub-services, such as the [operators](#operators) and the [BOS reporter](#reporter).

For more information, see [BOS API](API.md).

### Database

Most BOS data is stored in a Redis database. Some BOS data is stored in an etcd database.

For more information, see [BOS Database](Database.md).

### Operators

> BOS operators are a feature of BOS v2 only.

BOS operators are always-running sub-services. They are each responsible for doing a single basic task,
such as powering on nodes, discovering new nodes on the system, or initializing a new session.

For more information, see [BOS Operators](Operators.md).

### Reporter

> The BOS reporter is a feature of BOS v2 only.

The BOS reporter is a sub-service that must be installed on all nodes managed by BOS.
It is responsible for reporting the actual state of the node to BOS.

For more information, see [BOS Reporter](Reporter.md).

### Boot Orchestration Agent (BOA)

BOA is a feature of BOS v1 only. It is a Kubernetes job that is responsible for tracking all of the nodes in a BOS session and taking actions against them.

The source for BOA is located in the
[`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) open source GitHub repository.

## CLI

The [Cray CLI](../../glossary.md#cray-cli-cray) supports BOS commands, providing a more user friendly front-end for the
[BOS API](#api).

The first CLI argument specifies the BOS version.
For ease of interactive CLI use, specifying the BOS version is optional; it defaults to `v2`.
However, explicitly specifying the version in scripts or documentation is **highly recommended**,
because the default BOS version for the CLI is subject to change.

For context-specific usage information, append `--help` to the CLI command. For example:

* `cray bos --help`
* `cray bos v1 --help`
* `cray bos sessions --help`
* `cray bos v2 components list --help`

(`ncn-mw#`) API information, including the version, can be found with the following command:

```bash
cray bos list --format json
```

Example output:

```json
{
  "links": [
    {
      "href": "https://api-gw-service-nmn.local/apis/bos/",
      "rel": "self"
    },
    {
      "href": "https://api-gw-service-nmn.local/apis/bos/v2",
      "rel": "versions"
    }
  ],
  "major": "2",
  "minor": "10",
  "patch": "15"
}
```

For more information, see [BOS Commands Cheat Sheet](Cheatsheet.md).

## Versions

There are currently two supported API versions for BOS -- v1 and v2.
While they appear superficially similar, they work very differently.
For more detailed information than is found on this page, see [BOS API Versions](BOS_API_Versions.md).

### BOS v1

> BOS v1 is deprecated in CSM 1.3 and removed in CSM 1.6. See [BOS v1 removal](BOS_API_Versions.md#bos-v1-removal) for more information.

BOS v1 is strictly session based and uses a Boot Orchestration Agent (BOA) to fulfills boot requests.
After a BOS v1 session is created, BOS will create a Kubernetes BOA job to apply an action. BOA coordinates with the underlying subsystems to complete the action requested.

### BOS v2

BOS v2 takes a more flexible approach and relies on a number of permanent [operators](#operators) to guide components through state transitions in an independent manner.
The BOS v2 session can be used to track progress of the operation, but there is no centralized Kubernetes pod in which the session resides.

## Dependencies

BOS depends on each of the following services to complete its tasks:

* [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss)
    * Stores the configuration information that is used to boot each hardware component.
    * Nodes consult BSS for their boot artifacts and boot parameters when they boot or reboot.
* [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
    * BOS uses CFS to apply configuration to the nodes in its boot sets (node personalization).
* [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs)
    * Used by BOS to power nodes on and off, as well as query current power status.
* [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
    * BOS queries HSM to determine if a node is enabled or disabled.
    * BOS queries HSM to get the node membership lists for
      [HSM groups](../hardware_state_manager/Component_Groups_and_Partitions.md)
      and [HSM roles](../hardware_state_manager/HSM_Roles_and_Subroles.md).
* [Tenant and Partition Management System (TAPMS)](../../glossary.md#tenant-and-partition-management-system-tapms)
    * Manages tenant information for [Multi-tenancy](../README.md#multi-tenancy).
    * BOS queries TAPMS to determine which nodes belong to a given tenant.
    * For more information, see [Multi-tenancy with BOS](Multi_tenancy_with_BOS.md).
* [Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3)
    * Contains the actual data for the node images.

## Source code

The source code and Helm charts for BOS are located in the following open source GitHub repositories:

| *Repository* | *Contents* |
| ------------ | ---------- |
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server, API specification, database, operators, and `bos-reporter` RPM. |
| [`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) | BOA. |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
