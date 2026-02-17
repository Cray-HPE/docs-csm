# Manage a BOS Session

Once a BOS [session template](Session_Templates.md) is created, users can perform operations on nodes,
such as `boot`, `reboot`, `configure`, and `shutdown`.

To find the corresponding API calls for any Cray CLI command, append `-vvv` to the end of the CLI command.
This makes the CLI print the underlying API call in the output.

* [Create a session](#create-a-session)
  * [Optional session creation arguments](#optional-session-creation-arguments)
  * [Completed session cleanup](#completed-session-cleanup)
* [List all sessions](#list-all-sessions)
* [Show session details](#show-session-details)
* [View session status](#view-session-status)
* [Delete a session](#delete-a-session)

## Create a session

Creating a new BOS session requires the following command-line options:

* `--template-uuid`: Use this option to specify the name value returned in the `cray bos sessiontemplate list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, `configure`, or `shutdown` action is being taken.

The following is an example of a boot operation:

```console
ncn-mw# cray bos session create --template-uuid TEMPLATE_UUID --operation boot --format toml
```

Example output:

```toml
limit = ""
operation = "boot"
templateUuid = "TEMPLATE_UUID"
[[links]]
href = "/v1/session/9173f29f-29a4-424f-b974-7fe85036dc3f"
jobId = "boa-9173f29f-29a4-424f-b974-7fe85036dc3f"
rel = "session"
type = "GET"

[[links]]
href = "/v1/session/9173f29f-29a4-424f-b974-7fe85036dc3f/status"
rel = "status"
type = "GET"
```

The BOS session ID is a UUID embedded in the `jobId` and `href` fields.
In the above example, it is `9173f29f-29a4-424f-b974-7fe85036dc3f`.

### Optional session creation arguments

BOS sessions also support the following optional argument:

* `--limit`: Limits the nodes that BOS will run against.
  * For more information see [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md).

### Completed session cleanup

It is important to periodically delete completed BOS sessions. If too many BOS sessions
exist, it can lead to hangs when trying to list them.
For more information, see:

* [Hang Listing BOS Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_Sessions.md)
* [Delete a session](#delete-a-session)

## List all sessions

List all BOS sessions with the following command:

```console
ncn-mw# cray bos session list --format toml
```

Example output:

```toml
results = [ "fc469e41-6419-4367-a571-d5fd92893398", "st3-d6730dd5-f0f8-4229-b224-24df005cae52",]
```

**Troubleshooting:** There is a known limitation of BOS v1 that listing sessions will hang if too
many sessions exist. For more information, see
[Hang Listing BOS Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_Sessions.md).

## Show session details

Get details for a BOS session using the session ID.

```console
ncn-mw# cray bos session describe BOS_SESSION_ID --format toml
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

## View session status

See [View the status of a session](View_the_Status_of_a_BOS_Session.md#view-the-status-of-a-session).

## Delete a session

It is important to periodically delete completed BOS sessions. If too many BOS sessions
exist, it can lead to hangs when trying to list them. For more information, see
[Hang Listing BOS Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_Sessions.md).

Delete a specific BOS session:

```console
ncn-mw# cray bos session delete BOS_SESSION_ID
```
