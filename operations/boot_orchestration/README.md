# Boot Orchestration Service (BOS)

* [Overview[(#overview)
* [Versions](#versions)
  * [BOS v1](#bos-v1)
  * [BOS v2](#bos-v2)
* [Dependencies](#dependencies)
* [CLI commands](#cli-commands)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions.

BOS users create a BOS session template using the REST API (or using the [Cray CLI](../../glossary.md#cray-cli-cray), which is a front-end for the REST API).
A session template is a collection of metadata for a group of nodes and their desired boot artifacts and configuration.
A BOS session can then be created by applying an action to a session template. The available actions are boot, reboot, shutdown, and configure.
The session can be monitored to determine the status of the request.

> The configure action is only available in [BOS v1](#bos-v1) sessions.

For more information, see [BOS Workflows](BOS_Workflows.md).

## Versions

There are currently two supported API versions for BOS -- v1 and v2.
While they appear superficially similar, they work very differently.
For more detailed information than is found on this page, see [BOS API Versions](BOS_API_Versions.md).

### BOS v1

> BOS v1 is deprecated in CSM 1.3 and removed in CSM 1.6. See [BOS v1 removal](BOS_API_Versions.md#bos-v1-removal) for more information.

BOS v1 is strictly session based and uses a Boot Orchestration Agent \(BOA\) to fulfills boot requests.
After a BOS v1 session is created, BOS will create a Kubernetes BOA job to apply an action. BOA coordinates with the underlying subsystems to complete the action requested.

### BOS v2

BOS v2 takes a more flexible approach and relies on a number of permanent operators to guide components through state transitions in an independent manner.
The BOS v2 session can be used to track progress of the operation, but there is no centralized Kubernetes pod in which the session resides.

## Dependencies

BOS depends on each of the following services to complete its tasks:

| *Service* | *Description* |
| --------- | ------------- |
| [BOA](Sessions.md#boot-orchestration-agent-boa) | Handles any action type submitted to the BOS v1 API. BOA jobs are created and launched by BOS. |
| [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) | Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when they boot or reboot. |
| [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) | BOS uses CFS to apply configuration to the nodes in its boot sets \(node personalization\). |
| [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) | Used to power on and off the nodes. |
| [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) | Tracks the state of each node, and the node membership of groups and roles. |

## CLI commands

The Cray CLI supports BOS commands. The first argument specifies the BOS version.
For ease of interactive CLI use, specifying the BOS version is optional; it defaults to v1.
However, explicitly specifying the version in scripts or documentation is **highly recommended**,
because the default BOS version for the CLI will change in a future CSM release.

(`ncn-mw#`) API information, including the default API version, can be found with the following command:

```bash
cray bos list --format toml
```

Example output:

```toml
[[results]]
major = "2"
minor = "0"
patch = "0"
[[links]]
href = "https://api-gw-service-nmn.local/apis/bos/"
rel = "self"

[[links]]
href = "https://api-gw-service-nmn.local/apis/bos/v2"
rel = "versions"
```

## Source code

The source code for BOS is located in the following open source GitHub repositories:

| *Repository* | *Contents* |
| ------------ | ---------- |
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server |
| [`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) | BOA |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
