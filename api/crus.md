<!-- Generator: Widdershins v4.0.1 -->

<h1 id="compute-rolling-upgrade-service">Compute Rolling Upgrade Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Compute Rolling Upgrade Service (CRUS) coordinates with workload managers
and the Boot Orchestration Service (BOS) to modify the boot image and/or
configuration on a set of compute nodes in a way that is minimally disruptive
to the overall ability of the computes to run jobs.

CRUS divides the set of nodes into groups and, for each group in turn, it performs
the following procedure:
1. Quiesces the nodes using the workload manager.
2. Takes the nodes out of service in the workload manager.
3. Creates a BOS reboot operation on the nodes using the specified BOS session template.
4. Puts the nodes back into service using the workload manager.

Each group of nodes must complete this procedure before the next group begins it. In
this way most of the total set of nodes remains available to do work while each smaller
group is being updated.

## Resources

### /session

A CRUS session performs a rolling upgrade on a set of compute nodes.

## Workflow

### Create a New Session

#### POST /session

A new session is launched as a result of this call.

Specify the following parameters:
* failed_label: An empty Hardware State Manager (HSM) group which CRUS will populate
with any nodes that fail their upgrades.
* starting_label: An HSM group which contains the total set of nodes to be upgraded.
* upgrade_step_size: The number of nodes to include in each discrete upgrade step.
The upgrade steps will never exceed this quantity, although in some cases they
may be smaller.
* upgrade_template_id: The name of the BOS session template to use for the upgrades.
* workload_manager_type: Currently only slurm is supported.
* upgrading_label: An empty HSM group which CRUS will use to boot and configure
the discrete sets of nodes.

### Examine a Session

#### GET /session/{upgrade_id}

Retrieve session details and status by upgrade id.

### List All Sessions

#### GET /session

List all in progress and completed sessions.

### Request a Session Be Deleted

#### DELETE /session/{upgrade_id}

Request a deletion of the specified CRUS session. Note that the delete may not happen
immediately.

## Interactions with Other APIs

CRUS works in concert with BOS to perform the node upgrades. The session template
specified as the upgrade template must be available in BOS.
CRUS uses HSM to view the starting node group and modify the upgrading and (if
necessary) failed node groups.

Base URLs:

* <a href="https://api-gw-service-nmn.local/apis/crus">https://api-gw-service-nmn.local/apis/crus</a>

# Authentication

- HTTP Authentication, scheme: bearer 

<h1 id="compute-rolling-upgrade-service-default">Default</h1>

## post__session

> Code samples

```http
POST https://api-gw-service-nmn.local/apis/crus/session HTTP/1.1
Host: api-gw-service-nmn.local
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST https://api-gw-service-nmn.local/apis/crus/session \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.post('https://api-gw-service-nmn.local/apis/crus/session', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "https://api-gw-service-nmn.local/apis/crus/session", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /session`

*Create a session*

The creation of a session performs a rolling upgrade
using the specified session template on the nodes
specified in the starting group.

> Body parameter

```json
{
  "failed_label": "nodes-that-failed",
  "starting_label": "nodes-to-upgrade",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}
```

<h3 id="post__session-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[Session](#schemasession)|true|A JSON object for creating a Session|

> Example responses

> 201 Response

```json
{
  "api_version": "2.71.828",
  "completed": true,
  "failed_label": "nodes-that-failed",
  "kind": "ComputeUpgradeSession",
  "messages": [
    "string"
  ],
  "starting_label": "nodes-to-upgrade",
  "state": "UPDATING",
  "upgrade_id": "c926acf6-b5c6-411e-ba6c-ea0448cab2ee",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}
```

