# Stage 4 - Upgrade Aruba switches to 10.08.1021

As part of the CSM 1.2 you need to upgrade Aruba switches to 10.08.1021.

After this change the NAE script to address Mac learning issue with 8325 is no longer required and needs to be deleted from the system. 

### Automated removal of NAE script

#### Prerequisites:

1. The nae_remove.py script relies on /etc/hosts file to pull IP addresses of the switch. Without this information the script won’t run.
2. You have 8325 in your setup that is running software version 10.08.1021
3. Script assumes you  are using default username "admin"  for the switch and it will prompt you for password.

NOTE: 	The nae_remover script automatically detects 8325’s and only applies the fix to this platform.

#### How to run the install script:

**Step 1:**
```
ncn-m002:~ # /usr/share/doc/csm/upgrade/1.2/scripts/aruba/nae_remove.py
```

**step 2:**

> Type in your switch password and the script will upload and enable the NAE script.

## Upgrading software

### Pre-requisites

* Choose which way you want to upload the new software to the switches.
	* Via USB
	* Via WEB UI
	* Via TFTP or SFTP

NOTE: if you do not want to proceed with pre-staging you can also upload the new software directly using ‘vsx update-software’ command, however you will be limited to only using TFTP if you choose not to pre-stage the firmware.

NOTE 2: VSX update-software is only available in VSX paired switches, for example 6300 would not have this upgrade option. 

### Upgrading with VSX update-software: 

```
switch# vsx update-software tftp://192.168.1.1/ArubaOS-CX_8325_10_08_1021.swi 
Do you want to save the current configuration (y/n)? y
The running configuration was saved to the startup configuration.

This command will download new software to the %s image of both the VSX primary and secondary systems,
then reboot them in sequence. The VSX secondary will reboot first, followed by the primary.
Continue (y/n)? y
VSX Primary Software Update Status     : <VSX primary software update status>
VSX Secondary Software Update Status   : <VSX secondary software update status>
VSX ISL Status                         : <VSX ISL status>
Progress [..........................................................................................]
Secondary VSX system updated completely. Rebooting primary.
```

### Upgrading without VSX software 

```
switch# copy tftp://192.168.1.1/ArubaOS-CX_6400-6300_10_08_1021.swi secondary
switch# boot system secondary
```

[Return to main upgrade page](README.md)
