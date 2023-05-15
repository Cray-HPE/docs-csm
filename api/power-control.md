<!-- Generator: Widdershins v4.0.1 -->

<h1 id="power-control-service-pcs-">Power Control Service (PCS) v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Power Control Service (PCS) performs power-related operations on  system components - nodes, blades, and chassis.  PCS refers to system components by their xname, or system identifier. 

This REST API provides the following functions:
* Turn xnames on or off.
* Perform hard and soft reset actions.
* Set and retrieve power capping parameters and capabilities.
* Get node rules which are various parameters relating to power operations.

## Resources
### /transitions
Power xname on or off.
### /power-status
Get power status of xnames.
### /power-cap
### /power-cap-snapshot
Get and set power capping parameters.
## Workflows
### Set Power Cap for a list of targets
#### PATCH /power-cap
Send a JSON payload with a list of targets and power capping parameters to be applied to the targets.  This is a non-blocking operation. A task ID is returned, used to query the status of the task and get the requested information.
### Get Power Cap status and information for a power cap task
#### GET /power-cap/{taskID}
Retrieve status of specified power cap PATCH operation and current values.
### Get Power Cap parameters and capabilities for a list of targets
#### POST /power-cap/snapshot
Send a JSON payload with a list of target xnames.  This will launch a task and return a snapshot ID which can be queried for status.
### Get status and current Power Cap settings from recent power cap snapshot
#### GET /power-cap/{taskID}
Query the status of a power cap snapshot task.  If completed, contains the current power cap values as read from the hardware.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/power-control/v1">https://api-gw-service-nmn.local/apis/power-control/v1</a>

* <a href="http://cray-power-control/v1">http://cray-power-control/v1</a>

* <a href="https://loki-ncn-m001.us.cray.com/apis/power-control/v1">https://loki-ncn-m001.us.cray.com/apis/power-control/v1</a>

* <a href="http://localhost:26970">http://localhost:26970</a>

 License: MIT

<h1 id="power-control-service-pcs--transitions">transitions</h1>

Endpoints that perform power operations to a set of xnames

## post__transitions

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/power-control/v1/transitions HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/power-control/v1/transitions \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/power-control/v1/transitions', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/power-control/v1/transitions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /transitions`

*Start a transition*

Request to perform power transitions.

> Body parameter

```json
{
  "operation": "force-off",
  "taskDeadlineMinutes": 0,
  "location": [
    {
      "xname": "x0c0s0b0n0",
      "deputyKey": "80838f7c-04e3-4cf6-8456-6bd557a0f1be"
    }
  ]
}
```

<h3 id="post__transitions-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[transition_create](#schematransition_create)|true|Transition parameters|

> Example responses

> 200 Response

```json
{
  "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
  "operation": "on"
}
```

> 400 Response

<h3 id="post__transitions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Accepted|[transition_start_output](#schematransition_start_output)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error prevented starting the transition|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__transitions

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/transitions HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/transitions \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/transitions', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/transitions", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /transitions`

*Retrieve all requested power transitions*

Return a complete list of the requested power transitions,
with status information. Note that records older than 24 hours
are automatically deleted.

> Example responses

> 200 Response

```json
{
  "transitions": [
    {
      "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
      "createTime": "2020-12-16T19:00:20",
      "automaticExpirationTime": "2019-08-24T14:15:22Z",
      "transitionStatus": "in-progress",
      "operation": "force-off",
      "taskCounts": {
        "total": 5,
        "new": 2,
        "in-progress": 2,
        "failed": 0,
        "succeeded": 1,
        "un-supported": 0
      }
    }
  ]
}
```

> 500 Response

<h3 id="get__transitions-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[transitions_getAll](#schematransitions_getall)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error prevented getting the transitions|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__transitions_{transitionID}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /transitions/{transitionID}`

*Retrieve transition status by ID*

Retrieve the transition status information for the specified 
transitionID.

