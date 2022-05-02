# FAS Filters

FAS uses five primary filters for `actions` and `snapshots` to determine what operations to create. The filters are listed below:

* Selection Filters - Determine `what` operations will be created. The following selection filters are available:
  * `stateComponentFilter`
  * `targetFilter`
  * `inventoryHardwareFilter`
  * `imageFilter`
* Command Filters - Determine `how` the operations will be executed. The following command filters are available:
  * `command`

All filters are logically connected with `AND` logic. Only the `stateComponentFilter`, `targetFilter`, and `inventoryHardwareFilter` are used for snapshots.

---

## Selection Filters

### `stateComponentFilter`

The state component filter allows users to select hardware to update. Hardware can be selected individually with component names (xnames), or in groups by leveraging the Hardware State Manager (HSM) groups and partitions features.

#### Parameters

* `xnames` - A list of component names (xnames) to target.
* `partitions` - A partition to target.
* `groups`- A group to target.
* `deviceTypes` Set to NodeBMC, RouterBMC, or ChassisBMC. These are the ONLY three allowed types and come from the Hardware State Manager (HSM).

---

### `inventoryHardwareFilter`

The inventory hardware filter takes place after the state component filter has been applied. It will remove any devices that do not conform to the identified manufacturer or models determined by querying the Redfish endpoint.

> **IMPORTANT:** There can be a mismatch of hardware models. The model field is human-readable and is human-programmable. In some cases, there can be typos where the wrong model is programmed, which causes issues filtering. If this occurs, query the hardware, find the model name, and add it to the images repository on the desired image.

#### Parameters

* `manufacturer` - Set to `Cray`, `HPE`, or `Gigabyte`.
* `model` - The Redfish reported model, which can be specified.

---

### `imageFilter`

FAS applies images to component name (xname)/targets. The image filter is a way to specify an explicit image that should be used. When included with other filters, the image filter reduces the devices considered to only those devices where the image can be applied.

For example, consider if a user specifies an image that only applies to Gigabyte nodeBMC BIOS targets. If all hardware in the system is targeted with an empty stateComponentFilter, FAS would find all devices in the system that can be updated via Redfish, and then the image filter would remove all component name (xname)/ targets that this image could not be applied to. In this example, FAS would remove any device that is not a Gigabyte nodeBMC, as well as any target that is not BIOS.

#### Parameters

* `imageID` - The ID of the image to force onto the system.
* `overrideImage` - If this is combined with `imageID`, then it will FORCE the selected image onto all hardware identified, even if it is not applicable.
  > **WARNING:** This may cause undesirable outcomes, but most hardware will prevent a bad image from being loaded.

---

### `targetFilter`

The target filter selects targets that match against the list. For example, if the user specifies only the BIOS target, FAS will include only operations that explicitly have BIOS as a target. A Redfish device has potentially many targets (members). Targets for FAS are case sensitive and must match Redfish.

#### Parameters

* `targets` - The actual 'members' that will be upgraded. Examples include, but are not limited to the following:
  * BIOS
  * BMC
  * NIC
  * Node0.BIOS
  * Node1.BIOS
  * Recovery

---

## Command Filters

### `command`

The command group is the most important part of an action command and controls if the action is executed as dry-run or a live update.

It also determines whether or not to override an operation that would normally not be executed if there is no way to return the component name (xname)/target to the previous firmware version. This happens if an image does not exist in the image repository.

These filters are then applied; and then `command` parameter applies settings for the overall action. The swagger file is a great reference.

#### Parameters

* `version` - Usually `latest` because that is the most common use case.
* `tag` - Usually `default` because the default image is the most useful one to use. This parameter can usually be ignored.
* `overrideDryrun` - This determines if this is a LIVE UPDATE or a DRY-RUN. If doing an override; then it will provide a live update.
* `restoreNotPossibleOverride` - This determines if an update (live or dry-run) will be attempted if a restore cannot be performed. Typically there is not enough firmware to be able to do a rollback, which means if the system is an UPDATE away from a particular version, it cannot go back to a previous version. It is most likely that this value will ALWAYS need to be set `true`.
* `overwriteSameImage` - This will cause a firmware update to be performed EVEN if the device is already at the identified, selected version.
* `timeLimit` - This is the amount of time in seconds that any operation should be allowed to execute. Most `cray` hardware can be completed in approximately 1000 seconds or less; but the `gigabyte` hardware will commonly take 1500 seconds or greater. Setting the value to 4000 is recommended as a stop gap to prevent the operation from never ending, should something get stuck.
* `description`- A human-friendly description that should be set to give useful information about the firmware operation.
