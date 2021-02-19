# Firmware Update the sytem with FAS

## Prerequisites

1. 001-008 have been completed; CSM has been installed and HSM is running with discovered nodes.  Firmware has been loaded into FAS as part of the CSM install
2. 009 has been applied and the NCNs are locked.

**WARNING:** Non-compute nodes (NCNs) should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. Research "*009-NCN-LOCKING*" for more information. Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.


Using the process outlined in `255-FIRMWARE-ACTION-SERVICE-FAS.md` follow the process to update the system.  We recommend that you use the 'recipies' listed in `256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md` to update each supported type.

**NOTE**: each system is different and may not have all hardware options.


## Current Capabilities as of Shasta Release v1.4

The following table describes the hardware items that can have their firmware updated via FAS.

*Table 1. Upgradable Firmware Items*

| **Manufacturer** | **Type**   | **Target**                                                   | **New in Release 1.4**                     |
| ---------------- | ---------- | ------------------------------------------------------------ | ------------------------------------------ |
| Cray             | nodeBMC    | `BMC`, `Node0.BIOS`,  `Node1.BIOS`,  `Recovery`, `Node1.AccFPGA0`, `Node0.AccFPGA0` | Node1.AccFPGA0  and Node0.AccFPGA0 targets |
| Cray             | chassisBMC | `BMC`, `Recovery`                                            |                                            |
| Cray             | routerBMC  | `BMC`, `Recovery`                                            |                                            |
| Gigabyte         | nodeBMC    | `BMC`, `BIOS`                                                |                                            |
| HPE              | nodeBMC    | `iLO 5` (BMC aka `1` ), `System ROM` ,`Redundant System ROM` (BIOS aka `2`) | `iLO 5` and `System ROM` targets 