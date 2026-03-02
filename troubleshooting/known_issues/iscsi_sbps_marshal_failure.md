# iSCSI SBPS Marshal agent may fail during upgrade

## Symptom  

During CSM upgrade from `1.6.x` to `1.7.x`, where 'x' is the minor version,
the NCN checks may fail with iSCSI SBPS as below:

```text
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
    "successful": false, --------
    "summary-line": "Command: iSCSI-readiness-test: exit-status:\nExpected\n    <int>: 1\nto equal\n    <int>: 0",
    "test-type": 0,
    "title": "iSCSI-readinesss-test"
}
```

```text
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
    "successful": false, --------
    "summary-line": "Command: iscsi_cps_sanity: exit-status:\nExpected\n    <int>: 1\nto equal\n    <int>: 0",
    "test-type": 0,
    "title": "iSCSI boot content projection"
}
```

## Root cause

iSCSI SBPS marshal system service may not be in active state as below:

```bash
# systemctl status sbps-marshal
● sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images simi>
     Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; preset: disabled)
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-02-26 09:11:36 UTC; 13s ago
    Process: 2241039 ExecStart=/usr/lib/sbps-marshal/bin/sbps-marshal (code=exited, status=203/EXEC)
   Main PID: 2241039 (code=exited, status=203/EXEC)
        CPU: 2ms
```

`journalctl` log for this service may have below errors:

```bash
# Journalctl -u sbps-marshal.service
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

## Resolution

Follow the sequence of steps on the affected node as below:

1. Enable the `sbps-marshal` `systemd` service:

```bash
# systemctl enable sbps-marshal.service
```

Example output:

```bash
ncn-w003:~ # systemctl enable sbps-marshal.service
Created symlink /etc/systemd/system/multi-user.target.wants/sbps-marshal.service → /usr/lib/systemd/system/sbps-marshal.service.
```

1. Restart `sbps-marshal` `systemd` service

```bash
# systemctl restart sbps-marshal.service
```

1. Check the status of `sbps-marshal` service, it should be running fine as below:

Example command:

```bash
# systemctl status sbps-marshal.service
```

Example command output:

```bash

ncn-w003:~ # systemctl status sbps-marshal.service
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
