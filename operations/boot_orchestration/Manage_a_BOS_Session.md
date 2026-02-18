# Manage a BOS Session

Once a BOS [session template](Session_Templates.md) is created, users can perform operations on nodes,
such as `boot`, `reboot`, and `shutdown`.

To find the corresponding API calls for any Cray CLI command, append `-vvv` to the end of the CLI command.
This makes the CLI print the underlying API call in the output.

* [Create a session](#create-a-session)
    * [Optional session creation arguments](#optional-session-creation-arguments)
* [List all sessions](#list-all-sessions)
* [Show session details](#show-session-details)
* [View session status](#view-session-status)
* [Delete a session](#delete-a-session)

## Create a session

Creating a new BOS session requires the following command-line options:

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
  "template_name": "TEMPLATE_NAME",
  "tenant": null
}
```

### Optional session creation arguments

Sessions also support several other optional arguments:

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

## List all sessions

(`ncn-mw#`) List all BOS sessions with the following command:

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
    "template_name": "cle-1.1.0",
    "tenant": null
  }
]
```

## Show session details

(`ncn-mw#`) Get details for a BOS session using the session name.

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
  "template_name": "cle-1.1.0",
  "tenant": null
}
```

## View session status

(`ncn-mw#`) View the status of a BOS session using the session name.

 ```bash
cray bos v2 sessions status list <BOS_SESSION_NAME> --format json
```

See [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md).

## Delete a session

(`ncn-mw#`) Delete a specific BOS session:

```bash
cray bos v2 sessions delete <BOS_SESSION_NAME>
```
