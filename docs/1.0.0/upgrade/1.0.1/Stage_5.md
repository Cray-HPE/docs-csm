# Stage 5 - Workaround for MAC-learning issue with Aruba 8325 switches

Issue description:

> **Aruba CR:**          90598
>
> **Affected platform:** Aruba 8325 switches
>
> **Symptom:**           MAC learning stops
>
> **Scenario:**          Under extremely rare DMA stress conditions, an L2 learning thread may timeout and exit, preventing future MAC learning
>
> **Workaround:**        Reboot the switch or monitor the L2 thread and restart it with an NAE script
>
> **Fixed in:**        10.06.0130, 10.7.0010, and above
>
> [Aruba release notes](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches;productSeries=Aruba%208325%20Switch%20Series)

## Overview

**`NOTE:`** If you do not have Aruba 8325 switches in your system, skip this stage and [return to main upgrade page](README.md).

You can run the NAE script on the 8325 platform switches to resolve a MAC learning issue. An install script is provided to automate this process.

The file locations:
* NAE script: [scripts/aruba/L2X-Watchdog-creates-bash-script.py](scripts/aruba/L2X-Watchdog-creates-bash-script.py)
* Automatic NAE install script: [scripts/aruba/nae_upload.py](scripts/aruba/nae_upload.py)

## Prerequisites

* You have an 8325 in your setup that is running software version below 10.06.0130.
* Additionally, the install script used in this procedure makes the following assumptions:
	* The switches (and their IP addresses) are in the `/etc/hosts` file with hostnames containing the string "sw".
	* You are using default username `admin` for the switches.
	* All of the switches use the same password for the `admin` user (the install script will prompt you for the password).

## Procedure

>**`IMPORTANT:`**
>
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

1. Run the NAE install script:

	```bash
	ncn-m002# /usr/share/doc/csm/upgrade/1.0.1/scripts/aruba/nae_upload.py
	```

1. Type in your switch password and the script will upload and enable the NAE script.

[Return to main upgrade page](README.md)
