# Firmware Update the system with FAS

* [Prerequisites](#prerequisites)
* [Current Capabilities as of Shasta Release v1.4](#current-capabilities)
* [Order Of Operations](#order-of-operations)
* [Hardware Precedence Order](#hardware-precedence-order)
* [Next steps](#next-steps)

<a name="prerequisites"></a>
## Prerequisites

1. 001-008 have been completed; CSM has been installed and HSM is running with discovered nodes.  Firmware has been loaded into FAS as part of the CSM install
2. 009 has been applied and the NCNs are locked.
3. Identify the type and manufacturers of hardware in your system.  e.g. if you don't have Gigabytes, don't update them!

**WARNING:** Non-compute nodes (NCNs) should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. Research "*009-NCN-LOCKING*" for more information. Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.


Using the process outlined in [`255-FIRMWARE-ACTION-SERVICE-FAS.md`](../255-FIRMWARE-ACTION-SERVICE-FAS.md) follow the process to update the system.  We recommend that you use the 'recipes' listed in [`256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md`](256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md) to update each supported type.

**NOTE**: each system is different and may not have all hardware options.


<a name="current-capabilities"></a>
## Current Capabilities as of Shasta Release v1.4

The following table describes the hardware items that can have their firmware updated via FAS.

*Table 1. Upgradable Firmware Items*

| **Manufacturer** | **Type**   | **Target**                                                   | **New in Release 1.4**                     |
| ---------------- | ---------- | ------------------------------------------------------------ | ------------------------------------------ |
| Cray             | nodeBMC    | `BMC`, `Node0.BIOS`,  `Node1.BIOS`,  `Recovery`, `Node1.AccFPGA0`, `Node0.AccFPGA0` | Node1.AccFPGA0  and Node0.AccFPGA0 targets |
| Cray             | chassisBMC | `BMC`, `Recovery`                                            |                                            |
| Cray             | routerBMC  | `BMC`, `Recovery`                                            |                                            |
| Gigabyte         | nodeBMC    | `BMC`, `BIOS`                                                |                                            |
| HPE              | nodeBMC    | `iLO 5` (BMC aka `1` ), `System ROM`(BIOS aka `2`) ,`Redundant System ROM`  | `iLO 5` and `System ROM` targets |


<a name="order-of-operations"></a>
## Order Of Operations

For each item in the `Hardware Precedence Order`:

1. Complete a dry run

     2. `cray fas actions create {jsonfile}`
     2. Note the ActionID!
     3. Poll the status of the action until the action `state` is `completed`:
        1. `cray fas actions status describe {actionID} --format json`

  2. Interpret the outcome of the dryrun; look at the counts and determine if the dryrun identified any hardware to update

     For the steps below, the following returned messages will help determine if a firmware update is needed. The following are end `state`s for `operations`.  The Firmware `action` itself should be in `completed` once all operations have finished.

     *	`NoOp`: Nothing to do, already at version.
     *	`NoSol`: No viable image is available; this will not be updated.
     *	`succeeded`: 
     	*	IF `dryrun`: The operation should succeed if performed as a `live update`.  `succeeded` means that FAS identified that it COULD update an xname + target with the declared strategy. 
     	*	IF `live update`: the operation succeeded, and has updated the xname + target to the identified version.
     *	`failed`: 
     	*	IF `dryrun` : There is something that FAS could do, but it likely would fail; most likely because the file is missing. 
     	*	IF `live update` : the operation failed, the identified version could not be put on the xname + target.

3. If necessary (e.g. `succeeded` count > 0) now perform a live update

4. update the json file `overrideDryrun` to `true`

   1. `cray fas actions create {jsonfile}`
     2. Note the ActionID!
     3. Poll the status of the action until the action `state` is `completed`:
        1. `cray fas actions status describe {actionID} --format json`

5. Interpret the outcome of the live update; proceed to next type of hardware

<a name="hardware-precedence-order"></a>
## Hardware Precedence Order
After you identify which hardware you have; start with the top most item on this list to update.  If you don't have the hardware, skip it.

**IMPORTANT**: this process does not communicate the SAFE way to update NCNs. If you have not locked NCNs or blindly use FAS to update NCNs without following the correct process **YOU WILL VIOLATE THE STABILITY OF THE SYSTEM**

**IMPORTANT** : read the corresponding recipes! there are sometimes ancillary actions that must be completed in order to ensure update integrity!

1. Cray
     2. [RouterBMC](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-:-routerbmc-|--target-:-bmc)
     2. [ChassisBMC](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-:-chassisbmc-|-target:-bmc)
     4. NodeBMC
        4. [BMC](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-:-nodebmc-|-target-:-bmc)
        5. [NodeBios](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-:-nodebmc-|-target-:-nodebios)
        6. [Redstone FPGA 	](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-:-nodebmc-|-target-:-redstone-fpga) 
5. Gigabyte
	6. [BMC](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#gb-device-type-:-nodebmc-|-target-:-bmc) 
	7. [BIOS](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#gb-device-type-:-nodebmc-|-target-:-bios) 
3. HPE
     1. [BMC (iLO5)](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#hpe-device-type-:-nodebmc-|-target-:--aka-bmc)
     2. [BIOS (System ROM)](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#hpe-device-type-:-nodebmc-|-target-:--aka-bios) 


<a name="next-steps"></a>
## Next Steps

Next the administrator should install additional products following the procedures in the HPE Cray EX System Installation and Configuration Guide S-8000.

