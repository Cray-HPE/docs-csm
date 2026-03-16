# iSCSI SBPS `systemd` service (`sbps-marshal`) may fail during upgrade

## Symptom

During the CSM upgrade from `1.6.x` to `1.7.x` or from `1.7.x` to `1.7.y`
where 'x' and 'y' are the patch version(s), the NCN health checks may fail with
iSCSI SBPS as below:

```json
{
    "duration": 54160,
    "err": null,
    "expected": [
        "0"
    ],
    "found": [
        "1"
    ],
    "human": "Expected\n    <int>: 1\nto equal\n    <int>: 0",
    "meta": {
        "desc": "Readiness Test for iSCSI.",
        "sev": 0
    },
    "property": "exit-status",
    "resource-id": "iSCSI-readiness-test",
    "resource-type": "Command",
    "result": 1,
    "skipped": false,
    "successful": false,
    "summary-line": "Command: iSCSI-readiness-test: exit-status:\nExpected\n    <int>: 1\nto equal\n    <int>: 0",
    "test-type": 0,
    "title": "iSCSI-readinesss-test"
}
```

```json
{
    "duration": 35375,
    "err": null,
    "expected": [
        "0"
    ],
    "found": [
        "1"
    ],
    "human": "Expected\n    <int>: 1\nto equal\n    <int>: 0",
    "meta": {
        "desc": "Checks for iSCSI portals and verifies that the iSCSI-based boot Content Projection Service is active and running.",
        "sev": 0
    },
    "property": "exit-status",
    "resource-id": "iscsi_cps_sanity",
    "resource-type": "Command",
    "result": 1,
    "skipped": false,
    "successful": false,
    "summary-line": "Command: iscsi_cps_sanity: exit-status:\nExpected\n    <int>: 1\nto equal\n    <int>: 0",
    "test-type": 0,
    "title": "iSCSI boot content projection"
}
```

## Root cause

(`ncn-w#`) Status of iSCSI SBPS `systemd` service may not be active:

```bash
systemctl status sbps-marshal
```

Example command output:

```text

● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images simi>
     Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; preset: disabled)
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-02-26 09:11:36 UTC; 13s ago
    Process: 2241039 ExecStart=/usr/lib/sbps-marshal/bin/sbps-marshal (code=exited, status=203/EXEC)
   Main PID: 2241039 (code=exited, status=203/EXEC)
        CPU: 2ms
```

The `systemd` service journal may show the following errors:

```bash
journalctl -u sbps-marshal.service
```

Snippet of `journalctl` log:

```text
Feb 26 09:11:00 ncn-w003 systemd[1]: Started System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE..
Feb 26 09:11:00 ncn-w003 (-marshal)[2230374]: sbps-marshal.service: Failed at step EXEC spawning /usr/lib/sbps-marshal/bin/sbps-marshal: No such file or directory
Feb 26 09:11:00 ncn-w003 systemd[1]: sbps-marshal.service: Main process exited, code=exited, status=203/EXEC
Feb 26 09:11:00 ncn-w003 systemd[1]: sbps-marshal.service: Failed with result 'exit-code'.
Feb 26 09:11:36 ncn-w003 systemd[1]: Stopped System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE..
Feb 26 09:11:36 ncn-w003 (-marshal)[2241039]: sbps-marshal.service: Failed to locate executable /usr/lib/sbps-marshal/bin/sbps-marshal: No such file or directory
Feb 26 09:11:36 ncn-w003 (-marshal)[2241039]: sbps-marshal.service: Failed at step EXEC spawning /usr/lib/sbps-marshal/bin/sbps-marshal: No such file or directory
Feb 26 09:11:36 ncn-w003 systemd[1]: Started System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE..
Feb 26 09:11:36 ncn-w003 systemd[1]: sbps-marshal.service: Main process exited, code=exited, status=203/EXEC
Feb 26 09:11:36 ncn-w003 systemd[1]: sbps-marshal.service: Failed with result 'exit-code'.
```

The failure to locate `/usr/lib/sbps-marshal/bin/sbps-marshal` can occur due to issues during the RPM installation
or `sbps-marshal` service enablement process. The `sbps-marshal` binary is installed as part of the RPM installation,
while the symbolic link between `/usr/lib/systemd/system/sbps-marshal.service` and
`/etc/systemd/system/multi-user.target.wants/sbps-marshal.service` is created when the `sbps-marshal` service is enabled.

