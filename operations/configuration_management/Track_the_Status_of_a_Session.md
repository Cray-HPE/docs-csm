# Track the Status of a Session

A configuration session can be a long-running process, and depends on many system factors, as well as the number of configuration layers and Ansible
tasks that are run in each layer. The Configuration Framework Service \(CFS\) provides the session status through the session metadata to allow for
tracking progress and session state.

- [Prerequisites](#prerequisites)
- [View session status](#view-session-status)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- A configuration session exists in CFS.
- The Cray CLI must be configured on the node where the commands are being run.
  - See [Configure the Cray CLI](../configure_cray_cli.md).

## View session status

(`ncn-mw#`) To view the session status of a session named `example`, use the following command:

```bash
cray cfs v3 sessions describe example --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "",
    "passthrough": "",
    "verbosity": 0
  },
  "configuration": {
    "limit": "",
    "name": "example-config"
  },
  "debug_on_failure": false,
  "logs": "ara.cmn.site/hosts?label=example",
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "completion_time": "2023-08-28T23:35:15",
      "job": "cfs-4d1084f7-7f14-4bc0-a98a-ab22a18d3734",
      "start_time": "2023-08-28T15:08:48",
      "status": "complete",
      "succeeded": "true"
    }
  },
  "tags": {},
  "target": {
    "definition": "dynamic",
    "groups": null
  }
}
```

The `jq` tool, along with the `--format json` output option of the CLI, are helpful for filtering the session data to view just the session status:

```bash
cray cfs v3 sessions describe example --format json | jq .status.session
```

Example output:

```json
{
  "completion_time": "2023-08-28T23:35:15",
  "job": "cfs-4d1084f7-7f14-4bc0-a98a-ab22a18d3734",
  "start_time": "2023-08-28T15:08:48",
  "status": "complete",
  "succeeded": "true"
}
```

The `status` section of the `cray cfs v3 session describe` command output will not be populated until the CFS session Kubernetes job has started.

The `.status.session` mapping shows the overall status of the configuration session.

The `.succeeded` key within this mapping is a string with
values of either `"true"`, `"false"`, `"unknown"`, or `"none"`.
`"none"` occurs if the session has not yet completed, and `"unknown"` occurs when the session is deleted mid-run, there is an error creating the session
and it never starts, or any similar case where checking the session status would fail to find the underlying Kubernetes job running the CFS session.

Values of `.status` can be `"pending"`, `"running"`, or `"complete"`.
Note that a value of `"complete"` does not indicate that configuration was successful.
It only indicates that the session is no longer running.

## Troubleshooting

If a session is not starting, then see [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md).

If a session is starting but not completing, then see [Troubleshoot CFS Session Failing to Complete](Troubleshoot_CFS_Session_Failing_to_Complete.md).

If a session completed but did not succeed, then see [Troubleshoot Failed CFS Sessions](Troubleshoot_CFS_Session_Failed.md).
