

## Install HPC Firmware Pack from PIT or LiveCD

Copyright 2021 Hewlett Packard Enterprise Development LP

### Procedure

1. Complete the [Setup Nexus](../../install/install_csm_services.md#setup-nexus) instructions.

2. Complete the [Install HPC Firmware Pack (HFP)](Install_HPC_Firmware_Pack.md#install-hpc-firmware-pack-hfp) instructions.

3. Complete the [Validate CSM Health](../validate_csm_health.md#validate-csm-health) instructions.

4. Use the Firmware Action Service (FAS) CLI to see what firmware updates are available. See [Check for New Firmware Versions with a Dry-Run](FAS_Admin_Procedures.md#check-for-new-firmware-versions-with-a-dry-run) for more information.

    The FAS Loader job will run automatically. It takes approximately 5 minutes to run.

    FAS can now be used for firmware updates to supported hardware. Refer to the FAS documentation in [Update Firmware with FAS](Update_Firmware_with_FAS.md#update-firmware-with-fas) for how to use FAS.

### Documentation for Each Firmware Unit

Documenation for each firmware unit is alongside the firmware in the overall package. 
This documentation material should be used for manually installing firmware when not using FAS on HPE Cray EX. It it sourced from Morpheus at each update of that particular firmware unit.

├── HPE_XL675d-Gen10Plus                                               <----- Hardware type this firmware is for
│ ├── A47_2.40_02_23_2021.fwpkg                                       <----- File used for manual installation
│ ├── DOC                                                             <----- Documentation
│ │ ├── HPCM-Firmware-Flash_v2021.03.04.pdf
│ │ ├── INSTALL.txt
│ │ └── README.txt
│ └── FAS-BIOS-HPE_XL675d-Gen10Plus-2.40-1-sles15sp1.x86_64.rpm.      <----- rpm used by FAS for update

├── GB_SVR_1264UP_C17_C21
│ ├── DOC
│ │ ├── BMCFirmwareUpdate.txt
│ │ ├── Gigabyte-Shasta-Firmware-Update.pdf
│ │ ├── README.txt
│ │ ├── Relnotes_MZ32-AR0-YF_C17_F01.pdf
│ │ ├── Relnotes_MZ32-AR0-YF_C17_Rome.pdf
│ │ └── Relnotes_MZ32-AR0-YF_Naples.pdf
│ └── sh-svr-1264up-bios-21.00.00-20210325025941_8df4708.x86_64.rpm


