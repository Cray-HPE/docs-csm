# Manage a BOS Session

Once there is a Boot Orchestration Service \(BOS\) session template created, users can perform operations on nodes, such as `boot`, `reboot`, `configure`, and `shutdown`.
Managing sessions through the Cray CLI can be accomplished using the `cray bos session` commands.

* [Create a new session](#create-a-new-session)
* [List all sessions](#list-all-sessions)
* [Show details for a session](#show-details-for-a-session)
* [Delete a session](#delete-a-session)

## Create a new session

Creating a new BOS session requires the following command-line options:

* `--template-name`: Use this option to specify the name value returned in the `cray bos sessiontemplate list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, `configure`, or `shutdown` action is being taken.

The following is an example of a boot operation:

```bash
ncn-mw# cray bos session create --template-uuid SESSIONTEMPLATE_NAME --operation Boot --format toml
```

Example output:

```toml
operation = "Boot"
templateUuid = "TEMPLATE_UUID"
[[links]]
href = "foo-c7faa704-3f98-4c91-bdfb-e377a184ab4f"
jobId = "boa-a939bd32-9d27-433f-afc2-735e77ec8e58"
rel = "session"
type = "GET"
```

## List all sessions

List all BOS sessions with the following command:

```bash
ncn-mw# cray bos session list --format toml
```

Example output:

```toml
results = [ "fc469e41-6419-4367-a571-d5fd92893398", "st3-d6730dd5-f0f8-4229-b224-24df005cae52",]
```

## Show details for a session

Get details for a BOS session using the session ID returned in the `cray bos session list` command output.

```bash
ncn-mw# cray bos session describe BOS_SESSION_JOB_ID --format toml
```

Example output:

```toml
computes = "boot_finished"
boa_finish = "2019-12-13 17:07:23.501674"
bos_launch = "2019-12-13 17:02:24.000324"
operation = "reboot"
session_template_id = "cle-1.1.0"
boa_launch = "2019-12-13 17:02:29.703310"
stage = "Done"
```

**Troubleshooting:** There is a known issue in BOS v1 where some sessions cannot be described using the `cray bos session describe` command.
The issue with the describe action results in a 404 error, despite the session existing in the output of `cray bos session list` command.

## Delete a session

Delete a specific BOS session:

```bash
ncn-mw# cray bos session delete BOS_SESSION_JOB_ID
```
