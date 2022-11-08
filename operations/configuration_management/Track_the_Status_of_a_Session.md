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
cray cfs sessions describe example --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "",
    "verbosity": 0
  },
  "configuration": {
    "limit": "",
    "name": "configurations-example"
  },
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "completionTime": "2020-07-28T03:26:30",
      "job": "cfs-8c8d628b-ebac-4946-a8b7-f1f167b35b0d",
      "startTime": "2020-07-28T03:26:00",
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
cray cfs sessions describe example --format json | jq .status.session
```

Example output:

```json
{
  "completionTime": "2020-07-28T03:26:30",
  "job": "cfs-8c8d628b-ebac-4946-a8b7-f1f167b35b0d",
  "startTime": "2020-07-28T03:26:00",
  "status": "complete",
  "succeeded": "true"
}
```

The `status` section of the `cray cfs session describe` command output will not be populated until the CFS session Kubernetes job has started.

The `.status.session` mapping shows the overall status of the configuration session. The `.succeeded` key within this mapping is a string with
values of either `"true"`, `"false"`, `"unknown"`, or `"none"`.

`"none"` occurs if the session has not yet completed, and `"unknown"` occurs when the session is deleted mid-run, there is an error creating the session
and it never starts, or any similar case where checking the session status would fail to find the underlying Kubernetes job running the CFS session.

Values of `.status` can be `"pending"`, `"running"`, or `"complete"`.

## Troubleshooting

If a session is not starting, then see [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md).

If a session is starting but not completing, then see [Troubleshoot CFS Session Failing to Complete](Troubleshoot_CFS_Session_Failing_to_Complete.md).

If a session completed but did not succeed, then see [Troubleshoot Ansible Play Failures in CFS Sessions](#Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md).