<h3 id="get__transitions_{transitionid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|transitionID|path|string(uuid)|true|none|

> Example responses

> 200 Response

```json
{
  "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
  "createTime": "2020-12-16T19:00:20",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "transitionStatus": "in-progress",
  "operation": "force-off",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "tasks": [
    {
      "xname": "x0c0s0b0n0",
      "taskStatus": "failed",
      "taskStatusDescription": "the device did not respond in a timely manner",
      "error": "failed to achieve transition"
    }
  ]
}
```

> 400 Response

<h3 id="get__transitions_{transitionid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[transitions_getID](#schematransitions_getid)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error prevented getting the transition|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## delete__transitions_{transitionID}

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/power-control/v1/transitions/{transitionID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /transitions/{transitionID}`

*Abort an in-progress transition*

Attempt to abort an in-progress transition by transitionID

<h3 id="delete__transitions_{transitionid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|transitionID|path|string(uuid)|true|none|

> Example responses

> 202 Response

```json
{
  "abortStatus": "Accepted - abort initiated"
}
```

> 400 Response

<h3 id="delete__transitions_{transitionid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|202|[Accepted](https://tools.ietf.org/html/rfc7231#section-6.3.3)|Accepted - abort initiated|[transitions_abort](#schematransitions_abort)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Specified transition is complete|[Problem7807](#schemaproblem7807)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|TransitionID not found|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error prevented abort signaling|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="power-control-service-pcs--power-status">power-status</h1>

Endpoints that retrieve power status of xnames

## get__power-status

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/power-status HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/power-status \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/power-status', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/power-status", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /power-status`

*Retrieve the power state*

Retrieve the power state of the component specified by xname.

<h3 id="get__power-status-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|query|array[string]|false|none|
|powerStateFilter|query|string|false|none|
|managementStateFilter|query|string|false|none|

#### Enumerated Values

|Parameter|Value|
|---|---|
|powerStateFilter|on|
|powerStateFilter|off|
|powerStateFilter|undefined|
|managementStateFilter|available|
|managementStateFilter|unavailable|

> Example responses

> 200 Response

```json
{
  "status": [
    {
      "xname": "x0c0s0b0n0",
      "powerState": "on",
      "managementState": "unavailable",
      "error": "permission denied - system credentials failed",
      "supportedPowerTransitions": [
        "soft-restart"
      ],
      "lastUpdated": "2022-08-24T16:45:53.953811137Z"
    }
  ]
}
```

> 400 Response

<h3 id="get__power-status-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[power_status_all](#schemapower_status_all)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="power-control-service-pcs--power-cap">power-cap</h1>

Endpoints that retrieve or set power cap parameters

## post__power-cap_snapshot

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/snapshot HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/snapshot \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/snapshot', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/snapshot", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /power-cap/snapshot`

*Take a power cap snapshot for a set of targets*

Get power cap snapshot for a set of targets.  This operation returns a taskID to be used for completion status queries, since this can be a long running task. Progress and status for this task can be queried via a `GET /power-cap/{taskID}`

> Body parameter

```json
{
  "xnames": [
    "x0c0s0b0n0"
  ]
}
```

<h3 id="post__power-cap_snapshot-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[power_cap_snapshot_req](#schemapower_cap_snapshot_req)|false|none|

> Example responses

> 200 Response

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1"
}
```

> 400 Response

<h3 id="post__power-cap_snapshot-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. The data was successfully retrieved|[op_task_start_response](#schemaop_task_start_response)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__power-cap

> Code samples

```http
PATCH https://api-gw-service-nmn.local/apis/power-control/v1/power-cap HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PATCH https://api-gw-service-nmn.local/apis/power-control/v1/power-cap \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.patch('https://api-gw-service-nmn.local/apis/power-control/v1/power-cap', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "https://api-gw-service-nmn.local/apis/power-control/v1/power-cap", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /power-cap`

