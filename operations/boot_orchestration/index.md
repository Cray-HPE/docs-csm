# Boot Orchestration Service (BOS)

* [Overview[(#overview)
* [Terminology](#terminology)
* [Services](#services)
  * [API](#api)
  * [Database](#database)
  * [Boot Orchestration Agent (BOA)](#boot-orchestration-agent-boa)
* [CLI](#cli)
* [API changes in CSM 1.2.0](#api-changes-in-csm-120)
* [Versions](#versions)
* [Dependencies](#dependencies)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service (BOS) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions.

BOS users create a BOS session template, and then create a BOS session, which applies an action to the session template.
The available actions are boot, reboot, shutdown, and configure.
The session can be monitored to determine the status of the request.

For more information, see [BOS Workflows](BOS_Workflows.md).

## Terminology

* [Session](Sessions.md): A request for BOS to perform an action on a specified set of components, bringing them to a specified desired state.
* [Session template](Session_Templates.md): A collection of metadata for a group of nodes and their desired boot artifacts and configuration.

## Services

BOS is made up of a number of different sub-services that combine to provide its functionality.

* [API](#api)
* [Database](#database)
* [Boot Orchestration Agent (BOA)](#boot-orchestration-agent-boa)

### API

The API is the point of contact for the user and all other services that want to query or update BOS data.

For more information, see [BOS API](API.md).

### Database

BOS data is stored in an etcd database.

For more information, see [BOS Database](Database.md).

### Boot Orchestration Agent (BOA)

BOS uses a Boot Orchestration Agent (BOA) to fulfills boot requests.
After a BOS session is created, BOS will create a Kubernetes BOA job to apply an action.
BOA coordinates with the underlying subsystems to complete the action requested.

For more information, see [Boot Orchestration Agent (BOA)](Sessions.md#boot-orchestration-agent-boa).

The source for BOA is located in the
[`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) open source GitHub repository.

## CLI

The [Cray CLI](../../glossary.md#cray-cli-cray) supports BOS commands, providing a more user friendly front-end for the
[BOS API](#api).

The first CLI argument specifies the BOS version.
For ease of interactive CLI use, specifying the BOS version is optional; it defaults to `v1`.
However, explicitly specifying the version in scripts or documentation is **highly recommended**,
because the default BOS version for the CLI is subject to change.

For context-specific usage information, append `--help` to the CLI command. For example:

* `cray bos --help`
* `cray bos v1 --help`
* `cray bos session --help`
* `cray bos v1 sessiontemplate list --help`

API information, including the version, can be found with the following command:

```console
ncn-mw# cray bos list --format json
```

Example output:

```json
{
  "links": [
    {
      "href": "https://api-gw-service-nmn.local/apis/bos/v1",
      "rel": "self"
    }
  ],
  "major": "1",
  "minor": "0",
  "patch": "0"
}
```

## API changes in CSM 1.2.0

This is a forewarning of the following changes to the BOS API in CSM 1.2.0:

* The `--template-body` option for the Cray CLI BOS command is deprecated.
* The status code for a successful GET on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) is 200.
  * This is a change from CSM 1.0, where the status code is 201.

## Versions

There is only one supported API version for BOS -- v1.
In CSM 1.3, BOS v1 is deprecated and BOS v2 is introduced.
BOS v1 is removed in CSM 1.6.

## Dependencies

BOS depends on each of the following services to complete its tasks:

* [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss)
  * Stores the configuration information that is used to boot each hardware component.
  * Nodes consult BSS for their boot artifacts and boot parameters when they boot or reboot.
* [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
  * BOA uses CFS to apply configuration to the nodes in its boot sets (node personalization).
* [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
  * Used to power nodes on and off, as well as query current power status.
* [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
  * Tracks the state of each node, and the node membership of
    [groups](../hardware_state_manager/Component_Groups_and_Partitions.md)
    and [roles](../hardware_state_manager/HSM_Roles_and_Subroles.md).
* [Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3)
  * Contains the actual data for the node images.

## Source code

The source code and Helm charts for BOS are located in the following open source GitHub repositories:

| *Repository* | *Contents* |
| ------------ | ---------- |
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server, API specification, and database. |
| [`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) | BOA. |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
