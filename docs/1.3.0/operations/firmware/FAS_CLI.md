# FAS CLI

This section describes the basic capabilities of the Firmware Action Service (FAS) CLI commands. These commands can be used to manage firmware for system hardware supported by FAS. Refer to the
prerequisites section before proceeding to any of the sections for the supported operations.

The following CLI operations are described:

- [Prerequisites](#prerequisites)
- [Actions](#actions)
  - [Execute an action](#execute-an-action)
    - [Procedure](#execute-an-action-procedure)
  - [Abort an action](#abort-an-action)
    - [Procedure](#abort-an-action-procedure)
  - [Describe an action](#describe-an-action)
    - [Interpreting output](#describe-an-action-interpreting-output)
    - [Procedure](#describe-an-action-procedure)
      - [Get high level summary](#get-high-level-summary)
      - [Get details of action](#get-details-of-action)
      - [Get details of operation](#get-details-of-operation)
- [Snapshots](#snapshots)
  - [Create a snapshot](#create-a-snapshot)
    - [Procedure](#create-a-snapshot-procedure)
  - [List snapshots](#list-snapshots)
    - [Procedure](#list-snapshots-procedure)
  - [View snapshots](#view-snapshots)
    - [Procedure](#view-snapshots-procedure)
- [Update a firmware image](#update-a-firmware-image)
  - [Procedure](#update-a-firmware-image-procedure)
- [FAS loader commands](#fas-loader-commands)
  - [Loader status](#loader-status)
  - [Load firmware from Nexus](#load-firmware-from-nexus)
  - [Load individual RPM or ZIP into FAS](#load-individual-rpm-or-zip-into-fas)
  - [Display results of loader run](#display-results-of-loader-run)
  - [Delete loader run data](#delete-loader-run-data)

## Prerequisites

The Cray command line interface (CLI) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

## Actions

### Execute an action

Use FAS to execute an action. An action produces a set of firmware operations. Each operation represents a component name (xname) + target on that component name (xname) that will be targeted for
update. There are two of firmware action modes: : `dryrun` or `liveupdate`; the parameters used when creating either are completely identical except for the `overrideDryrun` setting. `overrideDryrun`
will determine if feature to determine what firmware can be updated on the system. Dry-runs are enabled by default, and can be configured with the `overrideDryrun` parameter. A dry-run will create a
query according to the filters requested by the admin. It will initiate an update sequence to determine what firmware is available, but will not actually change the state of the firmware.

> **WARNING**: It is crucial that an administrator is familiar with the release notes of any firmware. The release notes will indicate what new features the firmware provides and if there are any
> incompatibilities. FAS does not know about incompatibilities or dependencies between versions. The administrator assumes full responsibility for this knowledge. It is also likely that when
> performing a firmware update, the current version of firmware will not be available. This means that after successfully upgrading, the firmware cannot be reverted or downgraded to a previous version.

#### Execute an action: Procedure

This covers the generic process for executing an action. For more specific examples and detailed explanations of options, see [FAS Recipes](FAS_Recipes.md) and [FAS Filters](FAS_Filters.md).

1. Identify the selection of filters to apply.

   Filters narrow the scope of FAS to target specific component names (xnames), manufacturers, targets, and so on. For this example, FAS will run with no selection filters applied.

1. (`ncn-mw#`) Create a JSON file.

    To make this a `live update` set `"overrideDryrun": true`.

    ```json
    {  "command": {
          "version": "latest",
          "tag":  "default",
          "overrideDryrun": false,
          "restoreNotPossibleOverride": true,
          "timeLimit": 1000,
          "description": "dryrun of full system" }
    }
    ```

1. (`ncn-mw#`) Execute the dry-run.

    Modify the example command to specify the JSON file created in the previous step.

    ```bash
    cray fas actions create filename.json --format json
    ```

    Example output:

    ```json
    {
      "actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
      "overrideDryun": false
    }
    ```

    Note the returned `actionID`.

See [Describe an action: Interpreting output](#describe-an-action-interpreting-output) for more information.

### Abort an action

Firmware updates can be stopped if required. This is useful because only one action can be run at a time. This is to protect hardware from multiple actions trying to modify it at the same time.

> **IMPORTANT:** If a Redfish update is already in progress, the abort will not stop that process on the device. It is likely the device will update. If the device needs to be manually power cycled
> (`needManualReboot`), then it is possible that the device will update, but not actually apply the update until its next reboot. Administrators must verify the state of the system after an abort.
> Only perform an abort if truly necessary. The best way to check the state of the system is to do a snapshot or do a dry-run of an update.

#### Abort an action: Procedure

(`ncn-mw#`) Issue the abort command to the action.

Modify the example command to specify the `actionID` of the action being aborted.

```bash
cray fas actions instance delete {actionID}
```

The action could take up to a minute to fully abort.

### Describe an action

There are several ways to get more information about a firmware update. An `actionID` and `operationID`s are generated when a live update or dry-run is created. These values can be used to learn more
about what is happening on the system during an update.

#### Describe an action: Interpreting output

For the steps below, the following returned messages will help determine if a firmware update is needed. The following are end `state`s for `operations`. The Firmware `action` itself should be in `completed` once all operations have finished.

- `NoOp`: Nothing to do, already at version.
- `NoSol`: No image is available.
- `succeeded`:
  - If `dryrun`: The operation should succeed if performed as a `live update`. `succeeded` means that FAS identified that it COULD update a component name (xname) + target with the declared strategy.
  - If `live update`: The operation succeeded, and has updated the component name (xname) + target to the identified version.
- `failed`:
  - If `dryrun`: There is something that FAS could do, but it likely would fail; most likely because the file is missing.
  - If `live update`: The operation failed; the identified version could not be put on the component name (xname) + target.

**NOTE**: Any node which is locked will remain in the state `inProgress` with the `stateHelper` message of `"failed to lock"` until the action times out, or the lock is released.
These nodes will report as `failed` with the `stateHelper` message of `"time expired; could not complete update"` if action times out.
This includes NCNs which are manually locked to prevent accidental rebooting and firmware updates.

Data can be viewed at several levels of information:

#### Describe an action: Procedure

##### Get high level summary

(`ncn-mw#`) To view counts of operations, what state they are in, the overall state of the action, and what parameters were used to create the action:

Modify the following command to specify the actual `actionID` of the action to be examined.

```bash
cray fas actions status list {actionID} --format toml
```

Example output:

```toml
actionID = "e6dc14cd-5e12-4d36-a97b-0dd372b0930f"
snapshotID = "00000000-0000-0000-0000-000000000000"
startTime = "2021-09-07 16:43:04.294233199 +0000 UTC"
endTime = "2021-09-07 16:53:09.363233482 +0000 UTC"
state = "completed"
blockedBy = []

[command]
overrideDryrun = false
restoreNotPossibleOverride = true
overwriteSameImage = false
timeLimit = 2000
version = "latest"
tag = "default"
description = "Dryrun upgrade of Gigabyte node BMCs"

[operationCounts]
total = 14
initial = 0
configured = 0
blocked = 0
needsVerified = 0
verifying = 0
inProgress = 0
failed = 0
succeeded = 8
noOperation = 6
noSolution = 0
aborted = 0
unknown = 0
```

> **IMPORTANT:** The action is still in progress unless the action's `state` is `completed` or `aborted`.

##### Get details of action

(`ncn-mw#`) Modify the following command to specify the actual `actionID` of the action to be examined.

```bash
cray fas actions describe {actionID} --format json
```

Example output:

```json
{
  "parameters": {
    "stateComponentFilter": {
      "deviceTypes": [
        "nodeBMC"
      ]
    },
    "command": {
      "dryrun": false,
      "description": "upgrade of nodeBMCs for cray",
      "tag": "default",
      "restoreNotPossibleOverride": true,
      "timeLimit": 1000,
      "version": "latest"
    },
    "inventoryHardwareFilter": {
      "manufacturer": "cray"
    },
    "imageFilter": {
      "imageID": "00000000-0000-0000-0000-000000000000"
    },
    "targetFilter": {
      "targets": [
        "BMC"
      ]
    }
  },
  "blockedBy": [],
  "state": "completed",
  "command": {
    "dryrun": false,
    "description": "upgrade of nodeBMCs for cray",
    "tag": "default",
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "version": "latest"
  },
  "actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
  "startTime": "2020-06-26 20:03:37.316932354 +0000 UTC",
  "snapshotID": "00000000-0000-0000-0000-000000000000",
  "endTime": "2020-06-26 20:04:07.118243184 +0000 UTC",
  "operationSummary": {
    "succeeded": {
      "OperationsKeys": []
    },
    "verifying": {
      "OperationsKeys": []
    },
    "unknown": {
      "OperationsKeys": []
    },
    "configured": {
      "OperationsKeys": []
    },
    "initial": {
      "OperationsKeys": []
    },
    "failed": {
      "OperationsKeys": [
        {
          "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
          "fromFirmwareVersion": "",
          "xname": "x5000c1r7b0",
          "target": "BMC",
          "operationID": "0796eed0-e95d-45ea-bc71-8903d52cffde"
        },
      ]
    },
    "noSolution": {
      "OperationsKeys": []
    },
    "aborted": {
      "OperationsKeys": []
    },
    "needsVerified": {
      "OperationsKeys": []
    },
    "noOperation": {
      "OperationsKeys": []
    },
    "inProgress": {
      "OperationsKeys": []
    },
    "blocked": {
      "OperationsKeys": []
    }
  }
}
```

##### Get details of operation

(`ncn-mw#`) Using the `operationID` listed in the actions array, see the full detail of the operation.

Modify the following command to specify the actual `operationID` of the operation to be examined.

```bash
cray fas operations describe {operationID} --format json
```

Example output:

```json
{
    "fromFirmwareVersion": "", "fromTag": "",
    "fromImageURL": "",
    "endTime": "2020-06-24 14:23:37.544814197 +0000 UTC",
    "actionID": "f48aabf1-1616-49ae-9761-a11edb38684d", "startTime": "2020-06-24 14:19:15.10128214 +0000 UTC",
    "fromSemanticFirmwareVersion": "", "toImageURL": "",
    "model": "WindomNodeCard_REV_D",
    "operationID": "24a5e5fb-5c4f-4848-bf4e-b071719c1850", "fromImageID": "00000000-0000-0000-0000-000000000000",
    "target": "BMC",
    "toImageID": "71c41a74-ab84-45b2-95bd-677f763af168", "toSemanticFirmwareVersion": "",
    "refreshTime": "2020-06-24 14:23:37.544824938 +0000 UTC",
    "blockedBy": [],
    "toTag": "",
    "state": "succeeded",
    "stateHelper": "unexpected change detected in firmware version. Expected nc.1.3.8-shasta-release.arm.2020-06-15T22:57:31+00:00.b7f0725 got: nc.1.2.25-shasta-release.arm.2020-05-15T17:27:16+00:00.0cf7f51",
    "deviceType": "",
    "expirationTime": "",
    "manufacturer": "cray",
    "xname": "x9000c1s3b1",
    "toFirmwareVersion": ""
}
```

## Snapshots

FAS includes a snapshot feature to record the firmware value for each device (type and target) on the system into the FAS database.

### Create a snapshot

Similar to the FAS actions described above, FAS provides a lot of flexibility for taking snapshots.

A snapshot of the system captures the firmware version for every device that is in the Hardware State Manager (HSM) Redfish Inventory.

#### Create a snapshot: Procedure

1. (`ncn-mw#`) Determine the desired snapshot level.

   Create a JSON file based on the desired level.

   - Full system

      ```json
      {
          "name":"fullSystem_20200701"
      }
      ```

   - Partial system

      ```json
      {
          "name": "20200402_all_xnames",
          "expirationTime": "2020-06-26T16:32:53.275Z",
          "stateComponentFilter": {
              "partitions": [
                  "p1"
              ],
              "deviceTypes": [
                  "nodeBMC"
              ]
          },
          "inventoryHardwareFilter": {
              "manufacturer": "gigabyte"
          },
          "targetFilter": {
              "targets": [
                  "BMC"
              ]
          }
      }
      ```

1. (`ncn-mw#`) Create the snapshot.

    Modify the example command to specify the JSON file created in the previous step.

    ```bash
    cray fas snapshots create {file.json}
    ```

1. Use the snapshot name to query the snapshot. This is a long-running operation, so monitor the `state` field to determine if the snapshot is complete.

### List snapshots

A list of all snapshots can be viewed on the system. Any of the snapshots listed can be used to restore the firmware on the system.

#### List snapshots: Procedure

1. (`ncn-mw#`) List the snapshots.

    ```bash
    cray fas snapshots list --format json
    ```

    Example output:

    ```json
    {
        "snapshots": [
            {
              "ready": true,
              "captureTime": "2020-06-25 22:47:11.072268274 +0000 UTC",
              "relatedActions": [],
              "name": "1",
              "uniqueDeviceCount": 9
            },
            {
              "ready": true,
              "captureTime": "2020-06-25 22:49:13.314876084 +0000 UTC",
              "relatedActions": [],
              "name": "3",
              "uniqueDeviceCount": 9
            },
            {
              "ready": true,
              "captureTime": "2020-06-26 22:38:12.309979483 +0000 UTC",
              "relatedActions": [],
              "name": "adn0",
              "uniqueDeviceCount": 6
            }
        ]
    }
    ```

### View snapshots

View a snapshot to see which versions of firmware are set for each target.

#### View snapshots: Procedure

1. (`ncn-mw#`) View a snapshot.

    Modify the following command to specify the actual name of the snapshot to be examined.

    ```bash
    cray fas snapshots describe {snapshot_name} --format json
    ```

    Example output:

    ```json
    {
      "relatedActions": [],
      "name": "all",
      "parameters": {
        "stateComponentFilter": {},
        "targetFilter": {},
        "name": "all",
        "inventoryHardwareFilter": {}
      },
      "ready": true,
      "captureTime": "2020-06-26 19:13:53.755350771 +0000 UTC",
      "devices": [
        {
          "xname": "x3000c0s19b4",
          "targets": [
            {
              "name": "BIOS",
              "firmwareVersion": "C12",
              "imageID": "00000000-0000-0000-0000-000000000000"
            },
            {
              "name": "BMC",
              "firmwareVersion": "12.03.3",
              "imageID": "00000000-0000-0000-0000-000000000000"
            }
          ]
        },
        {
          "xname": "x3000c0s1b0",
          "targets": [
            {
              "name": "BPB_CPLD1",
              "firmwareVersion": "10",
              "imageID": "00000000-0000-0000-0000-000000000000"
            },
            {
              "name": "BMC",
              "firmwareVersion": "12.03.3",
              "imageID": "00000000-0000-0000-0000-000000000000"
            },
            {
              "name": "BIOS",
              "firmwareVersion": "C12",
              "imageID": "00000000-0000-0000-0000-000000000000"
            },
            {
              "name": "BPB_CPLD2",
              "firmwareVersion": "10",
              "imageID": "00000000-0000-0000-0000-000000000000"
            }
          ]
        }
      ]
    }
    ```

## Update a firmware image

If FAS indicates that hardware is in a `nosolution` state as a result of a dry-run or update, it is an indication that there is no matching image available to update firmware.
A missing image is highly possible, but the issue could also be that the hardware has inconsistent model names in the image file.

Given the nature of the `model` field and its likelihood to not be standardized, it may be necessary to update the image to include an image that is not currently present.

### Update a firmware image: Procedure

1. (`ncn-mw#`) List the existing firmware images to find the `imageID` of the desired firmware image.

    ```bash
    cray fas images list
    ```

1. (`ncn-mw#`) Describe the image using the `imageID`.

    Modify the following command to specify the actual `imageID` of the image to be examined.

    ```bash
    cray fas images describe {imageID} --format json
    ```

    Example output:

    ```json
    {
      "semanticFirmwareVersion": "0.2.6",
      "target": "Node0.BIOS",
      "waitTimeBeforeManualRebootSeconds": 0,
      "tags": [
        "default"
      ],
      "models": [
        "GrizzlyPeak-Rome"
      ],
      "updateURI": "",
      "waitTimeAfterRebootSeconds": 0,
      "imageID": "efa4c2bc-06b9-4e88-8098-8d6778c1db52",
      "s3URL": "s3:/fw-update/794c47d1b7e011ea8d20569839947aa5/gprnc.bios-0.2.6.tar.gz",
      "forceResetType": "",
      "deviceType": "nodeBMC",
      "pollingSpeedSeconds": 30,
      "createTime": "2020-06-26T19:08:52Z",
      "firmwareVersion": "gprnc.bios-0.2.6",
      "manufacturer": "cray"
    }
    ```

1. (`ncn-mw#`) Describe the FAS action and compare it to the image from the previous step.

    Look at the hardware models to see if some of the population is in a `noSolution` state, while others are in a `succeeded` state.
    If that is the case, then view the operation data and examine the models.

    Modify the following command to specify the actual `actionID` of the action to be examined.

    ```bash
    cray fas actions describe {actionID} --format json
    ```

    Example output:

   ```json
      "parameters": {
        "stateComponentFilter": {
          "deviceTypes": [
            "nodeBMC"
          ]
        },
        "command": {
          "dryrun": false,
          "description": "upgrade of nodeBMCs for cray",
          "tag": "default",
          "restoreNotPossibleOverride": true,
          "timeLimit": 1000,
          "version": "latest"
        },
        "inventoryHardwareFilter": {
          "manufacturer": "cray"
        },
        "imageFilter": {
          "imageID": "00000000-0000-0000-0000-000000000000"
        },
        "targetFilter": {
          "targets": [
            "BMC"
          ]
        }
      },
      "blockedBy": [],
      "state": "completed",
      "command": {
        "dryrun": false,
        "description": "upgrade of nodeBMCs for cray",
        "tag": "default",
        "restoreNotPossibleOverride": true,
        "timeLimit": 1000,
        "version": "latest"
      },
      "actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
      "startTime": "2020-06-26 20:03:37.316932354 +0000 UTC",
      "snapshotID": "00000000-0000-0000-0000-000000000000",
      "endTime": "2020-06-26 20:04:07.118243184 +0000 UTC",
      "operationSummary": {
        "succeeded": {
          "OperationsKeys": []
        },
        "verifying": {
          "OperationsKeys": []
        },
        "unknown": {
          "OperationsKeys": []
        },
        "configured": {
          "OperationsKeys": []
        },
        "initial": {
          "OperationsKeys": []
        },
        "failed": {
          "OperationsKeys": [
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "",
              "xname": "x5000c1r7b0",
              "target": "BMC",
              "operationID": "0796eed0-e95d-45ea-bc71-8903d52cffde"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c3r7b0",
              "target": "BMC",
              "operationID": "11421f0b-1fde-4917-ba56-c42b321fc833"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c3r3b0",
              "target": "BMC",
              "operationID": "21e04403-f89f-4a9f-9fd6-5affc9204689"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c1r5b0",
              "target": "BMC",
              "operationID": "3a13a459-2102-4ee5-b516-62880baa132d"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c1r1b0",
              "target": "BMC",
              "operationID": "80fafbdd-9bac-407d-b28a-ad47c197bbc1"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c3r5b0",
              "target": "BMC",
              "operationID": "a86e8e04-81cc-40ad-ac62-438ae73e033a"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c1r3b0",
              "target": "BMC",
              "operationID": "dd0e8b62-8894-4751-bd22-a45506a2a50a"
            },
            {
              "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
              "xname": "x5000c3r1b0",
              "target": "BMC",
              "operationID": "f87bff63-d231-403e-b6b6-fc09e4dc7d11"
            }
          ]
        },
        "noSolution": {
          "OperationsKeys": []
        },
        "aborted": {
          "OperationsKeys": []
        },
        "needsVerified": {
          "OperationsKeys": []
        },
        "noOperation": {
          "OperationsKeys": []
        },
        "inProgress": {
          "OperationsKeys": []
        },
        "blocked": {
          "OperationsKeys": []
        }
      }
    }
    ```

1. (`ncn-mw#`) View the operation data.

    If the model name is different between identical hardware, it may be appropriate to update the image model with the model of the `noSolution` hardware.

    Modify the following command to specify the actual `operationID` of the operation to be examined.

    ```bash
    cray fas operations describe {operationID} --format json
    ```

    Example output:

    ```json
    {
      "fromFirmwareVersion": "sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
      "fromTag": "",
      "fromImageURL": "",
      "endTime": "2020-06-26 20:15:38.535719717 +0000 UTC",
      "actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
      "startTime": "2020-06-26 20:03:39.44911099 +0000 UTC",
      "fromSemanticFirmwareVersion": "",
      "toImageURL": "",
      "model": "ColoradoSwitchBoard_REV_A",
      "operationID": "f87bff63-d231-403e-b6b6-fc09e4dc7d11",
      "fromImageID": "00000000-0000-0000-0000-000000000000",
      "target": "BMC",
      "toImageID": "1540ce48-91db-4bbf-a0cf-5cf936c30fbc",
      "toSemanticFirmwareVersion": "1.4.35",
      "refreshTime": "2020-06-26 20:15:38.535722248 +0000 UTC",
      "blockedBy": [],
      "toTag": "",
      "state": "failed",
      "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
      "deviceType": "RouterBMC",
      "expirationTime": "2020-06-26 20:20:19.44911275 +0000 UTC",
      "manufacturer": "cray",
      "xname": "x5000c3r1b0",
      "toFirmwareVersion": "sc.1.4.35-prod-master.arm64.2020-06-26T08:36:42+00:00.0c2bb02"
    }
    ```

1. (`ncn-mw#`) Update the firmware image file.

   This step should be skipped if there is no clear evidence of a missing image or incorrect model name.

   > **WARNING:** The administrator needs to be certain the firmware is compatible before proceeding.

   1. Dump the content of the firmware image to a JSON file.

      Modify the following command to specify the actual `imageID` of the image to be updated.

      ```bash
      cray fas images describe {imageID} --format json > imagedata.json
      ```

   1. Edit the new `imagedata.json` file.

      Update any incorrect firmware information, such as the model name.

   1. Update the firmware image.

      Modify the following command to specify the actual `imageID` of the image to be updated,
      and be sure that the filename matches the edited file from the previous step.

      ```bash
      cray fas images update imagedata.json {imageID}
      ```

## FAS loader commands

### Loader status

(`ncn-mw#`) To check if the loader is currently busy and receive a list of loader run IDs:

```bash
cray fas loader list --format toml
```

Example output:

```toml
loaderStatus = "ready"
[[loaderRunList]]
loaderRunID = "770af5a4-15bf-4e9f-9983-03069479dc23"

[[loaderRunList]]
loaderRunID = "8efb19c4-77a2-41da-9a8f-fccbfe06f674"
```

The loader can only run one job at a time. If the loader is busy, then it will return an error on any attempt to create an additional job.

### Load firmware from Nexus

Firmware may be released and placed into the Nexus repository.

(`ncn-mw#`) To load the firmware from Nexus into FAS, use the following command:

```bash
cray fas loader nexus create --format toml
```

Example output:

```toml
loaderRunID = "c2b7e9bb-f428-4e4c-aa83-d8fd8bcfd820"
```

Use the `loaderRunID` to check the results of the loader run.

See [Load Firmware from Nexus](FAS_Admin_Procedures.md#load-firmware-from-nexus).

### Load individual RPM or ZIP into FAS

1. Copy the RPM or ZIP file to one of the master or worker NCNs.

1. (`ncn-mw#`) Load the firmware into FAS.

   Be sure to update the example command with the actual path and filename of the RPM or ZIP file to be loaded.

   ```bash
   cray fas loader create --file firmware.rpm --format toml
   ```

   Example output:

   ```toml
   loaderRunID = "dd37dd45-84ec-4bd6-b3c9-7af480048966"
   ```

Use the `loaderRunID` to check the results of the loader run.

See [Load Firmware from RPM or ZIP file](FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file).

### Display results of loader run

(`ncn-mw#`) Using the `loaderRunID` returned from the loader upload command, run the following command to get the output from the upload.

Be sure to update the example command with the actual `loaderRunID` whose output is to be checked.

```bash
cray fas loader describe dd37dd45-84ec-4bd6-b3c9-7af480048966 --format json
```

Example output:

```json
{
  "loaderRunOutput": [
    "2021-04-28T14:40:45Z-FWLoader-INFO-Starting FW Loader, LOG_LEVEL: INFO; value: 20",
    "2021-04-28T14:40:45Z-FWLoader-INFO-urls: {'fas': 'http://localhost:28800', 'fwloc': 'file://download/'}",
    "2021-04-28T14:40:45Z-FWLoader-INFO-Using local file: /ilo5_241.zip",
    "2021-04-28T14:40:45Z-FWLoader-INFO-unzip /ilo5_241.zip",
    "Archive:  /ilo5_241.zip",
    "  inflating: ilo5_241.bin",
    "  inflating: ilo5_241.json",
    "2021-04-28T14:40:45Z-FWLoader-INFO-Processing files from file://download/",
    "2021-04-28T14:40:45Z-FWLoader-INFO-get_file_list(file://download/)",
    "2021-04-28T14:40:45Z-FWLoader-INFO-Processing File: file://download/ ilo5_241.json",
    "2021-04-28T14:40:45Z-FWLoader-INFO-Uploading b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin",
    "2021-04-28T14:40:45Z-FWLoader-INFO-Metadata {'imageData': \"{'deviceType': 'nodeBMC', 'manufacturer': 'hpe', 'models': ['ProLiant XL270d Gen10', 'ProLiant DL325 Gen10', 'ProLiant DL325 Gen10 Plus', 'ProLiant DL385 Gen10', 'ProLiant DL385 Gen10 Plus', 'ProLiant XL645d Gen10 Plus', 'ProLiant XL675d Gen10 Plus'], 'targets': ['iLO 5'], 'tags': ['default'], 'firmwareVersion': '2.41 Mar 08 2021', 'semanticFirmwareVersion': '2.41.0', 'pollingSpeedSeconds': 30, 'fileName': 'ilo5_241.bin'}\"}",
    "2021-04-28T14:40:46Z-FWLoader-INFO-IMAGE: {\"s3URL\": \"s3:/fw-update/b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin\", \"target\": \"iLO 5\", \"deviceType\": \"nodeBMC\", \"manufacturer\": \"hpe\", \"models\": [\"ProLiant XL270d Gen10\", \"ProLiant DL325 Gen10\", \"ProLiant DL325 Gen10 Plus\", \"ProLiant DL385 Gen10\", \"ProLiant DL385 Gen10 Plus\", \"ProLiant XL645d Gen10 Plus\", \"ProLiant XL675d Gen10 Plus\"], \"softwareIds\": [], \"tags\": [\"default\"], \"firmwareVersion\": \"2.41 Mar 08 2021\", \"semanticFirmwareVersion\": \"2.41.0\", \"allowableDeviceStates\": [], \"needManualReboot\": false, \"pollingSpeedSeconds\": 30}",
    "2021-04-28T14:40:46Z-FWLoader-INFO-Number of Updates: 1",
    "2021-04-28T14:40:46Z-FWLoader-INFO-Iterate images",
    "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 5ab9f804a82b11eb8a700242c0a81003/wnc.bios-1.1.2.tar.gz",
    "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 5ab9f804a82b11eb8a700242c0a81003/wnc.bios-1.1.2.tar.gz",
    "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 53c060baa82a11eba26c0242c0a81003/controllers-1.3.317.itb",
    "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin",
    "2021-04-28T14:40:46Z-FWLoader-INFO-finished updating images ACL",
    "2021-04-28T14:40:46Z-FWLoader-INFO-removing local file: /ilo5_241.zip",
    "2021-04-28T14:40:46Z-FWLoader-INFO-*** Number of Updates: 1 ***"
  ]
}
```

A successful run will end with `*** Number of Updates: x ***`.

> **`NOTE`** The FAS loader will not overwrite image records already in FAS. `Number of Updates` will be the number of new images found in the RPM. If the number is 0, all images were already in FAS.

### Delete loader run data

(`ncn-mw#`) To delete the output from a loader run and remove it from the loader run list:

Be sure to update the example command with the actual `loaderRunID` whose output should be deleted.

```bash
cray fas loader delete dd37dd45-84ec-4bd6-b3c9-7af480048966
```

The delete command does not return anything if successful.

> **`NOTE`** The `loader delete` command does not delete any images from FAS; it only deletes the loader run saved status and removes the ID from the loader run list.
