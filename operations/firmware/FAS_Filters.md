## FAS Filters

FAS uses five primary filters for `actions` and `snapshots` to determine what operations to create. The filters are listed below:

* Selection Filters -> determine `what` operations will be created
	* `stateComponentFilter`
	* `targetFilter`
	* `inventoryHardwareFilter`
	*  ` imageFilter`
* Command Filters -> determine `how` the operations will be executed
	* `command` 	


All filters are logically connected with `AND` logic. Only the `stateComponentFilter`, `targetFilter`, and `inventoryHardwareFilter` are used for snapshots.

---

### Selection Filters

---

#### `stateComponentFilter` 
The state component filter allows users to select hardware to update. Hardware can be selected individually with xnames, or in groups by leveraging the Hardware State Manager (HSM) groups and partitions features.

##### Parameters

1.  `xnames` - a list of xnames to target
2.  `partitions` -  a partition to target
3.  `groups`- a group to target
4.  `deviceTypes` (like NodeBMC, RouterBMC, ChassisBMC -> these are the ONLY 3 allowed types and come from HSM)

---

#### `inventoryHardwareFilter` 

The inventory hardware filter takes place after the state component filter has been applied. It will remove any devices that do not conform to the identified manufacturer or models determined by querying the Redfish endpoint.

**IMPORTANT:** There can be a mismatch of hardware models. The model field is human-readable and is human-programmable. In some cases, there can be typos where the wrong model is programmed, which causes issues filtering. If this occurs, query the hardware, find the model name, and add it to the images repository on the desired image.

##### Parameters:

1. `manufacturer` - (like Cray, HPE, Gigabyte)
2. `model` - this is the Redfish reported model, you can specify this but we typically do not for the in-house updates we've done.

---

####  `imageFilter`

FAS applies images to xname/targets. The image filter is a way to specify an explicit image that should be used. When included with other filters, the image filter reduces the devices considered to only those devices where the image can be applied.

For example, if a user specifies an image that only applies to gigabyte, nodeBMCs, BIOS targets. If all hardware in the system is targeted with an empty stateComponentFilter, FAS would find all devices in the system that can be updated via Redfish, and then the image filter would remove all xname/ targets that this image could not be applied. In this example, FAS would remove any device that is not a gigabyte nodeBMC, as well as any target that is not BIOS.

##### Parameters

1. `imageID` -> this is the id of the image you want to force onto the system; 
2. `overrideImage` - if this is combined with imageID; it will FORCE the selected image onto all hardware identified, even if it is not applicable.  This may cause undesirable outcomes, but most hardware will prevent a bad image from being loaded.

---

#### `targetFilter` 
The target filter selects targets that match against the list. For example, if the user specifies only the BIOS target, FAS will include only operations that explicitly have BIOS as a target.  A Redfish device has potentially many targets (members). Targets for FAS are case sensitive and must match Redfish.

##### Parameters

1. `targets` - these are the actual 'members' that will be upgraded. Examples include, but are not limited to the following: 
  * BIOS
  * BMC
  * NIC
  * Node0.BIOS
  * Node1.BIOS
  * Recovery

---

### Command Filters

---

#### `command`

The command group is the most important part of an action command and controls if the action is executed as dry-run or a live update.

It also determines whether or not to override an operation that would normally not be executed if there is no way to return the xname/target to the previous firmware version. This happens if an image does not exist in the image repository.

These filters are then applied; and then `command` parameter applies settings for the overall action: The swagger is a great reference, so I will include just the standards you should most likely use.

##### Parameters

- `version` - usually `latest` because we want to upgrade usually
- `tag` - usually `default` because we only care about the default image (this can be mostly ignored)
- `overrideDryrun` - This determines if this is a LIVE UPDATE or a DRYRUN; if you override; then it will provide a live update
- `restoreNotPossibleOverride` - this determines if an update (live or dry run) will be attempted if a restore cannot be performed.  Typically we dont have engough firmrware to be able to do a rollback; that means if you UPDATE away from a particular version, we probably cannot go back to a previous version.  Given our context it is most likely that this value will ALWAYS need to be set `true` 
- `overwriteSameImage` - this will cause a firmware update to be performed EVEN if the device is already at the identified, selected version.  
- `timeLimit` - this is the amount of time in seconds that any operation should be allowed to execute.  Most `cray` stuff can be completed in ~1000 seconds or less; but the `gigabyte` stuff will comonly take 1,500 seconds or greater.   We recommend setting the value to 2000; this is just a stop gap to prevent the  operation from never ending, should something get stuck.
- `description`- this is a human friendly description; use it!

