# Manage a BOS Session

Once a Boot Orchestration Service \(BOS\) session template is created, users can perform operations on nodes, such as `boot`, `reboot`, and `shutdown`.

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.

* [Create a new session](#create-a-new-session)
* [List all sessions](#list-all-sessions)
* [Show details for a session](#show-details-for-a-session)
* [Delete a session](#delete-a-session)

## Create a new session

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

Sessions also support several other optional arguments:

* `--name`: The session name can be specified. If not set, a random UUID will be generated for the name.
* `--limit`: Limits the nodes that BOS will run against. For more information see [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md)
* `--stage`: Sets `staged_state` for components rather than `desired_state`. This has no immediate effect, but can be applied at a later time. For more information see [Stage Changes with BOS](Stage_Changes_with_BOS.md)

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

## Show details for a session

(`ncn-mw#`) Get details for a BOS session using the session ID.

 ```bash
cray bos v2 sessions describe <BOS_SESSION_ID> --format json
```

Example output:

```json
{
  "components": "",
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

## Delete a session

(`ncn-mw#`) Delete a specific BOS session:

```bash
cray bos v2 sessions delete <BOS_SESSION_ID>
```
