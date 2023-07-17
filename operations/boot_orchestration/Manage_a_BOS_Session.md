# Manage a BOS Session

Once a Boot Orchestration Service \(BOS\) session template is created, users can perform operations on nodes, such as `boot`, `reboot`, and `shutdown`.

To find the API versions of any commands listed, add `-vvv` to the end of the CLI command, and the CLI will print the underlying call to the API in the output.

* [Create a new v2 session](#create-a-new-v2-session)
* [Create a new v1 session](#create-a-new-v1-session)
* [List all sessions](#list-all-sessions)
* [Show details for a session](#show-details-for-a-session)
* [Delete a session](#delete-a-session)

## Create a new v2 session

Creating a new BOS v2 session requires the following command-line options:

* `--template-name`: Use this option to specify the name value returned in the `cray bos v2 sessiontemplates list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, or `shutdown` action is being taken.

(`ncn-mw#`): The following is a boot operation:

```bash
cray bos v2 sessions create --template-name <TEMPLATE_NAME> --operation Boot --format json
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

V2 Sessions also support several other optional arguments:

* `--name`: The session name can be specified. If not set, a random UUID will be generated for the name.
* `--limit`: Limits the nodes that BOS will run against. For more information see [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md)
* `--stage`: Sets `staged_state` for components rather than `desired_state`. This has no immediate effect, but can be applied at a later time. For more information see [Stage Changes with BOS](Stage_Changes_with_BOS.md)

## Create a new v1 session

Creating a new BOS v1 session requires the following command-line options:

* `--template-name`: Use this option to specify the name value returned in the `cray bos v1 sessiontemplate list` command.
* `--operation`: Use this option to indicate if a `boot`, `reboot`, `configure`, or `shutdown` action is being taken.

(`ncn-mw#`): The following is a boot operation:

```bash
cray bos v1 session create --template-name <TEMPLATE_NAME> --operation Boot --format json
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

## List all sessions

(`ncn-mw#`) List all BOS v2 sessions with the following command:

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

## Show details for a session

(`ncn-mw#`) Get details for a BOS v2 session using the session ID.

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

## Delete a session

(`ncn-mw#`) Delete a specific BOS v2 session:

```bash
cray bos v2 sessions delete <BOS_SESSION_ID>
```

(`ncn-mw#`) Delete a specific BOS v1 session:

```bash
cray bos v1 session delete <BOS_SESSION_ID>
```
