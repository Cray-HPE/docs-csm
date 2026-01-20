# Boot Orchestration Service (BOS)

* [Overview[(#overview)
* [Terminology](#terminology)
* [Services](#services)
* [CLI](#cli)
* [Versions](#versions)
* [Dependencies](#dependencies)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions.

BOS users create a BOS session template, and then create a BOS session, which applies an action to the session template.
The available actions are boot, reboot, and shutdown.
The session can be monitored to determine the status of the request.

For more information, see [BOS Workflows](BOS_Workflows.md).

## Terminology

* [Boot Orchestration Agent (BOA)](BOS_Services.md#boot-Orchestration-agent-boa): A sub-service in BOS version 1 that does not exist in BOS version 2.
* [Component](Components.md): A node (such as a [compute node](../../glossary.md#compute-node-cn) or [UAN](../../glossary.md#user-access-node-uan)).
* [Operator](BOS_Services.md#bos-operators): Permanent BOS sub-service responsible for performing a specific task when necessary.
* [Options](Options.md): Adjustable parameters to control how BOS operates.
* [Session](Sessions.md): A request for BOS to perform an action on a specified set of components, bringing them to a specified desired state.
* [Session template](Session_Templates.md): A collection of metadata for a group of nodes and their desired boot artifacts and configuration.

## Services

BOS is made up of a number of different sub-services that combine to provide its functionality.
For details, see [BOS Services](BOS_Services.md).

## CLI

The [Cray CLI](../../glossary.md#cray-cli-cray) supports BOS commands, providing a more user friendly front-end for the
[BOS API](BOS_Services.md#bos-api).

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
  "minor": "30",
  "patch": "5"
}
```

For more information, see [BOS Commands Cheat Sheet](Cheatsheet.md).

## Versions

> BOS v1 is not present starting in CSM 1.6. See [BOS v1 removal](BOS_API_Versions.md#bos-v1-removal) for more information.

There is only one supported API version for BOS -- v2. Compared to BOS v1, BOS v2 takes a more flexible approach and relies
on a number of permanent [operators](BOS_Services.md#bos-operators) to guide components through state transitions in an independent manner.
The BOS v2 session can be used to track progress of the operation, but there is no centralized Kubernetes pod in which the session resides.
For more detailed information than is found on this page, see [BOS API Versions](BOS_API_Versions.md).

## Dependencies

BOS depends on each of the following services to complete its tasks:

| *Service* | *Description* |
| --------- | ------------- |
| [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) | Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when they boot or reboot. |
| [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) | BOS uses CFS to apply configuration to the nodes in its boot sets \(node personalization\). |
| [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs) | Used to power nodes on and off, as well as query current power status. |
| [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) | Tracks the state of each node, and the node membership of groups and roles. |

## Source code

The source code for BOS is located in the following open source GitHub repositories:

| *Repository* | *Contents* |
| ------------ | ---------- |
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server, API specification, database, operators, and `bos-reporter` RPM. |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
