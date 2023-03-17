# BOS Limitations for Gigabyte BMC Hardware

Special steps need to be taken when using the Boot Orchestration Service \(BOS\) to boot, reboot, or shutdown Gigabyte hardware.
Gigabyte hardware treats power off and power on requests as successful, regardless of if actually successfully completed.
The power on/off requests are ignored by Cray Advanced Platform Monitoring and Control \(CAPMC\) if they are received within a short period of time, which is typically around 60 seconds per operation.
