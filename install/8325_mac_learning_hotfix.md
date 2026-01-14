# Hotfix to workaround known `mac-learning` issue with 8325

## Issue description

**Aruba CR:** 90598

**Affected platform:** 8325

**Symptom:** MAC learning stops.

**Scenario:** Under extremely rare DMA stress conditions, an L2 learning thread may timeout and exit preventing future MAC learning.

**Workaround:** Reboot the switch or monitor the L2 thread and restart it with an NAE script.

**Fixed in:** 10.06.0130, 10.7.0010, and above.

[Aruba release notes](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches;productSeries=Aruba%208325%20Switch%20Series)

## To fix the issue without upgrading software

Run an NAE script on the 8325 platform switches to resolve MAC learning issue.

## Important information

* This NAE script creates a Bash script in `/tmp` and runs every 60 seconds
* The script writes file to storage every 60 seconds (NAE alert file)
* There are no controls over alert status
* Event log is created when a problem is detected
  * `BCML2X has quit unexpectedly, attempting to restart...`
* The error can also be found using `grep` on `/var/log/messages`
* REST API URI is `/rest/v10.04/logs/event?SYSLOG_IDENTIFIER=root&since=yesterday`
* Delete agent and script after upgrading to 10.06.0130+
* Monitor `eMMC` health if planning to run for a long time
* Command to run on 8325 switches: `show system resource | include utiliz`

## Script locations

* [NAE script](../upgrade/1.0.1/scripts/aruba/L2X-Watchdog-creates-bash-script.py)
* [Automatic NAE install script](../upgrade/1.0.1/scripts/aruba/nae_upload.py)

## Install of NAE script

After the script has been successfully installed, the Network Analytics Engine will monitor the switch and automatically fix the MAC learning issue.

### Automated install of NAE script

The automated install script will upload and enable the NAE script.

#### Prerequisites

* The `nae-upload.py` script relies on `/etc/hosts` file to pull IP addresses of the switch. Without this information the script will not run.
* An 8325 running software version below 10.06.0130.
* Script assumes default username `admin` for the switch and it will prompt for the password.

NOTE: The `nae-upload.py` script automatically detects 8325 switches and only applies the fix to this platform.

#### Procedure

1. Ensure the latest documentation RPM is installed on the NCN where this procedure is being performed.

   See [Check for latest workarounds and documentation updates](../update_product_stream/index.md#check-for-latest-workarounds-and-documentation-updates).

1. Run the install script.

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/aruba/nae_upload.py
   ```

1. When prompted, enter the switch password.

#### Known error messages

##### Incorrect password

Example output:

```text
Switch login password:
Traceback (most recent call last):
File "./nae_upload.py", line 57, in <module>
platform = system.json()
File "/usr/lib/python3.6/site-packages/requests/models.py", line 898, in json
return complexjson.loads(self.text, **kwargs)
File "/usr/lib64/python3.6/site-packages/simplejson/__init__.py", line 518, in loads
return _default_decoder.decode(s)
File "/usr/lib64/python3.6/site-packages/simplejson/decoder.py", line 373, in decode
raise JSONDecodeError("Extra data", s, end, len(s))
simplejson.errors.JSONDecodeError: Extra data: line 1 column 5 - line 1 column 27 (char 4 - 26)
```

##### Script already loaded

Example output:

```text
Switch login password:
L2X-Watchdog NAE script is already installed on sw-spine-001.
L2X-Watchdog NAE script is already installed on sw-spine-002.
```

### Manual install of the NAE script

1. Download the NAE script to a system with web access to a AOS-CX device.

   See [Script locations](#script-locations) for links to the script.

1. Log in to an AOS-CX device via the Web User Interface.

1. Navigate to the Scripts page.

   1. Click on the Analytics section on the left.

   1. Click on the Scripts button in the top, middle section.

1. On the Scripts page, click the Upload button and select the NAE script on the local system.

   This will install the NAE script to the AOS-CX device.

1. Create an agent to run the script.

   1. On the Scripts page, click the Create Agent button.

   1. When prompted, enter any name for the agent. All other values should be left as default.

   1. Click Create.

1. Confirm that the Agent is running.

   1. Navigate to the Agents page.

   1. Click on the agent created in the previous step.

   1. Confirm that it is running and no errors have been generated.