*Set power capping parameters on a set of targets*

Set power cap parameters for a list of targets.  The PATCH payload contains the targets and the parameters to set.  This operation returns a  powercapID to be used for completion status queries, since this can be a long running task. Progress and status for this task can be queried via a `GET /power-cap/{taskID}`.

> Body parameter

```json
{
  "components": [
    {
      "xname": "x0c0s0b0n0",
      "controls": [
        {
          "name": "string",
          "value": 400
        }
      ]
    }
  ]
}
```

<h3 id="patch__power-cap-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[power_cap_patch](#schemapower_cap_patch)|false|none|

> Example responses

> 200 Response

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1"
}
```

> 400 Response

<h3 id="patch__power-cap-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. The data was successfully retrieved|[op_task_start_response](#schemaop_task_start_response)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__power-cap

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/power-cap HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/power-cap \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/power-cap', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/power-cap", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /power-cap`

*Get a list of power-cap tasks (snapshots or sets)*

> Example responses

> 200 Response

```json
{
  "tasks": [
    {
      "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1",
      "type": "snapshot",
      "taskCreateTime": "2021-04-01T19:00:00",
      "automaticExpirationTime": "2019-08-24T14:15:22Z",
      "taskStatus": "Completed",
      "taskCounts": {
        "total": 5,
        "new": 2,
        "in-progress": 2,
        "failed": 0,
        "succeeded": 1,
        "un-supported": 0
      }
    }
  ]
}
```

> 500 Response

<h3 id="get__power-cap-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. The data was successfully retrieved|[power_cap_task_list](#schemapower_cap_task_list)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__power-cap_{taskID}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/{taskID} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/{taskID} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/{taskID}', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/power-cap/{taskID}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /power-cap/{taskID}`

*Get power cap or snapshot information*

Queries the current status for the specified taskID. Use the taskID returned from a `PATCH /power-cap` or `POST /power-cap/snapshot` request.

<h3 id="get__power-cap_{taskid}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|taskID|path|[task_id](#schematask_id)|true|none|

> Example responses

> 200 Response

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1",
  "type": "snapshot",
  "taskCreateTime": "2021-04-01T19:00:00",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "taskStatus": "Completed",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x0c0s0b0n0",
      "error": "Optional error message",
      "limits": {
        "hostLimitMax": 900,
        "hostLimitMin": 360,
        "powerupPower": 250
      },
      "powerCapLimits": [
        {
          "name": "Node",
          "currentValue": 410,
          "maximumValue": 900,
          "minimumValue": 360
        }
      ]
    }
  ]
}
```

> 404 Response

<h3 id="get__power-cap_{taskid}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK. The data was successfully retrieved.  Task Info is only present for task status operations (PATCH power-cap or POST power-cap/snapshot)|[power_caps_retdata](#schemapower_caps_retdata)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|TaskID not found|[Problem7807](#schemaproblem7807)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Database error|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="power-control-service-pcs--cli_ignore">cli_ignore</h1>

## get__liveness

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/liveness HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/liveness

```

```python
import requests

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/liveness')

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Get liveness status of the service*

Get liveness status of the service

<h3 id="get__liveness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__readiness

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/readiness HTTP/1.1
Host: api-gw-service-nmn.local

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/readiness

```

