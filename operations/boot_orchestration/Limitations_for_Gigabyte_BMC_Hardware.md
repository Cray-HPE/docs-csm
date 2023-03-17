# BOS Limitations for Gigabyte BMC Hardware

> **`NOTE`** This section is for BOS V1 only. BOS V2 does not use CAPMC.

Special steps need to be taken when using the Boot Orchestration Service \(BOS\) to boot, reboot, or shutdown Gigabyte hardware.
Gigabyte hardware treats power off and power on requests as successful, regardless of if actually successfully completed.
The power on/off requests are ignored by Cray Advanced Platform Monitoring and Control \(CAPMC\) if they are received within a short period of time, which is typically around 60 seconds per operation.

The work around for customers with Gigabyte BMC hardware is to manually serialize power off events. This is done to prevent frequent power actions from being attempted and ignored by CAPMC.
From a boot orchestration perspective, this can be effectively worked around by issuing CAPMC power off commands before issuing BOS reboot commands.
