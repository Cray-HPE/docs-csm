<!-- Generator: Widdershins v4.0.1 -->

<h1 id="ncn-lifecycle-service">NCN Lifecycle Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

Base URLs:

* <a href="/apis">/apis</a>

<h1 id="ncn-lifecycle-service-ncn-lifecycle-events">NCN Lifecycle Events</h1>

## post__nls_v1_ncns_reboot

> Code samples

```http
POST /apis/nls/v1/ncns/reboot HTTP/1.1

Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/nls/v1/ncns/reboot \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('/apis/nls/v1/ncns/reboot', headers = headers)

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
    req, err := http.NewRequest("POST", "/apis/nls/v1/ncns/reboot", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /nls/v1/ncns/reboot`

*End to end rolling reboot ncns*

> Body parameter

```json
{
  "dryRun": true,
  "hosts": [
    "string"
  ],
  "switchPassword": "string",
  "wipeOsd": true
}
```

<h3 id="post__nls_v1_ncns_reboot-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[models.CreateRebootWorkflowRequest](#schemamodels.createrebootworkflowrequest)|true|hostnames to include|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "targetNcns": [
    "string"
  ]
}
```

<h3 id="post__nls_v1_ncns_reboot-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[models.CreateRebootWorkflowResponse](#schemamodels.createrebootworkflowresponse)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

## post__nls_v1_ncns_rebuild

> Code samples

```http
POST /apis/nls/v1/ncns/rebuild HTTP/1.1

Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST /apis/nls/v1/ncns/rebuild \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('/apis/nls/v1/ncns/rebuild', headers = headers)

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
    req, err := http.NewRequest("POST", "/apis/nls/v1/ncns/rebuild", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /nls/v1/ncns/rebuild`

*End to end rolling rebuild ncns*

> Body parameter

```json
{
  "desiredCfsConfig": "string",
  "dryRun": true,
  "hosts": [
    "string"
  ],
  "imageId": "string",
  "labels": {
    "property1": "string",
    "property2": "string"
  },
  "switchPassword": "string",
  "workflowType": "string",
  "zapOsds": true
}
```

<h3 id="post__nls_v1_ncns_rebuild-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[models.CreateRebuildWorkflowRequest](#schemamodels.createrebuildworkflowrequest)|true|hostnames to include|

> Example responses

> 200 Response

```json
{
  "name": "string",
  "targetNcns": [
    "string"
  ]
}
```

<h3 id="post__nls_v1_ncns_rebuild-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[models.CreateRebuildWorkflowResponse](#schemamodels.createrebuildworkflowresponse)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="ncn-lifecycle-service-workflow-management">Workflow Management</h1>

## get__nls_v1_workflows

> Code samples

```http
GET /apis/nls/v1/workflows HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X GET /apis/nls/v1/workflows \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('/apis/nls/v1/workflows', headers = headers)

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
    req, err := http.NewRequest("GET", "/apis/nls/v1/workflows", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /nls/v1/workflows`

*Get status of a ncn workflow*

<h3 id="get__nls_v1_workflows-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|labelSelector|query|string|false|Label Selector|

> Example responses

> 200 Response

```json
[
  {
    "label": {},
    "name": "string",
    "status": {}
  }
]
```

<h3 id="get__nls_v1_workflows-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|Inline|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<h3 id="get__nls_v1_workflows-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|[[models.GetWorkflowResponse](#schemamodels.getworkflowresponse)]|false|none|none|
|» label|object|false|none|none|
|» name|string|false|none|none|
|» status|object|false|none|none|

<aside class="success">
This operation does not require authentication
</aside>

## delete__nls_v1_workflows_{name}

> Code samples

```http
DELETE /apis/nls/v1/workflows/{name} HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X DELETE /apis/nls/v1/workflows/{name} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('/apis/nls/v1/workflows/{name}', headers = headers)

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
    req, err := http.NewRequest("DELETE", "/apis/nls/v1/workflows/{name}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /nls/v1/workflows/{name}`

*Delete a ncn workflow*

<h3 id="delete__nls_v1_workflows_{name}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|path|string|true|name of workflow|

> Example responses

> 200 Response

```json
{
  "message": "string"
}
```

<h3 id="delete__nls_v1_workflows_{name}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ResponseOk](#schemaresponseok)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

## put__nls_v1_workflows_{name}_rerun

> Code samples

```http
PUT /apis/nls/v1/workflows/{name}/rerun HTTP/1.1

Accept: application/json

```

```shell
# You can also use wget
curl -X PUT /apis/nls/v1/workflows/{name}/rerun \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.put('/apis/nls/v1/workflows/{name}/rerun', headers = headers)

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
    req, err := http.NewRequest("PUT", "/apis/nls/v1/workflows/{name}/rerun", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /nls/v1/workflows/{name}/rerun`

*Rerun a workflow, all steps will run*

<h3 id="put__nls_v1_workflows_{name}_rerun-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|path|string|true|name of workflow|

> Example responses

> 200 Response

```json
{
  "message": "string"
}
```

<h3 id="put__nls_v1_workflows_{name}_rerun-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ResponseOk](#schemaresponseok)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

## put__nls_v1_workflows_{name}_retry

> Code samples

```http
PUT /apis/nls/v1/workflows/{name}/retry HTTP/1.1

Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X PUT /apis/nls/v1/workflows/{name}/retry \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.put('/apis/nls/v1/workflows/{name}/retry', headers = headers)

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
    req, err := http.NewRequest("PUT", "/apis/nls/v1/workflows/{name}/retry", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PUT /nls/v1/workflows/{name}/retry`

*Retry a failed ncn workflow, skip passed steps*

> Body parameter

```json
{
  "restartSuccessful": true,
  "stepName": "string"
}
```

<h3 id="put__nls_v1_workflows_{name}_retry-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|name|path|string|true|name of workflow|
|body|body|[models.RetryWorkflowRequestBody](#schemamodels.retryworkflowrequestbody)|true|retry options|

> Example responses

> 200 Response

```json
{
  "message": "string"
}
```

<h3 id="put__nls_v1_workflows_{name}_retry-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK|[ResponseOk](#schemaresponseok)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request|[ResponseError](#schemaresponseerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found|[ResponseError](#schemaresponseerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error|[ResponseError](#schemaresponseerror)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_ResponseError">ResponseError</h2>
<!-- backwards compatibility -->
<a id="schemaresponseerror"></a>
<a id="schema_ResponseError"></a>
<a id="tocSresponseerror"></a>
<a id="tocsresponseerror"></a>

```json
{
  "message": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|message|string|false|none|none|

<h2 id="tocS_ResponseOk">ResponseOk</h2>
<!-- backwards compatibility -->
<a id="schemaresponseok"></a>
<a id="schema_ResponseOk"></a>
<a id="tocSresponseok"></a>
<a id="tocsresponseok"></a>

```json
{
  "message": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|message|string|false|none|none|

<h2 id="tocS_models.CreateRebootWorkflowRequest">models.CreateRebootWorkflowRequest</h2>
<!-- backwards compatibility -->
<a id="schemamodels.createrebootworkflowrequest"></a>
<a id="schema_models.CreateRebootWorkflowRequest"></a>
<a id="tocSmodels.createrebootworkflowrequest"></a>
<a id="tocsmodels.createrebootworkflowrequest"></a>

```json
{
  "dryRun": true,
  "hosts": [
    "string"
  ],
  "switchPassword": "string",
  "wipeOsd": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|dryRun|boolean|false|none|none|
|hosts|[string]|false|none|none|
|switchPassword|string|false|none|none|
|wipeOsd|boolean|false|none|none|

<h2 id="tocS_models.CreateRebootWorkflowResponse">models.CreateRebootWorkflowResponse</h2>
<!-- backwards compatibility -->
<a id="schemamodels.createrebootworkflowresponse"></a>
<a id="schema_models.CreateRebootWorkflowResponse"></a>
<a id="tocSmodels.createrebootworkflowresponse"></a>
<a id="tocsmodels.createrebootworkflowresponse"></a>

```json
{
  "name": "string",
  "targetNcns": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|targetNcns|[string]|false|none|none|

<h2 id="tocS_models.CreateRebuildWorkflowRequest">models.CreateRebuildWorkflowRequest</h2>
<!-- backwards compatibility -->
<a id="schemamodels.createrebuildworkflowrequest"></a>
<a id="schema_models.CreateRebuildWorkflowRequest"></a>
<a id="tocSmodels.createrebuildworkflowrequest"></a>
<a id="tocsmodels.createrebuildworkflowrequest"></a>

```json
{
  "desiredCfsConfig": "string",
  "dryRun": true,
  "hosts": [
    "string"
  ],
  "imageId": "string",
  "labels": {
    "property1": "string",
    "property2": "string"
  },
  "switchPassword": "string",
  "workflowType": "string",
  "zapOsds": true
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|desiredCfsConfig|string|false|none|none|
|dryRun|boolean|false|none|none|
|hosts|[string]|false|none|none|
|imageId|string|false|none|none|
|labels|object|false|none|none|
|» **additionalProperties**|string|false|none|none|
|switchPassword|string|false|none|none|
|workflowType|string|false|none|used to determine storage rebuild vs upgrade|
|zapOsds|boolean|false|none|this is necessary for storage rebuilds when unable to wipe the node prior to rebuild|

<h2 id="tocS_models.CreateRebuildWorkflowResponse">models.CreateRebuildWorkflowResponse</h2>
<!-- backwards compatibility -->
<a id="schemamodels.createrebuildworkflowresponse"></a>
<a id="schema_models.CreateRebuildWorkflowResponse"></a>
<a id="tocSmodels.createrebuildworkflowresponse"></a>
<a id="tocsmodels.createrebuildworkflowresponse"></a>

```json
{
  "name": "string",
  "targetNcns": [
    "string"
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|false|none|none|
|targetNcns|[string]|false|none|none|

<h2 id="tocS_models.GetWorkflowResponse">models.GetWorkflowResponse</h2>
<!-- backwards compatibility -->
<a id="schemamodels.getworkflowresponse"></a>
<a id="schema_models.GetWorkflowResponse"></a>
<a id="tocSmodels.getworkflowresponse"></a>
<a id="tocsmodels.getworkflowresponse"></a>

```json
{
  "label": {},
  "name": "string",
  "status": {}
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|label|object|false|none|none|
|name|string|false|none|none|
|status|object|false|none|none|

<h2 id="tocS_models.RetryWorkflowRequestBody">models.RetryWorkflowRequestBody</h2>
<!-- backwards compatibility -->
<a id="schemamodels.retryworkflowrequestbody"></a>
<a id="schema_models.RetryWorkflowRequestBody"></a>
<a id="tocSmodels.retryworkflowrequestbody"></a>
<a id="tocsmodels.retryworkflowrequestbody"></a>

```json
{
  "restartSuccessful": true,
  "stepName": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|restartSuccessful|boolean|false|none|none|
|stepName|string|false|none|none|

