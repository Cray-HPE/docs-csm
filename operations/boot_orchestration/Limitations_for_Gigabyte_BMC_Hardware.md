# BOS Limitations for Gigabyte BMC Hardware

> **`NOTE`** This section is for Boot Orchestration Service \(BOS\) v1 only. BOS v2 does not use
> [Cray Advanced Platform Monitoring and Control \(CAPMC\)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc).

Special steps need to be taken when using BOS to boot, reboot, or shutdown Gigabyte hardware.
Gigabyte hardware treats power off and power on requests as successful, regardless of if actually successfully completed.
The power on/off requests are ignored by CAPMC if they are received within a short period of time, which is typically around 60 seconds per operation.

The work around for customers with Gigabyte BMC hardware is to manually serialize power off events. This is done to prevent frequent power actions from being attempted and ignored by CAPMC.
From a boot orchestration perspective, this can be effectively worked around by issuing CAPMC power off commands before issuing BOS reboot commands.