<h3 id="post__session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|201|[Created](https://tools.ietf.org/html/rfc7231#section-6.3.2)|The status of the CRUS session.|[SessionStatus](#schemasessionstatus)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|None|
|422|[Unprocessable Entity](https://tools.ietf.org/html/rfc2518#section-10.3)|Unprocessable Entity|None|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get__session

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/crus/session HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/crus/session \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/crus/session', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/crus/session", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /session`

*List sessions*

List all sessions, including those in progress and those complete.

> Example responses

> 200 Response

```json
[
  {
    "api_version": "2.71.828",
    "completed": true,
    "failed_label": "nodes-that-failed",
    "kind": "ComputeUpgradeSession",
    "messages": [
      "string"
    ],
    "starting_label": "nodes-to-upgrade",
    "state": "UPDATING",
    "upgrade_id": "c926acf6-b5c6-411e-ba6c-ea0448cab2ee",
    "upgrade_step_size": 30,
    "upgrade_template_id": "my-bos-session-template",
    "upgrading_label": "nodes-currently-upgrading",
    "workload_manager_type": "slurm"
  }
]
```

<h3 id="get__session-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|A collection of Sessions|Inline|

<h3 id="get__session-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[SessionStatus](#schemasessionstatus)]|false|none|[The status for a CRUS Session.]|
|» api_version|string|true|none|Version of the API that created the session.|
|» completed|boolean|true|none|Whether or not the CRUS session has completed.|
|» failed_label|string|true|none|A Hardware State Manager (HSM) group which CRUS will populate<br>with any nodes that fail their upgrades.|
|» kind|string|true|none|The kind of CRUS session. Currently only ComputeUpgradeSession.|
|» messages|[string]|true|none|Status messages describing the progress of the session.|
|» starting_label|string|true|none|A Hardware State Manager (HSM) group which contains the total set of<br>nodes to be upgraded.|
|» state|string|true|none|Current state of the session.|
|» upgrade_id|string(uuid)|true|none|The ID of the CRUS session.|
|» upgrade_step_size|integer|true|none|The desired number of nodes for each discrete upgrade step. This quantity<br>will not be exceeded but some steps may use fewer nodes.|
|» upgrade_template_id|string|true|none|The name of the Boot Orchestration Service (BOS) session template for the<br>CRUS session upgrades.|
|» upgrading_label|string|true|none|A Hardware State Manager (HSM) group which the CRUS session will use<br>to boot and configure the discrete sets of nodes.|
|» workload_manager_type|string|true|none|The name of the workload manager.|

#### Enumerated Values

|Property|Value|
|---|---|
|kind|ComputeUpgradeSession|
|state|CREATED|
|state|READY|
|state|DELETING|
|state|UPDATING|
|workload_manager_type|slurm|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## get__session_{upgrade_id}

> Code samples

```http
GET https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X GET https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.get('https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id}', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /session/{upgrade_id}`

*Retrieve session details by id*

Retrieve session details by upgrade_id.

<h3 id="get__session_{upgrade_id}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|upgrade_id|path|string(uuid)|true|Upgrade ID|

> Example responses

> 200 Response

```json
{
  "api_version": "2.71.828",
  "completed": true,
  "failed_label": "nodes-that-failed",
  "kind": "ComputeUpgradeSession",
  "messages": [
    "string"
  ],
  "starting_label": "nodes-to-upgrade",
  "state": "UPDATING",
  "upgrade_id": "c926acf6-b5c6-411e-ba6c-ea0448cab2ee",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}
```

<h3 id="get__session_{upgrade_id}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The status of the CRUS session.|[SessionStatus](#schemasessionstatus)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|None|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

## delete__session_{upgrade_id}

> Code samples

```http
DELETE https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id} HTTP/1.1
Host: api-gw-service-nmn.local
Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id} \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer {access-token}'

```

```python
import requests
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer {access-token}'
}

r = requests.delete('https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id}', headers = headers)

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
        "Authorization": []string{"Bearer {access-token}"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "https://api-gw-service-nmn.local/apis/crus/session/{upgrade_id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /session/{upgrade_id}`

*Delete session by id*

Delete session by upgrade_id.

<h3 id="delete__session_{upgrade_id}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|upgrade_id|path|string(uuid)|true|Upgrade ID|

> Example responses

> 200 Response

```json
{
  "api_version": "2.71.828",
  "completed": true,
  "failed_label": "nodes-that-failed",
  "kind": "ComputeUpgradeSession",
  "messages": [
    "string"
  ],
  "starting_label": "nodes-to-upgrade",
  "state": "UPDATING",
  "upgrade_id": "c926acf6-b5c6-411e-ba6c-ea0448cab2ee",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}
```

<h3 id="delete__session_{upgrade_id}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|The status of the CRUS session.|[SessionStatus](#schemasessionstatus)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|None|

<aside class="warning">
To perform this operation, you must be authenticated by means of one of the following methods:
bearerAuth
</aside>

# Schemas

<h2 id="tocS_Session">Session</h2>
<!-- backwards compatibility -->
<a id="schemasession"></a>
<a id="schema_Session"></a>
<a id="tocSsession"></a>
<a id="tocssession"></a>

```json
{
  "failed_label": "nodes-that-failed",
  "starting_label": "nodes-to-upgrade",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}

```

A CRUS Session object.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|failed_label|string|true|none|An empty Hardware State Manager (HSM) group which CRUS will populate<br>with any nodes that fail their upgrades.|
|starting_label|string|true|none|A Hardware State Manager (HSM) group which contains the total set of<br>nodes to be upgraded.|
|upgrade_step_size|integer|true|none|The desired number of nodes for each discrete upgrade step. This quantity<br>will not be exceeded but some steps may use fewer nodes.|
|upgrade_template_id|string|true|none|The name of the Boot Orchestration Service (BOS) session template to use<br>for the upgrades.|
|upgrading_label|string|true|none|An empty Hardware State Manager (HSM) group which CRUS will use to boot<br>and configure the discrete sets of nodes.|
|workload_manager_type|string|true|none|The name of the workload manager. Currently only slurm is supported.|

#### Enumerated Values

|Property|Value|
|---|---|
|workload_manager_type|slurm|

<h2 id="tocS_SessionStatus">SessionStatus</h2>
<!-- backwards compatibility -->
<a id="schemasessionstatus"></a>
<a id="schema_SessionStatus"></a>
<a id="tocSsessionstatus"></a>
<a id="tocssessionstatus"></a>

```json
{
  "api_version": "2.71.828",
  "completed": true,
  "failed_label": "nodes-that-failed",
  "kind": "ComputeUpgradeSession",
  "messages": [
    "string"
  ],
  "starting_label": "nodes-to-upgrade",
  "state": "UPDATING",
  "upgrade_id": "c926acf6-b5c6-411e-ba6c-ea0448cab2ee",
  "upgrade_step_size": 30,
  "upgrade_template_id": "my-bos-session-template",
  "upgrading_label": "nodes-currently-upgrading",
  "workload_manager_type": "slurm"
}

```

The status for a CRUS Session.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|api_version|string|true|none|Version of the API that created the session.|
|completed|boolean|true|none|Whether or not the CRUS session has completed.|
|failed_label|string|true|none|A Hardware State Manager (HSM) group which CRUS will populate<br>with any nodes that fail their upgrades.|
|kind|string|true|none|The kind of CRUS session. Currently only ComputeUpgradeSession.|
|messages|[string]|true|none|Status messages describing the progress of the session.|
|starting_label|string|true|none|A Hardware State Manager (HSM) group which contains the total set of<br>nodes to be upgraded.|
|state|string|true|none|Current state of the session.|
|upgrade_id|string(uuid)|true|none|The ID of the CRUS session.|
|upgrade_step_size|integer|true|none|The desired number of nodes for each discrete upgrade step. This quantity<br>will not be exceeded but some steps may use fewer nodes.|
|upgrade_template_id|string|true|none|The name of the Boot Orchestration Service (BOS) session template for the<br>CRUS session upgrades.|
|upgrading_label|string|true|none|A Hardware State Manager (HSM) group which the CRUS session will use<br>to boot and configure the discrete sets of nodes.|
|workload_manager_type|string|true|none|The name of the workload manager.|

#### Enumerated Values

|Property|Value|
|---|---|
|kind|ComputeUpgradeSession|
|state|CREATED|
|state|READY|
|state|DELETING|
|state|UPDATING|
|workload_manager_type|slurm|

