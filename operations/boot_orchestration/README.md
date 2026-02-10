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
* [Dependencies](#dependencies)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service (BOS) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions.

BOS users create a BOS session template, and then create a BOS session, which applies an action to the session template.
The available actions are boot, reboot, and shutdown.
The session can be monitored to determine the status of the request.

For more information, see [BOS Workflows](BOS_Workflows.md).

## Terminology

* [Component](Components.md): A node (such as a [compute node](../../glossary.md#compute-node-cn) or [UAN](../../glossary.md#user-access-node-uan)).
    * Although [management nodes](../../glossary.md#management-nodes) have corresponding BOS components, BOS should not be used on them.
* [Options](Options.md): Adjustable parameters to control how BOS operates.
* [Session](Sessions.md): A request for BOS to perform an action on a specified set of components, bringing them to a specified desired state.
* [Session template](Session_Templates.md): A collection of metadata for a group of nodes and their desired boot artifacts and configuration.

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

BOS data is stored in a Redis database.

For more information, see [BOS Database](Database.md).

### Operators

BOS operators are always-running sub-services. They are each responsible for doing a single basic task,
such as powering on nodes, discovering new nodes on the system, or initializing a new session.

For more information, see [BOS Operators](Operators.md).

### Reporter

The BOS reporter is a sub-service that must be installed on all nodes managed by BOS.
It is responsible for reporting the actual state of the node to BOS.

For more information, see [BOS Reporter](Reporter.md).

### Boot Orchestration Agent (BOA)

BOA was a feature of BOS v1 only. It was a Kubernetes job that was responsible for tracking all of the components in a BOS session and taking actions against them.

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
* `cray bos v2 --help`
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
  "minor": "48",
  "patch": "2"
}
```

For more information, see [BOS Commands Cheat Sheet](Cheatsheet.md).

## Versions

> BOS v1 is not present starting in CSM 1.6. See [BOS v1 removal](BOS_API_Versions.md#bos-v1-removal) for more information.

There is only one supported API version for BOS -- v2. Compared to BOS v1, BOS v2 takes a more flexible approach and relies
on a number of permanent [operators](#operators) to guide components through state transitions in an independent manner.
The BOS v2 session can be used to track progress of the operation, but there is no centralized Kubernetes pod in which the session resides.
For more detailed information than is found on this page, see [BOS API Versions](BOS_API_Versions.md).

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
    * BOS queries HSM to determine which nodes have
      [HSM locks](../hardware_state_manager/Manage_HMS_Locks.md).
* [Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
    * Manages metadata records of the images used to boot nodes.
    * BOS sets and checks [IMS image tagging](../iscsi_sbps/README.md#4-ims-image-tagging) to enable
      [SBPS](../../glossary.md#scalable-boot-projection-service-sbps) projection to nodes.
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
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server, API specification, database, and operators. |
| [`Cray-HPE/bos-reporter`](https://github.com/Cray-HPE/bos-reporter/) | `bos-reporter` RPM. |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
