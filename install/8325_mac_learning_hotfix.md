# Hotfix to workaround known mac-learning issue with 8325


## Issue description

> **Aruba CR:**          90598
>
> **Affected platform:** 8325
>
>**Symptom:**           MAC learning stops.
>
>**Scenario:**          Under extremely rare DMA stress conditions, anL2 learning thread may timeout and exit preventing future MAC learning.
>
>**Workaround:**        Reboot the switch or monitor the L2 thread and restart it with an NAE script.
>
>**Fixed in:**           10.06.0130, 10.7.0010 and above.
>
>[Aruba release notes](https://asp.arubanetworks.com/downloads;products=Aruba%20Switches;productSeries=Aruba%208325%20Switch%20Series)

## To fix the issue without upgrading software

You can run a NAE script on the 8325 platform switches to resolve mac learning issue.

## Important information

* This NAE script creates a bash script in `/tmp` and runs every 60s
* The script writes file to storage every 60s (NAE alert file)
* There are no controls over alert status
* Event log is created when a problem is detected
    * `BCML2X has quit unexpectedly, attempting to restart...`
* You can also grep the error from `/var/log/messages`
* REST API URI is `/rest/v10.04/logs/event?SYSLOG_IDENTIFIER=root&since=yesterday`
* Delete agent and script after upgrading to 10.06.0130+
* Monitor eMMC health if you plan on running for a long time
* Command to run on 8325 switches: `show system resource | include utiliz`

## The file locations in doc-csm

* The NAE script is located at:  [../docs-csm/upgrade/1.0/scripts/aruba/L2X-Watchdog-creates-bash-script.py](../upgrade/1.2/scripts/aruba/L2X-Watchdog-creates-bash-script.py)
* Automatic NAE install script is located at:  [../docs-csm/upgrade/1.0/scripts/aruba/nae_upload.py](../upgrade/1.2/scripts/aruba/nae_upload.py)


## Automated install of NAE script

### Prerequisites

* The `nae-upload.py` script relies on `/etc/hosts` file to pull IP addresses of the switch. Without this information the script will not run.
* You have 8325 in your setup that is running software version below 10.06.0130.
* Script assumes you are using default username `admin` for the switch and it will prompt you for the password.

NOTE: The `nae-upload.py` script automatically detects 8325s and only applies the fix to this platform.

### How to run the install script

1. Run the following command:
    ```bash
    ncn-m001# ./docs-csm/upgrade/1.0/scripts/aruba/nae_upload.py
    ```

2. Type in your switch password and the script will upload and enable the NAE script.

### Manual Installation of the NAE script:

1. Log in to an AOS-CX device via the Web User Interface. Click on the Analytics section on the left, then click on the Scripts button in the top, middle section.

2. On the Scripts page, install the script from your PC to your AOS-CX device by clicking the Upload button on the scripts page and navigating to the file location on your PC.

3. After you have the script on the AOS-CX device, you now need to create an agent. On the Scripts page, you can click the Create Agent button and a Create Agent popup box will appear.
    * Give the Agent a name (no spaces).
    * NOTE: You can leave all other default values and click Create.

4. Navigate you to the Agents page, where you can click on the name of the Agent you made to confirm it is running and no errors are generated.
    * The Network Analytics Engine will monitor the switch and automatically fix the mac learning issue.

### Known Error Messages

#### Incorrect Password

```bash
ncn-m001# ./nae_upload.py
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

#### Script Already Loaded

```bash
ncn-m001# ./nae_upload.py
Switch login password:
L2X-Watchdog NAE script is already installed on sw-spine-001.
L2X-Watchdog NAE script is already installed on sw-spine-002.
```
