# View the Status of a BOS Session

The Boot Orchestration Service \(BOS\) supports a status endpoint that reports detailed status information for individual BOS sessions.

* [BOS session status](#bos-session-status)
  * [View the status of a session](#view-the-status-of-a-session)
  * [Session status details](#session-status-details)

## BOS session status

BOS session status offers an overall status, as well as information about the percentage of components in each state, and any errors being experienced.
Status will be current as long as the session is running, and will cache itself when the session ends for future reference.

### View the status of a session

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

This lists the duration of the session in `h:mm:ss`. While the session is running, this will be the current duration, and the value is locked-in when the session completes.