```python
import requests

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/readiness')

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Get readiness status of the service*

Get readiness status of the service

<h3 id="get__readiness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|503|[Service Unavailable](https://tools.ietf.org/html/rfc7231#section-6.6.4)|The service is not taking HTTP requests|None|

<aside class="success">
This operation does not require authentication
</aside>

## get__health

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/power-control/v1/health HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/power-control/v1/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('https://api-gw-service-nmn.local/apis/power-control/v1/health', headers = headers)

print(r.json())

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/power-control/v1/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Query the health of the service*

The `health` resource returns health information about the PCS service and its dependencies. This actively checks the connection between  PCS and the following:

  * KV store
  * Distributed locking subsystem
  * Hardware State Manager
  * Vault
  * Task Runner Service status and mode

This is primarily intended as a diagnostic tool to investigate the functioning of the PCS service.

> Example responses

> 200 Response

```json
{
  "KvStore": "connected, responsive",
  "StateManager": "connected, responsive",
  "BackingStore": "connected, responsive",
  "Vault": "connected, responsive",
  "TaskRunnerMode": "connected, responsive, local mode"
}
```

<h3 id="get__health-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|[health_rsp](#schemahealth_rsp)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted. For /health, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_power_status">power_status</h2>
<!-- backwards compatibility -->
<a id="schemapower_status"></a>
<a id="schema_power_status"></a>
<a id="tocSpower_status"></a>
<a id="tocspower_status"></a>

```json
{
  "xname": "x0c0s0b0n0",
  "powerState": "on",
  "managementState": "unavailable",
  "error": "permission denied - system credentials failed",
  "supportedPowerTransitions": [
    "soft-restart"
  ],
  "lastUpdated": "2022-08-24T16:45:53.953811137Z"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|powerState|string|false|none|What the power state was detected.|
|managementState|string|false|none|Describes if the device is currently available for commands via its management controller|
|error|string¦null|false|none|none|
|supportedPowerTransitions|[string]|false|none|none|
|lastUpdated|string(date-time)|false|read-only|none|

#### Enumerated Values

|Property|Value|
|---|---|
|powerState|on|
|powerState|off|
|powerState|undefined|
|managementState|unavailable|
|managementState|available|

<h2 id="tocS_power_status_all">power_status_all</h2>
<!-- backwards compatibility -->
<a id="schemapower_status_all"></a>
<a id="schema_power_status_all"></a>
<a id="tocSpower_status_all"></a>
<a id="tocspower_status_all"></a>

```json
{
  "status": [
    {
      "xname": "x0c0s0b0n0",
      "powerState": "on",
      "managementState": "unavailable",
      "error": "permission denied - system credentials failed",
      "supportedPowerTransitions": [
        "soft-restart"
      ],
      "lastUpdated": "2022-08-24T16:45:53.953811137Z"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|status|[[power_status](#schemapower_status)]|false|none|none|

<h2 id="tocS_transitions_getID">transitions_getID</h2>
<!-- backwards compatibility -->
<a id="schematransitions_getid"></a>
<a id="schema_transitions_getID"></a>
<a id="tocStransitions_getid"></a>
<a id="tocstransitions_getid"></a>

```json
{
  "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
  "createTime": "2020-12-16T19:00:20",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "transitionStatus": "in-progress",
  "operation": "force-off",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "tasks": [
    {
      "xname": "x0c0s0b0n0",
      "taskStatus": "failed",
      "taskStatusDescription": "the device did not respond in a timely manner",
      "error": "failed to achieve transition"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|transitionID|string(uuid)|false|none|none|
|createTime|string|false|none|none|
|automaticExpirationTime|string(date-time)|false|none|When the record will be deleted|
|transitionStatus|string|false|none|none|
|operation|string|false|none|none|
|taskCounts|[task_counts](#schematask_counts)|false|none|none|
|tasks|[[transition_task_data](#schematransition_task_data)]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|transitionStatus|new|
|transitionStatus|in-progress|
|transitionStatus|completed|
|transitionStatus|aborted|
|transitionStatus|abort-signaled|
|operation|on|
|operation|off|
|operation|soft-restart|
|operation|hard-restart|
|operation|init|
|operation|force-off|
|operation|soft-off|

<h2 id="tocS_transitions_getAll">transitions_getAll</h2>
<!-- backwards compatibility -->
<a id="schematransitions_getall"></a>
<a id="schema_transitions_getAll"></a>
<a id="tocStransitions_getall"></a>
<a id="tocstransitions_getall"></a>

```json
{
  "transitions": [
    {
      "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
      "createTime": "2020-12-16T19:00:20",
      "automaticExpirationTime": "2019-08-24T14:15:22Z",
      "transitionStatus": "in-progress",
      "operation": "force-off",
      "taskCounts": {
        "total": 5,
        "new": 2,
        "in-progress": 2,
        "failed": 0,
        "succeeded": 1,
        "un-supported": 0
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|transitions|[[transitions_get](#schematransitions_get)]|false|none|none|

<h2 id="tocS_transitions_get">transitions_get</h2>
<!-- backwards compatibility -->
<a id="schematransitions_get"></a>
<a id="schema_transitions_get"></a>
<a id="tocStransitions_get"></a>
<a id="tocstransitions_get"></a>

```json
{
  "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
  "createTime": "2020-12-16T19:00:20",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "transitionStatus": "in-progress",
  "operation": "force-off",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|transitionID|string(uuid)|false|none|none|
|createTime|string|false|none|none|
|automaticExpirationTime|string(date-time)|false|none|When the record will be deleted|
|transitionStatus|string|false|none|none|
|operation|string|false|none|none|
|taskCounts|[task_counts](#schematask_counts)|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|transitionStatus|in-progress|
|transitionStatus|new|
|transitionStatus|completed|
|transitionStatus|aborted|
|transitionStatus|abort-signaled|
|operation|on|
|operation|off|
|operation|soft-restart|
|operation|hard-restart|
|operation|init|
|operation|force-off|
|operation|soft-off|

<h2 id="tocS_transition_start_output">transition_start_output</h2>
<!-- backwards compatibility -->
<a id="schematransition_start_output"></a>
<a id="schema_transition_start_output"></a>
<a id="tocStransition_start_output"></a>
<a id="tocstransition_start_output"></a>

```json
{
  "transitionID": "8dd3e1a5-ae40-4761-b8fe-6c489e965fbd",
  "operation": "on"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|transitionID|string(uuid)|false|none|none|
|operation|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|operation|on|
|operation|off|
|operation|soft-restart|
|operation|hard-restart|
|operation|init|
|operation|force-off|
|operation|soft-off|

<h2 id="tocS_transitions_abort">transitions_abort</h2>
<!-- backwards compatibility -->
<a id="schematransitions_abort"></a>
<a id="schema_transitions_abort"></a>
<a id="tocStransitions_abort"></a>
<a id="tocstransitions_abort"></a>

```json
{
  "abortStatus": "Accepted - abort initiated"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|abortStatus|string|false|none|none|

<h2 id="tocS_transition_task_data">transition_task_data</h2>
<!-- backwards compatibility -->
<a id="schematransition_task_data"></a>
<a id="schema_transition_task_data"></a>
<a id="tocStransition_task_data"></a>
<a id="tocstransition_task_data"></a>

```json
{
  "xname": "x0c0s0b0n0",
  "taskStatus": "failed",
  "taskStatusDescription": "the device did not respond in a timely manner",
  "error": "failed to achieve transition"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|taskStatus|string|false|none|none|
|taskStatusDescription|string|false|none|none|
|error|string|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|taskStatus|new|
|taskStatus|in-progress|
|taskStatus|failed|
|taskStatus|succeeded|
|taskStatus|unsupported|

<h2 id="tocS_reserved_location">reserved_location</h2>
<!-- backwards compatibility -->
<a id="schemareserved_location"></a>
<a id="schema_reserved_location"></a>
<a id="tocSreserved_location"></a>
<a id="tocsreserved_location"></a>

```json
{
  "xname": "x0c0s0b0n0",
  "deputyKey": "80838f7c-04e3-4cf6-8456-6bd557a0f1be"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|[xname](#schemaxname)|true|none|The xname of this piece of hardware|
|deputyKey|string(uuid)|false|none|none|

<h2 id="tocS_transition_create">transition_create</h2>
<!-- backwards compatibility -->
<a id="schematransition_create"></a>
<a id="schema_transition_create"></a>
<a id="tocStransition_create"></a>
<a id="tocstransition_create"></a>

```json
{
  "operation": "force-off",
  "taskDeadlineMinutes": 0,
  "location": [
    {
      "xname": "x0c0s0b0n0",
      "deputyKey": "80838f7c-04e3-4cf6-8456-6bd557a0f1be"
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|operation|string|false|none|The operation that should be applied to the hardware.|
|taskDeadlineMinutes|integer|false|none|The number of minutes to wait for a single transition task  to complete before continuing.  Defaults to 5 minutes, if unspecified. 0 disables waiting. -1 waits as long as it takes.|
|location|[[reserved_location](#schemareserved_location)]|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|operation|on|
|operation|off|
|operation|soft-off|
|operation|soft-restart|
|operation|hard-restart|
|operation|init|
|operation|force-off|

<h2 id="tocS_task_counts">task_counts</h2>
<!-- backwards compatibility -->
<a id="schematask_counts"></a>
<a id="schema_task_counts"></a>
<a id="tocStask_counts"></a>
<a id="tocstask_counts"></a>

```json
{
  "total": 5,
  "new": 2,
  "in-progress": 2,
  "failed": 0,
  "succeeded": 1,
  "un-supported": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|total|integer|false|none|none|
|new|integer|false|none|none|
|in-progress|integer|false|none|none|
|failed|integer|false|none|none|
|succeeded|integer|false|none|none|
|un-supported|integer|false|none|none|

<h2 id="tocS_Problem7807">Problem7807</h2>
<!-- backwards compatibility -->
<a id="schemaproblem7807"></a>
<a id="schema_Problem7807"></a>
<a id="tocSproblem7807"></a>
<a id="tocsproblem7807"></a>

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "statusCode": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}

```

RFC 7807 compliant error payload. All fields are optional except the 'type' field.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string|true|none|none|
|detail|string|false|none|none|
|instance|string|false|none|none|
|statusCode|number(integer)|false|none|none|
|title|string|false|none|none|

<h2 id="tocS_xname">xname</h2>
<!-- backwards compatibility -->
<a id="schemaxname"></a>
<a id="schema_xname"></a>
<a id="tocSxname"></a>
<a id="tocsxname"></a>

```json
"x0c0s0b0n0"

```

The xname of this piece of hardware

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|The xname of this piece of hardware|

<h2 id="tocS_task_id">task_id</h2>
<!-- backwards compatibility -->
<a id="schematask_id"></a>
<a id="schema_task_id"></a>
<a id="tocStask_id"></a>
<a id="tocstask_id"></a>

```json
"497f6eca-6276-4993-bfeb-53cbbbba6f08"

```

Task ID from power-cap, snapshot operation

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string(uuid)|false|none|Task ID from power-cap, snapshot operation|

<h2 id="tocS_power_cap_patch">power_cap_patch</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_patch"></a>
<a id="schema_power_cap_patch"></a>
<a id="tocSpower_cap_patch"></a>
<a id="tocspower_cap_patch"></a>

```json
{
  "components": [
    {
      "xname": "x0c0s0b0n0",
      "controls": [
        {
          "name": "string",
          "value": 400
        }
      ]
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|components|[[power_cap_patch_component](#schemapower_cap_patch_component)]|false|none|none|

<h2 id="tocS_power_cap_patch_component">power_cap_patch_component</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_patch_component"></a>
<a id="schema_power_cap_patch_component"></a>
<a id="tocSpower_cap_patch_component"></a>
<a id="tocspower_cap_patch_component"></a>

```json
{
  "xname": "x0c0s0b0n0",
  "controls": [
    {
      "name": "string",
      "value": 400
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|controls|[[power_cap_patch_component_control](#schemapower_cap_patch_component_control)]|false|none|none|

<h2 id="tocS_power_cap_patch_component_control">power_cap_patch_component_control</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_patch_component_control"></a>
<a id="schema_power_cap_patch_component_control"></a>
<a id="tocSpower_cap_patch_component_control"></a>
<a id="tocspower_cap_patch_component_control"></a>

```json
{
  "name": "string",
  "value": 400
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|value|integer|false|none|none|

<h2 id="tocS_op_task_start_response">op_task_start_response</h2>
<!-- backwards compatibility -->
<a id="schemaop_task_start_response"></a>
<a id="schema_op_task_start_response"></a>
<a id="tocSop_task_start_response"></a>
<a id="tocsop_task_start_response"></a>

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|taskID|string(uuid)|false|none|none|

<h2 id="tocS_power_caps_retdata">power_caps_retdata</h2>
<!-- backwards compatibility -->
<a id="schemapower_caps_retdata"></a>
<a id="schema_power_caps_retdata"></a>
<a id="tocSpower_caps_retdata"></a>
<a id="tocspower_caps_retdata"></a>

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1",
  "type": "snapshot",
  "taskCreateTime": "2021-04-01T19:00:00",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "taskStatus": "Completed",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  },
  "components": [
    {
      "xname": "x0c0s0b0n0",
      "error": "Optional error message",
      "limits": {
        "hostLimitMax": 900,
        "hostLimitMin": 360,
        "powerupPower": 250
      },
      "powerCapLimits": [
        {
          "name": "Node",
          "currentValue": 410,
          "maximumValue": 900,
          "minimumValue": 360
        }
      ]
    }
  ]
}

```

### Properties

allOf

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[power_cap_task_info](#schemapower_cap_task_info)|false|none|none|

and

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|object|false|none|none|
|» components|[[rsp_power_cap_components](#schemarsp_power_cap_components)]|false|none|none|

<h2 id="tocS_power_cap_task_list">power_cap_task_list</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_task_list"></a>
<a id="schema_power_cap_task_list"></a>
<a id="tocSpower_cap_task_list"></a>
<a id="tocspower_cap_task_list"></a>

```json
{
  "tasks": [
    {
      "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1",
      "type": "snapshot",
      "taskCreateTime": "2021-04-01T19:00:00",
      "automaticExpirationTime": "2019-08-24T14:15:22Z",
      "taskStatus": "Completed",
      "taskCounts": {
        "total": 5,
        "new": 2,
        "in-progress": 2,
        "failed": 0,
        "succeeded": 1,
        "un-supported": 0
      }
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|tasks|[[power_cap_task_info](#schemapower_cap_task_info)]|false|none|none|

<h2 id="tocS_power_cap_task_info">power_cap_task_info</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_task_info"></a>
<a id="schema_power_cap_task_info"></a>
<a id="tocSpower_cap_task_info"></a>
<a id="tocspower_cap_task_info"></a>

```json
{
  "taskID": "e6d742d9-0922-4edc-baeb-3e1ecb0579d1",
  "type": "snapshot",
  "taskCreateTime": "2021-04-01T19:00:00",
  "automaticExpirationTime": "2019-08-24T14:15:22Z",
  "taskStatus": "Completed",
  "taskCounts": {
    "total": 5,
    "new": 2,
    "in-progress": 2,
    "failed": 0,
    "succeeded": 1,
    "un-supported": 0
  }
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|taskID|string(uuid)|false|none|none|
|type|string|false|none|The task can either be the result of a snapshot or a patch|
|taskCreateTime|string|false|none|none|
|automaticExpirationTime|string(date-time)|false|none|When the record will be deleted|
|taskStatus|string|false|none|none|
|taskCounts|[task_counts](#schematask_counts)|false|none|none|

#### Enumerated Values

|Property|Value|
|---|---|
|type|snapshot|
|type|patch|

<h2 id="tocS_power_cap_snapshot_req">power_cap_snapshot_req</h2>
<!-- backwards compatibility -->
<a id="schemapower_cap_snapshot_req"></a>
<a id="schema_power_cap_snapshot_req"></a>
<a id="tocSpower_cap_snapshot_req"></a>
<a id="tocspower_cap_snapshot_req"></a>

```json
{
  "xnames": [
    "x0c0s0b0n0"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xnames|[[xname](#schemaxname)]|false|none|[The xname of this piece of hardware]|

<h2 id="tocS_rsp_power_cap_components">rsp_power_cap_components</h2>
<!-- backwards compatibility -->
<a id="schemarsp_power_cap_components"></a>
<a id="schema_rsp_power_cap_components"></a>
<a id="tocSrsp_power_cap_components"></a>
<a id="tocsrsp_power_cap_components"></a>

```json
{
  "xname": "x0c0s0b0n0",
  "error": "Optional error message",
  "limits": {
    "hostLimitMax": 900,
    "hostLimitMin": 360,
    "powerupPower": 250
  },
  "powerCapLimits": [
    {
      "name": "Node",
      "currentValue": 410,
      "maximumValue": 900,
      "minimumValue": 360
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|xname|[xname](#schemaxname)|false|none|The xname of this piece of hardware|
|error|string|false|none|nullable error field|
|limits|[capabilities_limits](#schemacapabilities_limits)|false|none|none|
|powerCapLimits|[[rsp_power_cap_components_control](#schemarsp_power_cap_components_control)]|false|none|none|

<h2 id="tocS_rsp_power_cap_components_control">rsp_power_cap_components_control</h2>
<!-- backwards compatibility -->
<a id="schemarsp_power_cap_components_control"></a>
<a id="schema_rsp_power_cap_components_control"></a>
<a id="tocSrsp_power_cap_components_control"></a>
<a id="tocsrsp_power_cap_components_control"></a>

```json
{
  "name": "Node",
  "currentValue": 410,
  "maximumValue": 900,
  "minimumValue": 360
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|currentValue|integer|false|none|The current power cap limit as reported by the device|
|maximumValue|integer|false|none|The maximum power cap limit the device may be set to|
|minimumValue|integer|false|none|The minimum power cap limit the device may be set to|

#### Enumerated Values

|Property|Value|
|---|---|
|name|Node|
|name|Accel|

<h2 id="tocS_capabilities_limits">capabilities_limits</h2>
<!-- backwards compatibility -->
<a id="schemacapabilities_limits"></a>
<a id="schema_capabilities_limits"></a>
<a id="tocScapabilities_limits"></a>
<a id="tocscapabilities_limits"></a>

```json
{
  "hostLimitMax": 900,
  "hostLimitMin": 360,
  "powerupPower": 250
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|hostLimitMax|integer|false|none|Node maximum power draw, measured in watts, as reported by underlying Redfish implementation|
|hostLimitMin|integer|false|none|Node minimum power draw, measured in watts, as reported by underlying Redfish implementation|
|powerupPower|integer|false|none|Typical power consumption of each node during hardware initialization, specified in watts|

<h2 id="tocS_health_rsp">health_rsp</h2>
<!-- backwards compatibility -->
<a id="schemahealth_rsp"></a>
<a id="schema_health_rsp"></a>
<a id="tocShealth_rsp"></a>
<a id="tocshealth_rsp"></a>

```json
{
  "KvStore": "connected, responsive",
  "StateManager": "connected, responsive",
  "BackingStore": "connected, responsive",
  "Vault": "connected, responsive",
  "TaskRunnerMode": "connected, responsive, local mode"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|KvStore|string|true|none|Status of the KV Store.|
|DistLocking|string|true|none|Status of the distributed locking mechanism|
|StateManager|string|true|none|Status of the connection to the Hardware State Manager.|
|Vault|string|true|none|Status of the connection to Vault.|
|TaskRunner|any|true|none|TRS status and mode (local or remote/worker).|

