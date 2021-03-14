# FIRMWARE ACTION SERVICE (FAS) | User Procedures

## Prerequisites
The Cray command line interface (CLI) tool is initialized and configured on the system. See "Configure the Cray Command Line Interface (CLI)" in the HPE Cray EX System Administration Guide S-8001 for more information.

> **`IMPORTANT`** It may be necessary to explicitly set the power state of certain devices before performing a given firmware update. Refer to ()[] in order to understand the process for setting power state and controlling relevant settings.

##  <a name="action"></a>Execute an Action

### Objective
Use the Firmware Action Service (FAS) to execute an action.  An action produces a  set of firmware operations. Each operation represents an xname + target on that xname that will be targeted for update.  There are two of firmware action modes: : `dryrun` or `liveupdate`; the parameters used when creating either are completely identical except for the `overrideDryrun` setting. `overrideDryrun` will determine if feature to determine what firmware can be updated on the system. Dry-runs are enabled by default, and can be configured with the `overrideDryrun` parameter. A dry-run will create a query according to the filters requested by the admin. It will initiate an update sequence to determine what firmware is available, but will not actually change the state of the firmware

**WARNING**: It is crucial that an admin is familiar with the release notes of any firmware. The release notes will indicate what new features the firmware provides and if there are any incompatibilities. FAS does not know about incompatibilities or dependencies between versions. The admin assumes full responsibility for this knowledge.

**WARNING**: It is likely that when performing a firmware update, that the current version of firmware will not be available. This means that after successfully upgrading, the firmware cannot be reverted (i.e. downgraded to previous version).

### Steps
This will cover the generic process for executing an action.  For more specific examples and detailed explanations of options see the `recipes.md` file.

1. Identify the selection of filters you want to apply.  Filters narrow the scope of FAS to target specific xnames, manufacturers, targets, etc. For our purpose we will run FAS 'wide open', with no selection filters applied.

2. create a json file {whole-system-dryrun.json}; to make this a `live update` set `"overrideDryrun": true`

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

3. execute the dryrun 

```bash
# cray fas actions create {whole-system-dryrun.json}
...
{
	"actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
	"overrideDryrun": false
}
```
Note the returned `actionID`

See 'interpreting an Action' for more information.

## <a name="abort"></a>Abort an Action

### Objective
Firmware updates can be stopped if required. This is useful given only one action can be run at a time. This is to protect hardware from multiple actions trying to modify it at the same time.

**IMPORTANT**: If a Redfish update is already in progress, the abort will not stop that process on the device. It is likely the device will update. If the device needs to be manually power cycled (`needManualReboot`), it is possible that the device will update, but not actually apply the update until its next reboot. Admins must verify the state of the system after an abort. Only perform an abort if truly necessary. The best way to check the state of the system is to do a snapshot or do a dry-run of an update.

### Steps

1. Issue the abort command to the action

```bash
# cray fas actions instance delete {actionID}
```
**Note**: The action could take up to a minute to fully abort.

## <a name="describe-action"></a>Describe an Action

### Objective
There are several ways to get more information about a firmware update. An `actionID` and `operationID`s are generated when an live update or dry-run is created. These values can be used to learn more about what is happening on the system during an update.

### Interpreting Output

For the steps below, the following returned messages will help determine if a firmware update is needed. The following are end `state`s for `operations`.  The Firmware `action` itself should be in `completed` once all operations have finished.

*	`NoOp`: Nothing to do, already at version.
*	`NoSol`: No viable image is available; this will not be updated.
*	`succeeded`: 
	*	IF `dryrun`: The operation should succeed if performed as a `live update`.  `succeeded` means that FAS identified that it COULD update an xname + target with the declared strategy. 
	*	IF `live update`: the operation succeeded, and has updated the xname + target to the identified version.
*	`failed`: 
	*	IF `dryrun` : There is something that FAS could do, but it likely would fail; most likely because the file is missing. 
	*	IF `live update` : the operation failed, the identified version could not be put on the xname + target.

Data can be viewed at several levels of information:

### Steps

#### Get High Level Summary

To view counts of operations, what state they are in, the overall state of the action, and what parameters were used to create the action:

```toml
# cray fas actions status describe {actionID}
blockedBy = []
state = "completed"
actionID = "0a305f36-6d89-4cf8-b4a1-b9f199afaf3b" startTime = "2020-06-23 15:43:42.939100799 +0000 UTC"
snapshotID = "00000000-0000-0000-0000-000000000000"
endTime = "2020-06-23 15:48:59.586748151 +0000 UTC"

[actions.command]
description = "upgrade of x9000c1s3b1 Nodex.BIOS to WNC 1.1.2" tag = "default"
restoreNotPossibleOverride = true timeLimit = 1000
version = "latest" overrideDryrun = false [actions.operationCounts] noOperation = 0
succeeded = 2
verifying = 0
unknown = 0
configured = 0
initial = 0
failed = 0
noSolution = 0
aborted = 0
needsVerified = 0
total = 2
inProgress = 0
blocked = 0 [[actions]] blockedBy = [] state = "completed"
actionID = "0b9300d6-8f06-4019-a8fa-7b3ff65e5aa8" startTime = "2020-06-18 03:06:25.694573366 +0000 UTC"
snapshotID = "00000000-0000-0000-0000-000000000000"
endTime = "2020-06-18 03:11:06.806297546 +0000 UTC"

```

**NOTE** : unless the action's `state` is `completed` or `aborted`; then this action is still under progress. 

#### Get Details of Action


```
# cray fas actions describe {actionID} --format json
{
  "parameters": {
    "stateComponentFilter": {
      "deviceTypes": [
        "routerBMC"
      ]
    },
    "command": {
      "dryrun": false,
      "description": "upgrade of routerBMCs for cray",
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
    "description": "upgrade of routerBMCs for cray",
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


#### Get Details of Operation

Using the `operationID` listed in the actions array we can see the full detail of the operation.

```bash
# cray fas operations describe operationID --format json
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

