# Boot Orchestration Service (BOS)

* [Overview[(#overview)
* [Dependencies](#dependencies)
* [CLI commands](#cli-commands)
* [API changes in CSM 1.2.0](#api-changes-in-csm-120)
* [Source code](#source-code)

## Overview

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes.
This is accomplished using BOS session templates and sessions, as well as a Boot Orchestration Agent \(BOA\) that fulfills boot requests.

BOS users create a BOS session template using the REST API (or using the [Cray CLI](../../glossary.md#cray-cli-cray), which is a front-end for the REST API).
A session template is a collection of metadata for a group of nodes and their desired boot artifacts and configuration.
A BOS session can then be created by applying an action to a session template. The available actions are boot, reboot, shutdown, and configure.
BOS will create a Kubernetes BOA job to apply an action. BOA coordinates with the underlying subsystems to complete the action requested.
The session can be monitored to determine the status of the request.

## Dependencies

BOS depends on each of the following services to complete its tasks:

| *Service* | *Description* |
| --------- | ------------- |
| [BOA](Sessions.md#boot-orchestration-agent-boa) | Handles any action type submitted to the BOS API. BOA jobs are created and launched by BOS. |
| [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) | Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when they boot or reboot. |
| [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) | BOA uses CFS to apply configuration to the nodes in its boot sets \(node personalization\). |
| [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) | Used to power on and off the nodes. |
| [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) | Tracks the state of each node, and the node membership of groups and roles. |

## CLI commands

The Cray CLI supports BOS commands. For example, the BOS version can be found with the following command:

```text
ncn-m001# cray bos list --format toml
```

Example output:

```toml
[[results]]
major = "1"
minor = "0"
patch = "0"
[[results.links]]
href = "https://api-gw-service-nmn.local/apis/bos/v1"
rel = "self"
```

## API changes in CSM 1.2.0

This is a notice of the following changes to the BOS API in CSM 1.2.0:

* The `--template-body` option for the Cray CLI BOS command is deprecated.
* The status code for a successful GET on the session status for a boot set (i.e. `/v1/session/{session_id}/status/{boot_set_name}`) is now 200.
  * This is a change from CSM 1.0, where the status code was 201.

## Source code

The source code for BOS is located in the following open source GitHub repositories:

| *Repository* | *Contents* |
| ------------ | ---------- |
| [`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) | BOS API server |
| [`Cray-HPE/boa`](https://github.com/Cray-HPE/boa/) | BOA |
| [`Cray-HPE/craycli`](https://github.com/Cray-HPE/craycli/) | The Cray CLI, including the BOS subcommands. |
| [`Cray-HPE/cms-tools`](https://github.com/Cray-HPE/cms-tools/) | Health checks and utilities for several CSM services, including BOS. |
