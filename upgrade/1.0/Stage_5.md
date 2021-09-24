# Stage 5 - Workaround for known mac-learning issue with 8325.

Issue description:

> **Aruba CR:**          90598
>
> **Affected platform:** 8325
>
>**Symptom:**           MAC learning stops.
>
>**Scenario:**          Under extremely rare DMA stress conditions, anL2 learning threadmay     timeout and exit preventing future MAC learning.
>
>**Workaround:**        Reboot the switch or monitor the L2 thread and restart it with anNAE     script
>
>**Fixed in:**        10.06.0130, 10.7.0010 and above.
>
> [Aruba release notes](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches;productSeries=Aruba%208325%20Switch%20Series)

`To fix the issue without upgrading software:`

 > You can run a NAE script on the 8325 platform switches to resolve mac learning issue.

`The file locations in doc-csm`

- The NAE script (L2X-Watchdog-creates-bash-script.py) is located at: ../docs-csm/upgrade/1.0/    scripts/aruba
- Automatic NAE install script (nae_upload.py) is located at: ../docs-csm/upgrade/1.0/scripts/aruba

`Automated install of NAE script`

Prerequisites:

1. The nae-upload.py script relies on /etc/hosts file to pull IP addresses of the switch. Without this information the script will not run.
2. You have 8325 in your setup that is running software version below 10.06.0130.
3. Script assumes you  are using default username "admin"  for the switch and it will prompt you for password.

**`NOTE:`** The nae-upload script automatically detects 8325's and only applies the fix to this platform.

**How to run the install script:**

**Step 1:**

```bash
ncn-m002:~ # /usr/share/doc/csm/upgrade/1.0/scripts/aruba/nae_upload.py
```

**step 2:**

> Type in your switch password and the script will upload and enable the NAE script.

[Return to main upgrade page](README.md)