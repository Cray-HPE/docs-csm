# Performing upgrade on Mellanox switches

To perform an automatic firmware update by the OS for a different switch firmware version without changing the OS version, import the firmware package as described below. The OS sets it as the new default firmware and performs the firmware update automatically as described in the previous subsections.

Example

Default Firmware Change on Standalone Systems

1.	Import the firmware image (.mfa file). Run: 
switch (config) # image fetch scp://root@1.1.1.1:/tmp/fw-SIB-rel-11_1600_0200-FIT.mfa

2.	Password (if required): *******

3.	switch (config) # image default-chip-fw fw-SIB-rel-11_1600_0200-FIT.mfa

4.	Installing default firmware image. Please wait...
Default Firmware 11.1600.0200 updated. Please save configuration and reboot for new FW to take effect.
5.	Save the configuration. Run: 
switch (config) # configuration write
6.	Reboot the system to enable auto update.

[Back to Index](./index.md)

