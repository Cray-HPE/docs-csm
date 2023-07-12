# View the Status of a BOS Session

The Boot Orchestration Service \(BOS\) supports a status endpoint that reports detailed status information for individual BOS sessions.

* [BOS v2 session status](#bos-v2-session-status)
  * [View the status of a v2 session](#view-the-status-of-a-v2-session)
  * [Session status details](#session-status-details)
* [BOS v1 session status](#bos-v1-session-status)
  * [Metadata](#metadata)
  * [View the status of a v1 session](#view-the-status-of-a-v1-session)
  * [View the status of a boot set](#view-the-status-of-a-boot-set)
  * [View the status for an individual phase](#view-the-status-for-an-individual-phase)
  * [View the status for an individual category](#view-the-status-for-an-individual-category)

## BOS v2 session status

BOS v2 session status offers an overall status, as well as information about the percentage of components in each state, and any errors being experienced.
Status will be current as long as the session is running, and will cache itself when the session ends for future reference.

### View the status of a v2 session

(`ncn-mw#`) To view detailed session status, run:

```bash
cray bos v2 sessions status list 3d2e86d1-8909-46fc-8a22-f42f1a140264 --format json
```

Example output:

```json
{
  "error_summary": {
    "Sample error message": {"count":  1, "list":  "x3000c0s13b0n0"}
  },
  "managed_components_count": 1,
  "percent_failed": 100.0,
  "percent_staged": 0,
  "percent_successful": 0,
  "phases": {
    "percent_complete": 100.0,
    "percent_configuring": 0,
    "percent_powering_off": 0,
    "percent_powering_on": 0
  },
  "status": "complete",
  "timing": {
    "duration": "0:00:20",
    "end_time": "2022-08-22T16:51:10",
    "start_time": "2022-08-22T16:50:50"
  }
}
```

### Session status details

#### `error_summary`

Contains any error messages currently reported by nodes whether those are transient failures that will be retried or nodes that have reached a retry limit.
Nodes are grouped by error message, and each message includes a total count of nodes reporting that error as well as a comma separated list of nodes.
For errors on many nodes, the list of nodes will be truncated to the first few for readability.

#### `managed_components_count`

The number of components this session is responsible for.
While the session is running, this is the current count and may decrease if other newer sessions take over responsibility for components.
For completed sessions this is the number of components that were tracked by the session until the session was complete.

#### `status`

Status can be either `pending`, `running`, or `complete`. Sessions are considered `pending` until the desired state of all associated components has been set.

#### `percent_*`

The percent of the `managed_components` that are in the specified state.

#### `start_time`

This timestamp is set when the session is created.

#### `end_time`

This timestamp will initially be `null` and will be set when the session ends.

#### `duration`

This lists the duration of the session in `h:mm:ss`.  While the session is running, this will be the current duration, and the value is locked-in when the session completes.

## BOS v1 session status

In BOS v1, the status can be retrieved for each boot set within the session, as well as the individual items within a boot set.

BOS sessions contain one or more boot sets. Each boot set contains one or more phases, depending upon the operation for that session.
For example, a `reboot` operation would have a `shutdown`, `boot`, and possibly `configuration` phase, but a `shutdown` operation would only have a `shutdown` phase.
Each phase contains the following categories: `not_started`, `in_progress`, `succeeded`, `failed`, and `excluded`.

### Metadata

Each session, boot set, and phase contains similar metadata. The following is a table of useful attributes to look for in the metadata:

| Attribute     | Meaning |
|---------------|---------|
| `start_time`  | The time when a session, boot set, or phase started work. |
| `in_progress` | If true, it means that the session, boot set, or phase has started and still has work going on. |
| `complete`    | If true, it means the session, boot set, or phase has finished. |
| `error_count` | The number of errors encountered in the boot sets or phases. |
| `stop_time`   | The time when a session, boot set, or phase ended work. |

The following table summarizes how to interpret the various combinations of values for the `in_progress` and `complete` flags:

| `in_progress` | `complete` | Meaning |
|---------------|------------|---------|
| false         | false      | Item has not started. |
| true          | false      | Item is in progress. |
| false         | true       | Item has completed. |
| true          | true       | Invalid state \(should not occur\). |

The `in_progress`, `complete`, and `error_count` fields are cumulative, meaning that they summarize the state of the sub-items.

| Item     | `in_progress` meaning                                                       | `complete` meaning |
|----------|-----------------------------------------------------------------------------|--------------------|
| Phase    | If true, it means there is at least one node in the `in_progress` category. | If true, it means that there are no nodes in the `in_progress` or `not_started` categories. |
| Boot set | If true, it means there is at least one phase that is `in_progress`.        | If true, it means that all phases in the boot set are `complete`. |
| Session  | If true, it means that at least one boot set is `in_progress`.              | If true, it means that all boot sets are `complete`. |

### View the status of a v1 session

(`ncn-mw#`) The BOS session ID is required to view the status of a session. To list the available sessions, use the following command:

```bash
cray bos v1 session list --format json
```

Example output:

```json
[
  "99a192c2-050e-41bc-a576-548610851742",
  "4374f3e6-e8ed-4e66-bf63-3ebe0e618db2",
  "fb14932a-a9b7-41b2-ad21-b4bc632cf1ef",
  "9321ab7a-bf7f-42fd-8103-94a296552856",
  "50aaaa85-6807-45c7-b6de-f984a930e2eb",
  "972cfd09-3403-4282-ab93-b41992f7c0d8",
  "2c86c1b9-5281-4610-b044-479f1536727a",
  "7719385a-e462-4bb6-8fd8-55caa0836528",
  "0aac0252-4637-4198-919f-6bafda7fafef",
  "13207c87-0b9f-410c-88c1-6e26ff63cb34",
  "bd18e7e3-978f-4699-b8f2-8a4ce2d46f75",
  "b741e4de-2064-4de4-9f23-20b6c1d0dc1a",
  "f4eebe51-a217-46d0-8733-b9499a092042"
]
```

(`ncn-mw#`) It is recommended to describe the session using the session ID above to verify the desired selection was selected:

```bash
cray bos v1 session describe SESSION_ID
```

Example output:

```text
status_link = "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status"
complete = false
start_time = "2020-07-22 13:39:07.706774"
templateUuid = "cle-1.3.0"
error_count = 4
boa_job_name = "boa-f4eebe51-a217-46d0-8733-b9499a092042"
in_progress = false
operation = "reboot"
```

The status for the session will show the session ID, the boot sets in the session, the metadata, and some links. In the following example, there is only one boot set named computes, and the session ID being used is `f4eebe51-a217-46d0-8733-b9499a092042`.

(`ncn-mw#`) To display the status for the session:

```bash
cray bos v1 session status list SESSION_ID -–format json
```

Example output:

```json
{
  "boot_sets": [
    "computes"
  ],
  "id": "f4eebe51-a217-46d0-8733-b9499a092042",
  "links": [
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status",
      "rel": "self"
    },
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status/computes"                                                                            ,
      "rel": "Boot Set"
    }
  ],
  "metadata": {
    "in_progress": false,
    "start_time": "2020-07-22 13:39:07.706774",
    "complete": false,
    "error_count": 4
  }
}
```

### View the status of a boot set

Run the following command to view the status for a specific boot set in a session.
For more information about retrieving the session ID and boot set name, refer to the "View the Status of a Session" section above. Descriptions of the different status sections are described below.

* Boot set
  * The `id` parameter identifies which session this status belongs to.
  * The `name` parameter is the name of the boot set.
  * The `links` section displays links that enable administrators to drill down into each phase of the boot set.
  * There is `metadata` section for the boot set as a whole.
* Phases
  * The `name` parameter is the name of the phase.
  * There is a `metadata` section for each phase.
  * Each phase contains the following categories: `not_started`, `in_progress`, `succeeded`, `failed`, and `excluded`. The nodes are listed in the category they are currently occupying.

(`ncn-mw#`)

```bash
cray bos v1 session status describe BOOT_SET_NAME SESSION_ID --format json
```

Example output:

```json
{
  "phases": [
    {
      "name": "shutdown",
      "categories": [
        {
          "name": "not_started",
          "node_list": []
        },
        {
          "name": "succeeded",
          "node_list": []
        },
        {
          "name": "failed",
          "node_list": [
            "x3000c0s19b4n0",
            "x3000c0s19b1n0",
            "x3000c0s19b3n0",
            "x3000c0s19b2n0"
          ]
        },
        {
          "name": "excluded",
          "node_list": []
        },
        {
          "name": "in_progress",
          "node_list": []
        }
      ],
      "metadata": {
        "stop_time": "2020-07-22 13:53:19.842705",
        "in_progress": false,
        "start_time": "2020-07-22 13:39:08.276530",
        "complete": true,
        "error_count": 4
      }
    },
    {
      "name": "boot",
      "categories": [
        {
          "name": "not_started",
          "node_list": [
            "x3000c0s19b4n0",
            "x3000c0s19b3n0",
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        },
        {
          "name": "succeeded",
          "node_list": []
        },
        {
          "name": "failed",
          "node_list": []
        },
        {
          "name": "excluded",
          "node_list": []
        },
        {
          "name": "in_progress",
          "node_list": []
        }
      ],
      "metadata": {
        "in_progress": false,
        "start_time": "2020-07-22 13:39:08.276542",
        "complete": false,
        "error_count": 0
      }
    },
    {
      "name": "configure",
      "categories": [
        {
          "name": "not_started",
          "node_list": [
            "x3000c0s19b4n0",
            "x3000c0s19b3n0",
            "x3000c0s19b1n0",
            "x3000c0s19b2n0"
          ]
        },
        {
          "name": "succeeded",
          "node_list": []
        },
        {
          "name": "failed",
          "node_list": []
        },
        {
          "name": "excluded",
          "node_list": []
        },
        {
          "name": "in_progress",
          "node_list": []
        }
      ],
      "metadata": {
        "in_progress": false,
        "start_time": "2020-07-22 13:39:08.276552",
        "complete": false,
        "error_count": 0
      }
    }
  ],
  "session": "f4eebe51-a217-46d0-8733-b9499a092042",
  "name": "computes",
  "links": [
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status/computes",
      "rel": "self"
    },
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status/computes/shutdown",
      "rel": "Phase"
    },
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status/computes/boot",
      "rel": "Phase"
    },
    {
      "href": "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status/computes/configure",
      "rel": "Phase"
    }
  ],
  "metadata": {
    "in_progress": false,
    "start_time": "2020-07-22 13:39:08.276519",
    "complete": false,
    "error_count": 4
  }
}
```

### View the status for an individual phase

Direct calls to the API are needed to retrieve the status for an individual phase. Support for the Cray CLI is not currently available.

(`ncn-mw#`) The following command is used to view the status of a phase:

```bash
curl -H "Authorization: Bearer BEARER_TOKEN" -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/SESSION_ID/status/BOOT_SET_NAME/PHASE
```

(`ncn-mw#`) In the following example, the session ID is `f89eb554-c733-4197-b2f2-4e1e5ba0c0ec`, the boot set name is `computes`, and the individual phase is `shutdown`.

```bash
curl -H "Authorization: Bearer BEARER_TOKEN" -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/f89eb554-c733-4197-b2f2-4e1e5ba0c0ec/status/computes/shutdown
```

Example output:

```json
{
  "categories": [
    {
      "name": "not_started",
      "node_list": []
    },
    {
      "name": "succeeded",
      "node_list": []
    },
    {
      "name": "failed",
      "node_list": []
    },
    {
      "name": "excluded",
      "node_list": []
    },
    {
      "name": "in_progress",
      "node_list": [
        "x5000c1s2b0n1",
        "x5000c1s0b0n0",
        "x3000c0s19b4n0",
        "x5000c1s0b1n0",
        "x5000c1s0b1n1",
        "x5000c1s1b1n1",
        "x5000c1s2b0n0",
        "x3000c0s19b3n0",
        "x5000c1s0b0n1",
        "x5000c1s2b1n1",
        "x3000c0s19b1n0",
        "x5000c1s1b1n0",
        "x5000c1s2b1n0",
        "x3000c0s19b2n0",
        "x5000c1s1b0n1",
        "x5000c1s1b0n0"
      ]
    }
  ],
  "metadata": {
    "complete": false,
    "error_count": 0,
    "in_progress": true,
    "start_time": "2020-06-30 21:42:39.355423"
  },
  "name": "shutdown"
}
```

### View the status for an individual category

Direct calls to the API are needed to retrieve the status for an individual category. Support for the Cray CLI is not currently available.

(`ncn-mw#`) The following command is used to view the status of a phase:

```bash
curl -H "Authorization: Bearer BEARER_TOKEN" -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/SESSION_ID/status/BOOT_SET_NAME/PHASE/CATEGORY
```

(`ncn-mw#`) In the following example, the session ID is `f89eb554-c733-4197-b2f2-4e1e5ba0c0ec`, the boot set name is `computes`, the phase is `shutdown`, and the category is `in_progress`.

```bash
curl -H "Authorization: Bearer BEARER_TOKEN" -X GET https://api-gw-service-nmn.local/apis/bos/v1/session/f89eb554-c733-4197-b2f2-4e1e5ba0c0ec/status/computes/shutdown/in_progress
```

Example output:

```json
{
  "name": "in_progress",
  "node_list": [
    "x5000c1s2b0n1",
    "x5000c1s0b0n0",
    "x3000c0s19b4n0",
    "x5000c1s0b1n0",
    "x5000c1s0b1n1",
    "x5000c1s1b1n1",
    "x5000c1s2b0n0",
    "x3000c0s19b3n0",
    "x5000c1s0b0n1",
    "x5000c1s2b1n1",
    "x3000c0s19b1n0",
    "x5000c1s1b1n0",
    "x5000c1s2b1n0",
    "x3000c0s19b2n0",
    "x5000c1s1b0n1",
    "x5000c1s1b0n0"
  ]
}
```
