# Update Firmware with FAS

The Firmware Action Service (FAS) provides an interface for managing firmware versions of Redfish-enabled hardware in the system. FAS interacts with the Hardware State Managers (HSM), device data, and image data in order to update firmware.

Reset Gigabyte node BMC to factory defaults if having problems with ipmitool, using Redfish, or when flashing procedures fail. See [Set Gigabyte Node BMC to Factory Defaults](../../install/set_gigabyte_node_bmc_to_factory_defaults.md).

FAS images contain the following information that is needed for a hardware device to update firmware versions:

* Hardware-specific information: Contains the allowed device states and how to reboot a device if necessary.
* Selection criteria: How to link a firmware image to a specific hardware type.
* Image data: Where the firmware image resides in Simple Storage Service (S3) and what firmwareVersion it will report after it is successfully applied. See [Artifact Management](../artifact_management/Artifact_Management.md) for more information.

## Topics

   * [Prerequisites](#prerequisites)
   * [Warning](#warning)
   * [Current Capabilities](#current-capabilities)
   * [Order Of Operations](#order-of-operations)
   * [Hardware Precedence Order](#hardware-precedence-order)
   * [FAS Admin Procedures](#fas-admin-procedures)
   * [Firmware Actions](#firmware-actions)
   * [Firmware Operations](#firmware-operations)
   * [Firmware Images](#firmware-images)

<a name="prerequisites"></a>

## Prerequisites

1. CSM software has been installed, firmware has been loaded into FAS as part of the HPC Firmware Pack (HFP) install, HSM is running, and nodes have been discovered.
2. All management nodes have been locked.
3. Identify the type and manufacturers of hardware in the system. If Gigabyte nodes are not in use on the system, do not update them!

<a name="warning"></a>

## Warning

Non-compute nodes (NCNs) and their BMCs should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information. Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.

Follow the process outlined in [FAS CLI](FAS_CLI.md) to update the system. Use the recipes listed in [FAS Recipes](FAS_Recipes.md) to update each supported type.

> **NOTE:** Each system is different and may not have all hardware options.

<a name="current-capabilities"></a>

## Current Capabilities

The following table describes the hardware items that can have their firmware updated via FAS. For more information about the upgradable targets, refer to the Firmware product stream repository.

*Table 1. Upgradable Firmware Items*

| **Manufacturer** | **Type**   | **Target**                                                   |
| ---------------- | ---------- | ------------------------------------------------------------ |
| Cray             | nodeBMC    | `BMC`, `Node0.BIOS`,  `Node1.BIOS`,  `Recovery`, `Node1.AccFPGA0`, `Node0.AccFPGA0` |
| Cray             | chassisBMC | `BMC`, `Recovery`                                            |
| Cray             | routerBMC  | `BMC`, `Recovery`                                            |
| Gigabyte         | nodeBMC    | `BMC`, `BIOS`                                                |
| HPE              | nodeBMC    | `iLO 5` (BMC aka `1` ), `System ROM` ,`Redundant System ROM` (BIOS aka `2`) |

<a name="order-of-operations"></a>

## Order Of Operations

For each item in the `Hardware Precedence Order`:

1. Complete a dry-run:

   1. `cray fas actions create {jsonfile}`
   2. Note the `ActionID`.
   3. Poll the status of the action until the action `state` is `completed`:
      1. `cray fas actions describe {actionID} --format json`

2. Interpret the outcome of the dry-run. Look at the counts and determine if the dry-run identified any hardware to update:

   For the steps below, the following returned messages will help determine if a firmware update is needed. The following are end `state`s for `operations`. The Firmware `action` itself should be in `completed` once all operations have finished.

   * `NoOp`: Nothing to do; already at the requested version.
   * `NoSol`: No viable image is available; this will not be updated.
   * `succeeded`:
      * IF `dryrun`: The operation should succeed if performed as a `live update`. `succeeded` means that FAS identified that it COULD update a component name (xname) and target with the declared strategy.
      * IF `live update`: The operation succeeded and has updated the component name (xname) and target to the identified version.
   * `failed`:
      * IF `dryrun`: There is something that FAS could do, but it likely would fail (most likely because the file is missing).
      * IF `live update`: The operation failed. The identified version could not be put on the component name (xname) and target.

3. If `succeeded` count > 0, now perform a live update.

4. Update the JSON file `overrideDryrun` to `true`:

   1. `cray fas actions create {jsonfile}`
     1. Note the ActionID!
     2. Poll the status of the action until the action `state` is `completed`:
        1. `cray fas actions describe {actionID} --format json`

5. Interpret the outcome of the live update; proceed to next type of hardware.

<a name="hardware-precedence-order"></a>

## Hardware Precedence Order

After identifying which hardware is in the system, start with the top most item on this list to update. If any of the following hardware is not in the system, skip it.

>**IMPORTANT:**
>* This process does not communicate the SAFE way to update NCNs. If the NCNs and their BMCs have not been locked, or FAS is blindly used to update NCNs without following the correct process, then **THE STABILITY OF THE SYSTEM WILL BE JEOPARDIZED**.
>* Read the corresponding recipes before updating. There are sometimes ancillary actions that must be completed in order to ensure update integrity.

> **NOTE:** To update Switch Controllers \(sC\) or RouterBMC, refer to the Rosetta Documentation.

1. [Cray](FAS_Recipes.md#manufacturer-cray)
   1. [ChassisBMC](FAS_Recipes.md#cray-device-type-chassisbmc-target-bmc)
   2. NodeBMC
      1. [BMC](FAS_Recipes.md#cray-device-type-nodebmc-target-bmc)
      2. [NodeBIOS](FAS_Recipes.md#cray-device-type-nodebmc-target-nodebios)
      3. [Redstone FPGA](FAS_Recipes.md#cray-device-type-nodebmc-target-redstone-fpga)
2. [Gigabyte](FAS_Recipes.md#manufacturer-gigabyte)
   1. [BMC](FAS_Recipes.md#gb-device-type-nodebmc-target-bmc)
   2. [BIOS](FAS_Recipes.md#gb-device-type-nodebmc-target-bios)
3. [HPE](FAS_Recipes.md#manufacturer-hpe)
   1. [BMC (iLO5)](FAS_Recipes.md#hpe-device-type-nodebmc-target--aka-bmc)
   2. [BIOS (System ROM)](FAS_Recipes.md#hpe-device-type-nodebmc-target--aka-bios)


<a name="fas-admin-procedures"></a>

## FAS Admin Procedures

There are several use cases for using the FAS to update firmware on the system. These use cases are intended to be run by system administrators with a good understanding of firmware. Under no circumstances should non-administrator users attempt to use FAS or perform a firmware update.

* Perform a firmware update: Update the firmware of a component name (xname)'s target to the latest, earliest, or an explicit version.
* Determine what hardware can be updated by performing a dry-run: This is the easiest way to determine what can be updated.
* Take a snapshot of the system: Record the firmware versions present on each target for the identified component names (xnames). If the firmware version corresponds to an image available in the images repository, link the `imageID` to the record.
* Restore the snapshot of the system: Take the previously recorded snapshot and use the related `imageIDs` to put the component name (xname)/targets back to the firmware version they were at, at the time of the snapshot.
* Provide firmware for updating: FAS can only update a component name (xname)/target if it has an image record that is applicable. Most administrators will not encounter this use case.

<a name="firmware-actions"></a>

## Firmware Actions

An action is collection of operations, which are individual firmware update tasks. Only one FAS action can be run at a time. Any other attempted action will be queued. Additionally, only one operation can be run on a component name (xname) at a time. For example, if there are 1000 component names (xnames) with 5 targets each to be updated, all 1000 component names (xnames) can be updating a target, but only 1 target on each component name (xname) will be updated at a time.

The life cycle of any action can be divided into the static and dynamic portions of the life cycle.

The static portion of the life cycle is where the action is created and configured. It begins with a request to create an action through either of the following requests:

* Direct: Request to `/actions` API.
* Indirect: Request to restore a snapshot via the `/snapshots` API.

The dynamic portion of the life cycle is where the action is executed to completion. It begins when the actions is transitioned from the `new` to `configured` state. The action will then be ultimately transitioned to an end state of `aborted` or `completed`.

<a name="firmware-operations"></a>

## Firmware Operations

Operations are individual tasks in a FAS action.
FAS will create operations based on the configuration sent through the `actions create` command.
FAS operations will have one of the following states:

* `initial` - Operation just created.
* `configured` - The operation is configured, but nothing has been started.
* `blocked` - Only one operation can be performed on a node at a time. If more than one update is required for a component name (xname), then operations will be blocked. This will have a message of `blocked by sibling`.
* `inProgress` - Update is in progress, but not completed.
* `verifying` - Waiting for update to complete.
* `failed` - An update was attempted, but FAS is unable to tell that the update succeeded in the allotted time.
* `noOperation` - Firmware is at the correct version according to the images loaded into FAS.
* `noSolution` - FAS does not have a suitable image for an update.
* `aborted` - The operation was aborted before it could determine if it was successful. If aborted after the update command was sent to the node, then the node may still have updated.

<a name="firmware-images"></a>

## Firmware Images

FAS requires images in order to update firmware for any device on the system. An image contains the data that allows FAS to establish a link between an admin command, available devices \(xname/targets\), and available firmware.

The following is an example of an image:

```bash
{
  "imageID": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "createTime": "2020-05-11T17:11:07.017Z",
  "deviceType": "nodeBMC",
  "manufacturer": "intel",
  "model": ["s2600","s2600_REV_a"],
  "target": "BIOS",
  "tag": ["recovery", default"],
  "firmwareVersion": "f1.123.24xz",
  "semanticFirmwareVersion": "v1.2.252",
  "updateURI": "/redfish/v1/Systems/UpdateService/BIOS",
  "needManualReboot": true,
  "waitTimeBeforeManualRebootSeconds": 600,
  "waitTimeAfterRebootSeconds": 180,
  "pollingSpeedSeconds": 30,
  "forceResetType": "ForceRestart",
  "s3URL": "s3://firmware/f1.1123.24.xz.iso",
  "allowableDeviceStates": [
    "On",
    "Off"
  ]
}
```

The main components of an image are described below:

* **Key**

  This includes the `deviceType`, `manufacturer`, `model`, `target`, `tag`, `semanticFirmwareVersion` \(firmware version\) fields.

  These fields are how administrators assess what firmware is on a device, and if an image is applicable to that device.

* **Process guides**

  This includes the `forceResetType`, `pollingSpeedSeconds`, `waitTime(s)`, `allowableDeviceStates` fields.

  FAS gets information about how to update the firmware from these fields. These values determine if FAS is responsible for rebooting the device, and what communication pattern to use.

* **`s3URL`**

  The URL that FAS uses to get the firmware binary and the download link that is supplied to Redfish devices. Redfish devices are not able to directly communicate with S3.
