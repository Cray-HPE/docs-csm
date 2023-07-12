# BOS Components

> **`NOTE`** This section is for Boot Orchestration Service (BOS) v2 only.

BOS v2 provides a components endpoint where BOS tracks the status of individual components.
This includes information on the desired state and some information on the current state, status, and any session the component is part of.

Component records are created automatically and will include any components found in the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).

* [BOS component fields](#bos-component-fields)
  * [`actual_state`](#actual_state)
  * [`desired_state`](#desired_state)
  * [`staged_state`](#staged_state)
  * [`enabled`](#enabled)
  * [`error`](#error)
  * [`event_stats`](#event_stats)
  * [`last_action`](#last_action)
  * [`session`](#session)
  * [`status`](#status)
* [Managing BOS components](#managing-bos-components)
  * [List all components](#list-all-components)
  * [Show details for a component](#show-details-for-a-component)
  * [Update a component](#update-a-component)

## BOS component fields

### `actual_state`

Stores information on what BOS believes is the current boot artifacts the component is booted with. This is updated by the BOS state reporter, which runs on the booted node.
For more information, see [BOS state reporter](BOS_Services.md#bos-state-reporter).
See [Options](Options.md) for more information on setting the `component_actual_state_ttl` option, which controls how long this data is valid if it is not updated.
Information stored in other locations, such as the current configuration which is stored in CFS, is not included here.

### `desired_state`

Stores information on the desired boot artifacts and configuration for a component. If the component is enabled, BOS will try to make the actual state match the desired state.

### `staged_state`

Stores information on the eventual desired boot artifacts and configuration for a component. This has no immediate impact, but is moved to the desired state when the `applystaged` endpoint is called for the component.

### `enabled`

If the node is enabled (enabled == True), BOS will take action to make the actual state match the desired state.

### `error`

If the most recent action taken has failed or BOS is unable to continue operating on a component, an error message will be stored here.

### `event_stats`

These fields store data from the period of time when BOS begins operating on a component until the component either reaches its desired state or hits its retry limit and is marked failed.
The stored data includes the number of power on and power off attempts that have been tried for the component.

```json
"event_stats": {
  "power_off_forceful_attempts": 3,
  "power_off_graceful_attempts": 1,
  "power_on_attempts": 1
}
```

The number of attempts is limited by the `default_retry_policy` found in BOS options endpoint. See [Options](Options.md) for more information.

### `last_action`

Tracks information on the most recent action that BOS took on a component. This can be a power action, such as `powering_on`, or a management action such as `newly_discovered`.

### `session`

Stores the session ID of the session that is currently tracking the component.

### `status`

This collection of fields stores status information that the BOS operators and other users can query to determine the status of the component. Status fields should generally not be manually updated and should be left to BOS.  These fields include:

* `phase` - Describes the general phase of the boot process the component is currently in, such as `powering_on`, `powering_off` and `configuring`.
* `status` - A more specific description of where in the boot process the component is. This can be more detailed phases, such as `power_on_pending`, `power_on_called`, as well as final states such as `failed`.  
* `on_hold` is a special value that indicates BOS is re-evaluating the status of the component, such as when a component is re-enabled and BOS needs to collect new information from other services to determine the state of the component.
* `status_override` - A special status field that is used to override `status` when BOS would be unable to determine the status of the node with its current information. This includes the `on_hold` status.

## Managing BOS components

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.

### List all components

List all BOS components with the following command:

(`ncn-mw#`)

```bash
cray bos v2 components list --format json
```

Example output:

```json
[
  {
    "actual_state": {
      "boot_artifacts": {
        "initrd": "",
        "kernel": "",
        "kernel_parameters": ""
      },
      "bss_token": "",
      "last_updated": "2022-08-22T09:17:16"
    },
    "desired_state": {
      "boot_artifacts": {
        "initrd": "",
        "kernel": "",
        "kernel_parameters": ""
      },
      "bss_token": "",
      "configuration": "",
      "last_updated": "2022-08-22T09:17:16"
    },
    "enabled": false,
    "error": "",
    "event_stats": {
      "power_off_forceful_attempts": 0,
      "power_off_graceful_attempts": 0,
      "power_on_attempts": 0
    },
    "id": "x3000c0s13b0n0",
    "last_action": {
      "action": "newly_discovered",
      "last_updated": "2022-08-22T09:17:16"
    },
    "session": "",
    "staged_state": {
      "last_updated": "2022-08-22T09:17:16"
    },
    "status": {
      "phase": "",
      "status": "stable",
      "status_override": ""
    }
  }
]
```

### Show details for a component

Get details for a BOS session using the component `xname`.

(`ncn-mw#`):

```bash
cray bos v2 components describe <XNAME> --format json
```

Example output:

```json
{
  "actual_state": {
    "boot_artifacts": {
      "initrd": "",
      "kernel": "",
      "kernel_parameters": ""
    },
    "bss_token": "",
    "last_updated": "2022-08-22T09:17:16"
  },
  "desired_state": {
    "boot_artifacts": {
      "initrd": "",
      "kernel": "",
      "kernel_parameters": ""
    },
    "bss_token": "",
    "configuration": "",
    "last_updated": "2022-08-22T09:17:16"
  },
  "enabled": false,
  "error": "",
  "event_stats": {
    "power_off_forceful_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_on_attempts": 0
  },
  "id": "x3000c0s13b0n0",
  "last_action": {
    "action": "newly_discovered",
    "last_updated": "2022-08-22T09:17:16"
  },
  "session": "",
  "staged_state": {
    "last_updated": "2022-08-22T09:17:16"
  },
  "status": {
    "phase": "",
    "status": "stable",
    "status_override": ""
  }
}
```

### Update a component

Update a BOS component using `xname`.  While most fields can be updated manually, users should restrict themselves to updating the `desired_state` and `enabled`.  Altering other fields such as `status` or `last_action` may result in unintended behavior.

(`ncn-mw#`):

```bash
cray bos v2 components update <XNAME> --enabled True --format json
```

Example output:

```json
{
  "actual_state": {
    "boot_artifacts": {
      "initrd": "",
      "kernel": "",
      "kernel_parameters": ""
    },
    "bss_token": "",
    "last_updated": "2022-08-22T09:17:16"
  },
  "desired_state": {
    "boot_artifacts": {
      "initrd": "",
      "kernel": "",
      "kernel_parameters": ""
    },
    "bss_token": "",
    "configuration": "",
    "last_updated": "2022-08-22T09:17:16"
  },
  "enabled": true,
  "error": "",
  "event_stats": {
    "power_off_forceful_attempts": 0,
    "power_off_graceful_attempts": 0,
    "power_on_attempts": 0
  },
  "id": "x3000c0s13b0n0",
  "last_action": {
    "action": "newly_discovered",
    "last_updated": "2022-08-22T09:17:16"
  },
  "session": "",
  "staged_state": {
    "last_updated": "2022-08-22T09:17:16"
  },
  "status": {
    "phase": "",
    "status": "stable",
    "status_override": ""
  }
}
```
