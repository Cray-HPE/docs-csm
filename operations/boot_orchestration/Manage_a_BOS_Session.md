# Manage a BOS Session

Once a BOS [session template](Session_Templates.md) is created, users can perform operations on nodes,
such as `boot`, `reboot`, and `shutdown`.

To find the corresponding API calls for any Cray CLI command, append `-vvv` to the end of the CLI command.
This makes the CLI print the underlying API call in the output.

* [Create a session](#create-a-session)
    * [Create a v2 session](#create-a-v2-session)
        * [Optional v2 session creation arguments](#optional-v2-session-creation-arguments)
    * [Create a v1 session](#create-a-v1-session)
        * [Optional v1 session creation arguments](#optional-v1-session-creation-arguments)
        * [Completed v1 session cleanup](#completed-v1-session-cleanup)
* [List all sessions](#list-all-sessions)
    * [List all v2 sessions](#list-all-v2-sessions)
    * [List all v1 sessions](#list-all-v1-sessions)
* [Show session details](#show-session-details)
    * [Show v2 session details](#show-v2-session-details)
    * [Show v1 session details](#show-v1-session-details)
* [View session status](#view-session-status)
    * [View v2 session status](#view-v2-session-status)
    * [View v1 session status](#view-v1-session-status)
* [Delete a session](#delete-a-session)
    * [Delete a v2 session](#delete-a-v2-session)
    * [Delete a v1 session](#delete-a-v1-session)

## Create a session

### Create a v2 session

Creating a new BOS v2 session requires the following command-line options:

* `--template-name`: Use this option to specify the name value returned in the `cray bos v2 sessiontemplates list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, or `shutdown` action is being taken.

(`ncn-mw#`): The following is a boot operation:

```bash
cray bos v2 sessions create --template-name <TEMPLATE_NAME> --operation boot --format json
```

Example output:

```json
{
  "components": "",
  "include_disabled": false,
  "limit": "",
  "name": "9fea7f3f-0a77-40b9-892d-37712de51d65",
  "operation": "boot",
  "stage": false,
  "status": {
    "end_time": null,
    "error": null,
    "start_time": "2022-08-22T14:44:27",
    "status": "pending"
  },
  "template_name": "TEMPLATE_NAME"
}
```

#### Optional v2 session creation arguments

BOS v2 sessions also support several other optional arguments:

* `--name`: The session name can be specified. If not set, a random UUID will be generated for the name.
* `--limit`: Limits the nodes that BOS will run against.
    * For more information see [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md).
    * If the [`session_limit_required` BOS option](Options.md#session_limit_required) is enabled, then the `limit` argument is not optional.
* `--stage`: Sets `staged_state` for components rather than `desired_state`.
    * The new session has no immediate effect, but can be applied at a later time.
    * For more information see [Stage Changes with BOS](Stage_Changes_with_BOS.md).
* `--include-disabled`: BOS sessions automatically exclude nodes that have been disabled in the
  [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm),
  unless this argument is set to true when the session is created.

### Create a v1 session

Creating a new BOS v1 session requires the following command-line options:

* `--template-name`: Use this option to specify the name value returned in the `cray bos v1 sessiontemplate list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, `configure`, or `shutdown` action is being taken.

(`ncn-mw#`): The following is a boot operation:

```bash
cray bos v1 session create --template-name <TEMPLATE_NAME> --operation boot --format json
```

Example output:

```json
{
  "job": "boa-9173f29f-29a4-424f-b974-7fe85036dc3f",
  "limit": "",
  "links": [
    {
      "href": "/v1/session/9173f29f-29a4-424f-b974-7fe85036dc3f",
      "jobId": "boa-9173f29f-29a4-424f-b974-7fe85036dc3f",
      "rel": "session",
      "type": "GET"
    },
    {
      "href": "/v1/session/9173f29f-29a4-424f-b974-7fe85036dc3f/status",
      "rel": "status",
      "type": "GET"
    }
  ],
  "operation": "boot",
  "templateName": "TEMPLATE_NAME"
}
```

The BOS v1 session ID is a UUID embedded in the `job`, `jobId`, and `href` fields.
In the above example, it is `9173f29f-29a4-424f-b974-7fe85036dc3f`.

#### Optional v1 session creation arguments

BOS v1 sessions also support the following optional argument:

* `--limit`: Limits the nodes that BOS will run against.
    * The [`session_limit_required` BOS v2 option](Options.md#session_limit_required) has no impact on v1 sessions.
    * For more information see [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md).

#### Completed v1 session cleanup

It is important to periodically delete completed BOS v1 sessions. If too many BOS v1 sessions
exist, it can lead to hangs when trying to list them. This limitation does not exist in BOS v2.
For more information, see:

* [Hang Listing BOS V1 Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_V1_Sessions.md)
* [Delete a v1 session](#delete-a-v1-session)

## List all sessions

### List all v2 sessions

(`ncn-mw#`) List all BOS v2 sessions with the following command:

```bash
cray bos v2 sessions list --format json
```

Example output:

```json
[
  {
    "components": "",
    "include_disabled": false,
    "limit": "",
    "name": "9fea7f3f-0a77-40b9-892d-37712de51d65",
    "operation": "boot",
    "stage": false,
    "status": {
      "end_time": null,
      "error": null,
      "start_time": "2022-08-22T14:44:27",
      "status": "pending"
    },
    "template_name": "cle-1.1.0"
  }
]
```

### List all v1 sessions

(`ncn-mw#`) List all BOS v1 sessions with the following command:

```bash
cray bos v1 session list --format json
```

Example output:

```json
[
  "34dddd18-1f53-4fd7-829e-3ac7b4e995c3",
  "ebe82079-2397-4e03-8e39-091a8d036146"
]
```

**Troubleshooting:** There is a known limitation of BOS v1 that listing sessions will hang if too
many sessions exist. For more information, see
[Hang Listing BOS V1 Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_V1_Sessions.md).

## Show session details

### Show v2 session details

(`ncn-mw#`) Get details for a BOS v2 session using the session name.

 ```bash
cray bos v2 sessions describe <BOS_SESSION_NAME> --format json
```

Example output:

```json
{
  "components": "",
  "include_disabled": false,
  "limit": "",
  "name": "9fea7f3f-0a77-40b9-892d-37712de51d65",
  "operation": "boot",
  "stage": false,
  "status": {
    "end_time": null,
    "error": null,
    "start_time": "2022-08-22T14:44:27",
    "status": "pending"
  },
  "template_name": "cle-1.1.0"
}
```

### Show v1 session details

(`ncn-mw#`) Get details for a BOS v1 session using the session ID.

```bash
cray bos v1 session describe <BOS_SESSION_ID> --format json
```

Example output:

```json
{
  "complete": false,
  "error_count": 0,
  "in_progress": false,
  "job": "boa-34dddd18-1f53-4fd7-829e-3ac7b4e995c3",
  "operation": "reboot",
  "start_time": "2022-08-22T12:22:33.708209Z",
  "status_link": "/v1/session/34dddd18-1f53-4fd7-829e-3ac7b4e995c3/status",
  "stop_time": "2022-08-22 12:58:23.674867",
  "templateName": "cle-1.1.0"
}
```

**Troubleshooting:** There is a known issue in BOS v1 where some sessions cannot be described using the `cray bos v1 session describe` command.
The issue with the describe action results in a 404 error, despite the session existing in the output of `cray bos v1 session list` command.

## View session status

## View v2 session status

(`ncn-mw#`) View the status of a BOS session using the session name.

 ```bash
cray bos v2 sessions status list <BOS_SESSION_NAME> --format json
```

See [View the status of a v2 session](View_the_Status_of_a_BOS_Session.md#view-the-status-of-a-v2-session).

## View v1 session status

See [View the status of a v1 session](View_the_Status_of_a_BOS_Session.md#view-the-status-of-a-v1-session).

## Delete a session

### Delete a v2 session

(`ncn-mw#`) Delete a specific BOS v2 session:

```bash
cray bos v2 sessions delete <BOS_SESSION_NAME>
```

### Delete a v1 session

It is important to periodically delete completed BOS v1 sessions. If too many BOS v1 sessions
exist, it can lead to hangs when trying to list them. This limitation does not exist in BOS v2.
For more information, see
[Hang Listing BOS V1 Sessions](../../troubleshooting/known_issues/Hang_Listing_BOS_V1_Sessions.md).

(`ncn-mw#`) Delete a specific BOS v1 session:

```bash
cray bos v1 session delete <BOS_SESSION_ID>
```