Two scenarios can lead to this issue:

1. Incomplete RPM installation, resulting in the absence of `/usr/lib/sbps-marshal/bin/sbps-marshal`.

1. Successful RPM installation but the failure during service enablement (for example during worker node personalization),
resulting in the absence of symbolic link `/etc/systemd/system/multi-user.target.wants/sbps-marshal.service`

## Resolution

Use the following procedure on the affected node.

1. (`ncn-w#`) Check if the `sbps-marshal` RPM is installed.

   ```bash
   rpm -qa | grep sbps
   ```

   Example output:

   ```text
   sbps-marshal-1.0.3-1.noarch
   ```

1. (`ncn-w#`) Uninstall the `sbps-marshal` RPM.

   ```bash
   rpm -e sbps-marshal-1.0.3-1.noarch
   ```

   Example output:

   ```text
   Removed "/etc/systemd/system/multi-user.target.wants/sbps-marshal.service".
   ```

1. (`ncn-m#`) Locate the `sbps-marshal` RPM on the master node on which upgrade is triggered.

   1. cat upgrade `myenv` file :

      ```bash
      cat /etc/cray/upgrade/csm/myenv
      ```

      Example output:

      ```text
      export CSM_ARTI_DIR=/etc/cray/upgrade/csm/media/upg171rc6/csm-1.7.1-rc.6
      export CSM_RELEASE=1.7.1-rc.6
      export CSM_REL_NAME=csm-1.7.1-rc.6
      export STORAGE_IMS_IMAGE_ID=d3b0b216-028f-427d-9569-192f2750d1fc
      export K8S_IMS_IMAGE_ID=a72b1bb7-30ad-499f-b5b4-e192853445a1
      ```

   1. Switch to the directory mentioned in the `CSM_ARTI_DIR` variable from the previous step.

      ```bash
      cd /etc/cray/upgrade/csm/media/upg171rc6/csm-1.7.1-rc.6
      ```

    1.  Switch to `rpm/cray/csm/noos/noarch` under above mentioned directory.

      ```bash
      cd rpm/cray/csm/noos/noarch
      ```

    1.  List the `sbps-marshal` RPM.

      ```bash
      ls -l | grep sbps-marshal
      ```

      Example command output:

      ```text
      -rw-r--r-- 1 root root 11615684 Jan 22 18:34 sbps-marshal-1.0.3-1.noarch.rpm
      ```

1. (`ncn-w#`) Install the `sbps-marshal` RPM listed above:

   ```bash
   zypper install sbps-marshal-1.0.3-1.noarch.rpm
   ```

1. (`ncn-w#`) Verify whether the RPM is installed:

   ```bash
   rpm -qa | grep sbps-marshal
   ```

   Example output on successful installation:

   ```text
   sbps-marshal-1.0.3-1.noarch
   ```

1. (`ncn-w#`) Enable the `sbps-marshal` `systemd` service:

   ```bash
   systemctl enable sbps-marshal.service
   ```

   Example output:

   ```text
   Created symlink /etc/systemd/system/multi-user.target.wants/sbps-marshal.service → /usr/lib/systemd/system/sbps-marshal.service.
   ```

1. (`ncn-w#`) Restart the `sbps-marshal` `systemd` service

   ```bash
   systemctl restart sbps-marshal.service
   ```

1. (`ncn-w#`) Check the status of the `sbps-marshal` service, it should be running:

   Example command:

   ```bash
   systemctl status sbps-marshal.service
   ```

   Example command output:

```text
   
● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary>
     Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; preset: disabled)
     Active: active (running) since Thu 2026-02-26 18:07:51 UTC; 22min ago
   Main PID: 1297260 (sbps-marshal)
      Tasks: 1
        CPU: 3min 14.810s
     CGroup: /system.slice/sbps-marshal.service
             └─1297260 /usr/lib/sbps-marshal/bin/python /usr/lib/sbps-marshal/bin/sbps-marshal

Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:314 INFO 2026-02-26T18:29:49+0000 No sbps-project key value>
Feb 26 18:29:49 ncn-w003 sbps-marshal[1297260]: agent.py:main:405 INFO 2026-02-26T18:29:49+0000 END SCAN
```
