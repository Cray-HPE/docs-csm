# Firmware Action Service (FAS) Administration Guide

* [Recipes](#recipes) 
  * [Manufacturer : Cray](#manufacturer-cray)
    * [Device Type : RouterBMC |  Target : BMC](#cray-device-type-routerbmc--target-bmc) 
    * [Device Type : ChassisBMC | Target: BMC](#cray-device-type-chassisbmc-target-bmc) 
    * [Device Type : NodeBMC | Target : BMC](#cray-device-type-nodebmc-target-bmc) 
    * [Device Type : NodeBMC | Target : NodeBIOS](#cray-device-type-nodebmc-target-nodebios) 
    * [Device Type : NodeBMC | Target : Redstone FPGA](#cray-device-type-nodebmc-target-redstone-fpga) 
  * [Manufacturer : HPE](#manufacturer-hpe)
    * [Device Type : NodeBMC | Target : `iLO 5` aka BMC](#hpe-device-type-nodebmc-target--aka-bmc) 
    * [Device Type : NodeBMC | Target : `System ROM` aka BIOS](#hpe-device-type-nodebmc-target--aka-bios) 
  * [Manufacturer : Gigabyte](#manufacturer-gigabyte)
    * [Device Type : NodeBMC | Target : BMC](#gb-device-type-nodebmc-target-bmc) 
    * [Device Type : NodeBMC | Target : BIOS](#gb-device-type-nodebmc-target-bios) 
  * [Special Note: updating NCNs](#special-note-updating-ncns)

## FAS Filters for `actions` and `snapshots` 

FAS uses five primary filters to determine what operations to create. The filters are listed below:

* Selection Filters -> determine `what` operations will be created
	* `stateComponentFilter`
	* `targetFilter`
	* `inventoryHardwareFilter`
	*  ` imageFilter`
* Command Filters -> determine `how` the operations will be executed
	* `command` 	


All filters are logically connected with `AND` logic. Only the `stateComponentFilter`, `targetFilter`, and `inventoryHardwareFilter` are used for snapshots.

## Selection Filters

---

### `stateComponentFilter` 
The state component filter allows users to select hardware to update. Hardware can be selected individually with xnames, or in groups by leveraging the Hardware State Manager (HSM) groups and partitions features.

#### Parameters

1.  `xnames` - a list of xnames to target
2.  `partitions` -  a partition to target
3.  `groups`- a group to target
4.  `deviceTypes` (like NodeBMC, RouterBMC, ChassisBMC -> these are the ONLY 3 allowed types and come from HSM)

---

### `inventoryHardwareFilter` 

The inventory hardware filter takes place after the state component filter has been applied. It will remove any devices that do not conform to the identified manufacturer or models determined by querying the Redfish endpoint.

**IMPORTANT:** There can be a mismatch of hardware models. The model field is human-readable and is human-programmable. In some cases, there can be typos where the wrong model is programmed, which causes issues filtering. If this occurs, query the hardware, find the model name, and add it to the images repository on the desired image.

#### Parameters:

1. `manufacturer` - (like Cray, HPE, Gigabyte)
2. `model` - this is the Redfish reported model, you can specify this but we typically do not for the in-house updates we've done.

---

###  `imageFilter`

FAS applies images to xname/targets. The image filter is a way to specify an explicit image that should be used. When included with other filters, the image filter reduces the devices considered to only those devices where the image can be applied.

For example, if a user specifies an image that only applies to gigabyte, nodeBMCs, BIOS targets. If all hardware in the system is targeted with an empty stateComponentFilter, FAS would find all devices in the system that can be updated via Redfish, and then the image filter would remove all xname/ targets that this image could not be applied. In this example, FAS would remove any device that is not a gigabyte nodeBMC, as well as any target that is not BIOS.

#### Parameters

1. `imageID` -> this is the id of the image you want to force onto the system; 
2. `overrideImage` - if this is combined with imageID; it will FORCE the selected image onto all hardware identified, even if it is not applicable.  This may cause undesirable outcomes, but most hardware will prevent a bad image from being loaded.

---

### `targetFilter` 
The target filter selects targets that match against the list. For example, if the user specifies only the BIOS target, FAS will include only operations that explicitly have BIOS as a target.  A Redfish device has potentially many targets (members). Targets for FAS are case sensitive and must match Redfish.

#### Parameters

1. `targets` - these are the actual 'members' that will be upgraded. Examples include, but are not limited to the following: 
  * BIOS
  * BMC
  * NIC
  * Node0.BIOS
  * Node1.BIOS
  * Recovery

---

## Command Filters

---

### `command`

The command group is the most important part of an action command and controls if the action is executed as dry-run or a live update.

It also determines whether or not to override an operation that would normally not be executed if there is no way to return the xname/target to the previous firmware version. This happens if an image does not exist in the image repository.

These filters are then applied; and then `command` parameter applies settings for the overall action: The swagger is a great reference, so I will include just the standards you should most likely use.

#### Parameters

- `version` - usually `latest` because we want to upgrade usually
- `tag` - usually `default` because we only care about the default image (this can be mostly ignored)
- `overrideDryrun` - This determines if this is a LIVE UPDATE or a DRYRUN; if you override; then it will provide a live update
- `restoreNotPossibleOverride` - this determines if an update (live or dry run) will be attempted if a restore cannot be performed.  Typically we don't have enough firmrware to be able to do a rollback; that means if you UPDATE away from a particular version, we probably cannot go back to a previous version.  Given our context it is most likely that this value will ALWAYS need to be set `true` 
- `overwriteSameImage` - this will cause a firmware update to be performed EVEN if the device is already at the identified, selected version.  
- `timeLimit` - this is the amount of time in seconds that any operation should be allowed to execute.  Most `cray` stuff can be completed in about 1000 seconds or less; but the `gigabyte` stuff will commonly take 1,500 seconds or greater.   We recommend setting the value to 2000; this is just a stop gap to prevent the  operation from never ending, should something get stuck.
- `description`- this is a human friendly description; use it!


---
# <a name="recipes"></a>Recipes

Below are some example `json` files that you may find useful when updating specific hardware components.  In all of these examples the `overrideDryrun` field will be set to `false`; set them to `true` to perform a live update.  We would recommend that when updating an entire system that you walk down the device hierarchy component type by component type, starting first with 'Routers' aka switches, proceeding to Chassis, then finally Nodes.  While this is not strictly necessary we have found that it helps eliminate confusion. 

## <a name="manufacturer-cray"></a>Manufacturer : Cray

#### <a name="cray-device-type-routerbmc--target-bmc"></a>Device Type : RouterBMC |  Target : BMC

The BMC on the RouterBMC for a Cray includes the ASIC.  

```json
{
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"stateComponentFilter": {
    "deviceTypes": [
      "routerBMC"
    ]
},
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Columbia and/or Colorado router BMC"
  }
}
```

#### <a name="cray-device-type-chassisbmc-target-bmc"></a>Device Type : ChassisBMC | Target: BMC

**IMPORTANT**: Before updating a CMM, make sure all slot and rectifier power is off.
The hms-discovery job must also be stopped before updates and restarted after updates are complete:
> Stop hms-discovery job: ```kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":true}}'```
>
> Start hms-discovery job: ``` kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":false}}'```

```json
{
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"stateComponentFilter": {
    "deviceTypes": [
      "chassisBMC"
    ]
},
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Cray Chassis Controllers"
  }
}
```
#### <a name="cray-device-type-nodebmc-target-bmc"></a>Device Type : NodeBMC | Target : BMC

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Olympus node BMCs"
  }
}
```



#### <a name="cray-device-type-nodebmc-target-nodebios"></a> Device Type : NodeBMC | Target : NodeBIOS

**IMPORTANT**: The Nodes themselves must be powered **off** in order to update the BIOS on the nodes.  The BMC will still have power and will perform the update.

**IMPORTANT:** When the BMC is updated or rebooted after updating the Node0.BIOS and/or Node1.BIOS liquid-cooled nodes, the node BIOS version will not report the new version string until the nodes are powered back on. It is recommended that the Node0/1 BIOS be updated in a separate action, either before or after a BMC update and the nodes are powered back on after a BIOS update. The liquid-cooled nodes must be powered off for the BIOS to be updated.

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.BIOS",
      "Node1.BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node BIOS"
  }
}
```

> **NOTE**: If this update does not work as expected please check the workaround [257-FIRMWARE-ACTION-SERVICE-CRAY-WINDOM-COMPUTE-NODE-BIOS-WORKAROUND.md](../257-FIRMWARE-ACTION-SERVICE-CRAY-WINDOM-COMPUTE-NODE-BIOS-WORKAROUND.md).

#### <a name="cray-device-type-nodebmc-target-redstone-fpga"></a>Device Type : NodeBMC | Target : Redstone FPGA

**IMPORTANT**: The Nodes themselves must be powered **on** in order to update the firmware of the Redstone FPGA on the nodes.  

**NOTE**: If updating FPGAs fail due to "No Image available", you can update using the Override Image for Update procedure in [255-FIRMWARE-ACTIONS-SERVICE-FAS.md](../255-FIRMWARE-ACTION-SERVICE-FAS.md).  You can find the imageID using the following command: `cray fas images list --format json | jq '.[] | .[] | select(.target=="Node0.AccFPGA0")'`

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.AccFPGA0",
      "Node1.AccFPGA0"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node Redstone FPGA"
  }
}
```



---

## <a name="manufacturer-hpe"></a>Manufacturer : HPE 
####  <a name="hpe-device-type-nodebmc-target-`ilo-5`-aka-bmc"></a>Device Type : NodeBMC | Target : `iLO 5` aka BMC

```json
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "1"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node iLO 5"
  }
}
```

**NOTE**: You MUST use `1` as `target` to indicate `iLO 5`

####  <a name="hpe-device-type-nodebmc-target-`system-rom`-aka-bios"></a>Device Type : NodeBMC | Target : `System ROM` aka BIOS

**NOTE**: Node should be powered on for System ROM update and will need to be rebooted to use the updated BIOS.

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "NodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "2"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node system rom"
  }
}
```

**NOTE**: You MUST use `2` as `target` to indicate `System ROM`

**NOTE**: Because of an incorrect string in the image meta data in FAS.  Update of System ROM may report as an error when it actually succeeded.  You may have to manually check the update version.

---

## <a name="manufacturer-gigabyte"></a>Manufacturer : Gigabyte

#### <a name="gb-device-type-nodebmc-target-bmc"></a>Device Type : NodeBMC | Target : BMC

```json
{
"stateComponentFilter": {

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
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 2000,
    "description": "Dryrun upgrade of Gigabyte node BMCs"
  }
}
```

*note*: the timeLimit is `2000` because the gigabytes can take a lot longer to update. 

#### <a name="gb-device-type-nodebmc-target-bios"></a>Device Type : NodeBMC | Target : BIOS
```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 2000,
    "description": "Dryrun upgrade of Gigabyte node BIOS"
  }
}
```

## <a name="special-note-updating-ncns"></a>Special Note: updating NCNs

NCNs are compute blades; we currently only have NCNs that are manufactured by Gigabyte or HPE.  We recommend using the `NodeBMC` examples from above and including the `xname` param as part of the `stateComponentFilter` to target **ONLY** the xnames you have separately identified as an NCN.  Updating more than one NCN at a time **MAY** cause system instability. Be sure to follow the correct process for updating NCN; FAS accepts no responsibility for updates that do not follow the correct process.  Firmware updates have the capacity to harm the system; follow the appropriate guides!
