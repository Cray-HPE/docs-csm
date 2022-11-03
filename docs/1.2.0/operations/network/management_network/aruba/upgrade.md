# Perform a VSX Upgrade on Aruba Switches

The `vsx update-software` command is used to update the switch software with minimal to no downtime.
This command gives administrators the option to save the running configuration on the primary and secondary VSX switches.
After the command saves the running configuration, it downloads new software from the TFTP server and verifies the download.
After a successful verification, the command installs the software to the alternative image of both the VSX primary and secondary switches.

The command displays the status of the VSX primary and secondary switches during the upgrade.
The command also refreshes the progress bar as the image update progresses.
Do not interrupt the VSX primary CLI session until the software updates completes; however, software update process can be stopped.

If you stop the upgrade when the secondary switch has already installed the image in its flash memory or the secondary switch has started the reboot the process, it comes up with the new software.

The primary switch continues to have with older software. Administrators can stop the software update process by pressing **`ctrl+c`**.

## Prerequisites

* Choose the method to upload the new software to the switches:
  * Via USB
  * Via WEB UI
  * Via TFTP or SFTP

> **NOTE:** If you do not want to proceed with pre-staging you can also upload the new software directly using `vsx update-software` command. However, you will be limited to only using TFTP if you choose not to pre-stage the firmware.

## VSX Upgrade Command

The `vsx update-software` command is used to update the switch software. The following describes the syntax and parameters of the command.

### Syntax

```text
vsx update-software <REMOTE-URL> [vrf <VRF-NAME>]
```

### Parameters

```text
<REMOTE-URL>
```

Specifies the TFTP URL for downloading the software.

```text
vrf <VRF-NAME>
```

(Optional) Specifies the VRF name for downloading the software.

## Example of Updating Software via TFTP

> **NOTE:** If the new software is already pre-staged, call the image bank where the new image is located instead of using the TFTP.

```text
switch# vsx update-software tftp://192.168.1.1/XL.10.0x.xxxx vrf mgmt
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

[Back to Index](../index.md)
