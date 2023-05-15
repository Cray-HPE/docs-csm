<!-- Generator: Widdershins v4.0.1 -->

<h1 id="heartbeat-tracker-service">Heartbeat Tracker Service v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

The Heartbeat Tracker Service transfers basic node health, service state, and configuration information between compute nodes and the Hardware State Manager (HSM). The API tracks the heartbeats emitted by various system components. Generally, compute nodes emit heartbeats to inform the HSM that they are alive and healthy. Other components can also emit heartbeats if they so choose. An operating system developer may call this API to track a hardware component heartbeat. There is no Command Line (CLI) for the Heartbeat Tracker Service.
The compute nodes send heartbeats after every 3 seconds (by default) to the Heartbeat Tracker Service. The Heartbeat Tracker Service resides on the Non-Compute Node (NCN). It tracks the heartbeats received for a given component and checks them against the previous heartbeat.

Changes in heartbeat behavior are communicated to the Hardware State Manager in the following way:
* First time heartbeat received (HSM places the component in READY state)
* Heartbeat missing - If no further heartbeats arrive after the currently configured warning time interval, the component may be dead (HSM places the component in READY state with a WARNING flag). If configured to do so, this information is also dumped onto the HMS telemetry bus.
* Heartbeat missing - If still no further heartbeats arrive after the currently configured alert time interval, component is dead (HSM places component in STANDBY state with an ALERT flag). If configured to do so, this information is also dumped onto the HMS telemetry bus.

 This is a service to service communication.
## Resources
### /heartbeat
Send a heartbeat message from a compute node to the heartbeat tracker service. Heartbeat status changes like heartbeat starts or stops, are communicated to the HSM.
### /hbstates
Query the service for for the current heartbeat status of requested components.
### /params
Query and modify service operating parameters.
### /health
Retrieve health information for the service and its dependencies.
## Workflow
### Send Heartbeat Status from a Component
#### POST /heartbeat/{xname}
Send a heartbeat message to the heartbeat tracker service with a JSON formatted payload. If it's the first heartbeat, it will send a heartbeat-started message to the HSM and inform that the component is alive. Keep sending them periodically (say, every 10 seconds) to continue to have an "alive" state. If the heartbeats for a given component stop, the heartbeat tracker service will send a heartbeat-stopped message to HSM with a warning ("node might be dead") followed later by a heartbeat-stopped message to HSM with an alert ("node is dead").
### Query Heartbeat Status of Requested Components
#### POST /hbstates
Sends a list of components to the service in a JSON formatted payload. The service will respond with a JSON payload containing the same list of components, each with their XName and Heartbeating status.
#### GET /hbstate/{xname}
Query the service for the heartbeat status of a single component.  The service will respond with a JSON formatted payload containing the requested component XName and Heartbeating status.
### Retrieve and Modify Operational Parameters
#### GET /params
Retrieve current operational parameters.
#### PATCH /params
To change a parameter, perform a PATCH operation with a JSON-formatted payload containing the parameter(s) to be changed along with their new values. For example, you can set the debug level to 2. Debug parameter increases the verbosity of logging.

Base URLs:

* <a href="http://cray-hbtd/hmi/v1">http://cray-hbtd/hmi/v1</a>

* <a href="https://api-gw-service-nmn.local/apis/hbtd/hmi/v1">https://api-gw-service-nmn.local/apis/hbtd/hmi/v1</a>

<h1 id="heartbeat-tracker-service-heartbeat">heartbeat</h1>

## TrackHeartbeatXName

<a id="opIdTrackHeartbeatXName"></a>

> Code samples

```http
POST http://cray-hbtd/hmi/v1/heartbeat/{xname} HTTP/1.1
Host: cray-hbtd
Content-Type: application/json
Accept: */*

```

```shell
# You can also use wget
curl -X POST http://cray-hbtd/hmi/v1/heartbeat/{xname} \
  -H 'Content-Type: application/json' \
  -H 'Accept: */*'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': '*/*'
}

r = requests.post('http://cray-hbtd/hmi/v1/heartbeat/{xname}', headers = headers)

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
        "Accept": []string{"*/*"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "http://cray-hbtd/hmi/v1/heartbeat/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /heartbeat/{xname}`

*Send a heartbeat message*

Send a heartbeat message from a managed component like compute node to the heartbeat tracker service. To do so, a JSON object that contains the heartbeat information is sent to the heartbeat tracker service. Changes in heartbeat behavior are communicated to the Hardware State Manager.

> Body parameter

```json
{
  "Status": "Kernel Oops",
  "TimeStamp": "2018-07-06T12:34:56.012345-5Z"
}
```

<h3 id="trackheartbeatxname-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[heartbeat_xname](#schemaheartbeat_xname)|true|none|
|xname|path|[XName.1.0.0](#schemaxname.1.0.0)|true|none|

> Example responses

> 200 Response

<h3 id="trackheartbeatxname-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|[Error](#schemaerror)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON.  Verify all JSON formatting in payload. Verify that the all entries are properly set.|None|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC and/or authenticated token does not allow calling this method.  Check the authentication token expiration.  Verify that the RBAC information is correct.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /heartbeat, only POST operations are allowed.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

## TrackHeartbeat

<a id="opIdTrackHeartbeat"></a>

> Code samples

```http
POST http://cray-hbtd/hmi/v1/heartbeat HTTP/1.1
Host: cray-hbtd
Content-Type: application/json
Accept: */*

```

```shell
# You can also use wget
curl -X POST http://cray-hbtd/hmi/v1/heartbeat \
  -H 'Content-Type: application/json' \
  -H 'Accept: */*'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': '*/*'
}

r = requests.post('http://cray-hbtd/hmi/v1/heartbeat', headers = headers)

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
        "Accept": []string{"*/*"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "http://cray-hbtd/hmi/v1/heartbeat", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /heartbeat`

*Send a heartbeat message*

Send a heartbeat message from a managed component like compute node to the heartbeat tracker service. To do so, a JSON object that contains the heartbeat information is sent to the heartbeat tracker service. Changes in heartbeat behavior are communicated to the Hardware State Manager.

> Body parameter

```json
{
  "Component": "x0c1s2b0n3",
  "Hostname": "x0c1s2b0n3.us.cray.com",
  "NID": "83",
  "Status": "Kernel Oops",
  "TimeStamp": "2018-07-06T12:34:56.012345-5Z"
}
```

<h3 id="trackheartbeat-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[heartbeat](#schemaheartbeat)|true|none|

> Example responses

> 200 Response

<h3 id="trackheartbeat-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Success|[Error](#schemaerror)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON.  Verify all JSON formatting in payload. Verify that the all entries are properly set.|None|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC and/or authenticated token does not allow calling this method.  Check the authentication token expiration.  Verify that the RBAC information is correct.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /heartbeat, only POST operations are allowed.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="heartbeat-tracker-service-hbstates">hbstates</h1>

## GetHBStates

<a id="opIdGetHBStates"></a>

> Code samples

```http
POST http://cray-hbtd/hmi/v1/hbstates HTTP/1.1
Host: cray-hbtd
Content-Type: application/json
Accept: application/json

```

```shell
# You can also use wget
curl -X POST http://cray-hbtd/hmi/v1/hbstates \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://cray-hbtd/hmi/v1/hbstates', headers = headers)

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
    req, err := http.NewRequest("POST", "http://cray-hbtd/hmi/v1/hbstates", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /hbstates`

*Query the service for heartbeat status of requested components*

Sends a list of components to the service in a JSON formatted payload. The service will respond with a JSON payload containing the same list of components, each with their XName and Heartbeating status.

> Body parameter

```json
{
  "XNames": [
    "x0c1s2b0n3"
  ]
}
```

<h3 id="gethbstates-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[hbstates](#schemahbstates)|true|none|

> Example responses

> 200 Response

```json
{
  "HBStates": [
    {
      "XName": "x0c0s0b0n0",
      "Heartbeating": true
    }
  ]
}
```

> 401 Response

<h3 id="gethbstates-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The operation was successful and a payload was returned|[hbstates_rsp](#schemahbstates_rsp)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON.  Verify all JSON formatting in payload. Verify that the all entries are properly set.|None|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC and/or authenticated token does not allow calling this method.  Check the authentication token expiration.  Verify that the RBAC information is correct.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /hbstates, only POST operations are allowed.|[Error](#schemaerror)|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

## get__hbstate_{xname}

> Code samples

```http
GET http://cray-hbtd/hmi/v1/hbstate/{xname} HTTP/1.1
Host: cray-hbtd
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://cray-hbtd/hmi/v1/hbstate/{xname} \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://cray-hbtd/hmi/v1/hbstate/{xname}', headers = headers)

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
    req, err := http.NewRequest("GET", "http://cray-hbtd/hmi/v1/hbstate/{xname}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /hbstate/{xname}`

*Query the service for the heartbeat status of a single component.*

Query the service for the heartbeat status of a single component.  The service will respond with a JSON formatted payload containing the  requested component XName and heartbeating status.

<h3 id="get__hbstate_{xname}-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|xname|path|[XName.1.0.0](#schemaxname.1.0.0)|true|none|

> Example responses

> 200 Response

```json
{
  "XName": "x0c0s0b0n0",
  "Heartbeating": true
}
```

> 404 Response

<h3 id="get__hbstate_{xname}-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|OK.  The data was succesfully retrieved|[hbstates_single_rsp](#schemahbstates_single_rsp)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /hbstate/{xname}, only GET operations are allowed.|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="heartbeat-tracker-service-params">params</h1>

## get__params

> Code samples

```http
GET http://cray-hbtd/hmi/v1/params HTTP/1.1
Host: cray-hbtd
Accept: */*

```

```shell
# You can also use wget
curl -X GET http://cray-hbtd/hmi/v1/params \
  -H 'Accept: */*'

```

```python
import requests
headers = {
  'Accept': '*/*'
}

r = requests.get('http://cray-hbtd/hmi/v1/params', headers = headers)

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
        "Accept": []string{"*/*"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "http://cray-hbtd/hmi/v1/params", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /params`

*Retrieve heartbeat tracker parameters*

Fetch current heartbeat tracker configurable parameters.

> Example responses

> 200 Response

> default Response

```json
{
  "type": "string",
  "detail": "string",
  "instance": "string",
  "status": "string",
  "title": "string"
}
```

<h3 id="get__params-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Current heartbeat service operational parameter values|[params](#schemaparams)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON.  Verify all JSON formatting in payload.|[Error](#schemaerror)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC and/or authenticated token does not allow calling this method.  Check the authentication token expiration.  Verify that the RBAC information is correct.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /params, only PATCH and GET operations are allowed.|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|None|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

## patch__params

> Code samples

```http
PATCH http://cray-hbtd/hmi/v1/params HTTP/1.1
Host: cray-hbtd
Content-Type: application/json
Accept: */*

```

```shell
# You can also use wget
curl -X PATCH http://cray-hbtd/hmi/v1/params \
  -H 'Content-Type: application/json' \
  -H 'Accept: */*'

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': '*/*'
}

r = requests.patch('http://cray-hbtd/hmi/v1/params', headers = headers)

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
        "Accept": []string{"*/*"},
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("PATCH", "http://cray-hbtd/hmi/v1/params", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`PATCH /params`

*Update heartbeat tracker parameters*

Set one or more configurable parameters for the heartbeat tracker service and have them take effect immediately, without restarting the service.

> Body parameter

```json
{
  "Debug": "0",
  "Errtime": "10",
  "Warntime": "5",
  "Kv_url": "http://cray-hbtd-etcd-client:2379",
  "Interval": "5",
  "Nosm": "0",
  "Sm_retries": "3",
  "Sm_timeout": "5",
  "Sm_url": "http://cray-smd/v1/State/Components",
  "Telemetry_host": "10.2.3.4:9092:heartbeat_notifications",
  "Use_telemetry": "1"
}
```

<h3 id="patch__params-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[params](#schemaparams)|true|none|

> Example responses

> 200 Response

> default Response

```json
{
  "type": "string",
  "detail": "string",
  "instance": "string",
  "status": "string",
  "title": "string"
}
```

<h3 id="patch__params-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Current heartbeat service operational parameter values|[params](#schemaparams)|
|400|[Bad Request](https://tools.ietf.org/html/rfc7231#section-6.5.1)|Bad Request. Malformed JSON.  Verify all JSON formatting in payload.|[Error](#schemaerror)|
|401|[Unauthorized](https://tools.ietf.org/html/rfc7235#section-3.1)|Unauthorized. RBAC and/or authenticated token does not allow calling this method.  Check the authentication token expiration.  Verify that the RBAC information is correct.|[Error](#schemaerror)|
|404|[Not Found](https://tools.ietf.org/html/rfc7231#section-6.5.4)|Not Found. Endpoint not available. Check IP routing between managed and management plane. Check that any SMS node services are running on management plane. Check that SMS node API gateway service is running on management plane. Check that SMS node HMI service is running on management plane.|[Error](#schemaerror)|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation not permitted.  For /params, only PATCH and GET operations are allowed.|[Error](#schemaerror)|
|500|[Internal Server Error](https://tools.ietf.org/html/rfc7231#section-6.6.1)|Internal Server Error.  Unexpected condition encountered when processing the request.|None|
|default|Default|Unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="heartbeat-tracker-service-health">health</h1>

## get__health

> Code samples

```http
GET http://cray-hbtd/hmi/v1/health HTTP/1.1
Host: cray-hbtd
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://cray-hbtd/hmi/v1/health \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://cray-hbtd/hmi/v1/health', headers = headers)

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
    req, err := http.NewRequest("GET", "http://cray-hbtd/hmi/v1/health", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /health`

*Query the health of the service*

The `health` resource returns health information about the heartbeat tracker service and its dependencies.  This actively checks the  connection between the heartbeat tracker service and the following:

  * KV Store
  * Message Bus
  * Hardware State Manager

This is primarily intended as a diagnostic tool to investigate the functioning of the heartbeat tracker service.

> Example responses

> 200 Response

```json
{
  "KvStore": "KV Store not initialized",
  "MsgBus": "Connected and OPEN",
  "HsmStatus": "Ready"
}
```

<h3 id="get__health-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|[OK](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1) Network API call success|Inline|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /health, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<h3 id="get__health-responseschema">Response Schema</h3>

Status Code **200**

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|» KvStore|string|true|none|Status of the KV Store.|
|» MsgBus|string|true|none|Status of the connection with the message bus.|
|» HsmStatus|string|true|none|Status of the connection to the Hardware State Manager (HSM).  Any error reported by an attempt to access the HSM will be included here.|

<aside class="success">
This operation does not require authentication
</aside>

## get__liveness

> Code samples

```http
GET http://cray-hbtd/hmi/v1/liveness HTTP/1.1
Host: cray-hbtd
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://cray-hbtd/hmi/v1/liveness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://cray-hbtd/hmi/v1/liveness', headers = headers)

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
    req, err := http.NewRequest("GET", "http://cray-hbtd/hmi/v1/liveness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /liveness`

*Kubernetes liveness endpoint to monitor service health*

The `liveness` resource works in conjunction with the Kubernetes liveness probe to determine when the service is no longer responding to requests.  Too many failures of the liveness probe will result in the service being shut down and restarted.  

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="get__liveness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /liveness, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

## get__readiness

> Code samples

```http
GET http://cray-hbtd/hmi/v1/readiness HTTP/1.1
Host: cray-hbtd
Accept: application/json

```

```shell
# You can also use wget
curl -X GET http://cray-hbtd/hmi/v1/readiness \
  -H 'Accept: application/json'

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://cray-hbtd/hmi/v1/readiness', headers = headers)

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
    req, err := http.NewRequest("GET", "http://cray-hbtd/hmi/v1/readiness", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /readiness`

*Kubernetes readiness endpoint to monitor service health*

The `readiness` resource works in conjunction with the Kubernetes readiness probe to determine when the service is no longer healthy and able to respond correctly to requests.  Too many failures of the readiness probe will result in the traffic being routed away from this service and eventually the service will be shut down and restarted if in an unready state for too long.

This is primarily an endpoint for the automated Kubernetes system.

> Example responses

> 405 Response

```json
{
  "type": "about:blank",
  "detail": "Detail about this specific problem occurrence. See RFC7807",
  "instance": "",
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}
```

<h3 id="get__readiness-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|[No Content](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5) Network API call success|None|
|405|[Method Not Allowed](https://tools.ietf.org/html/rfc7231#section-6.5.5)|Operation Not Permitted.  For /readiness, only GET operations are allowed.|[Problem7807](#schemaproblem7807)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocS_heartbeat">heartbeat</h2>
<!-- backwards compatibility -->
<a id="schemaheartbeat"></a>
<a id="schema_heartbeat"></a>
<a id="tocSheartbeat"></a>
<a id="tocsheartbeat"></a>

```json
{
  "Component": "x0c1s2b0n3",
  "Hostname": "x0c1s2b0n3.us.cray.com",
  "NID": "83",
  "Status": "Kernel Oops",
  "TimeStamp": "2018-07-06T12:34:56.012345-5Z"
}

```

Heartbeat Message

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Component|[XName.1.0.0](#schemaxname.1.0.0)|true|none|Identifies sender by xname. This is the physical, location-based name of a component.|
|Hostname|[Hostname.1.0.0](#schemahostname.1.0.0)|false|none|Identifies sender by hostname. This is the host name of a component.|
|NID|[NID.1.0.0](#schemanid.1.0.0)|false|none|Identifies sender by Numeric ID (NID). This is the Numeric ID of a compute node.|
|Status|[HeartbeatStatus.1.0.0](#schemaheartbeatstatus.1.0.0)|true|none|Special status field for specific failure modes.|
|TimeStamp|[TimeStamp.1.0.0](#schematimestamp.1.0.0)|true|none|When heartbeat was sent. This is an ISO8601 formatted time stamp.|

<h2 id="tocS_heartbeat_xname">heartbeat_xname</h2>
<!-- backwards compatibility -->
<a id="schemaheartbeat_xname"></a>
<a id="schema_heartbeat_xname"></a>
<a id="tocSheartbeat_xname"></a>
<a id="tocsheartbeat_xname"></a>

```json
{
  "Status": "Kernel Oops",
  "TimeStamp": "2018-07-06T12:34:56.012345-5Z"
}

```

Heartbeat Message

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Status|[HeartbeatStatus.1.0.0](#schemaheartbeatstatus.1.0.0)|true|none|Special status field for specific failure modes.|
|TimeStamp|[TimeStamp.1.0.0](#schematimestamp.1.0.0)|true|none|When heartbeat was sent. This is an ISO8601 formatted time stamp.|

<h2 id="tocS_hbstates">hbstates</h2>
<!-- backwards compatibility -->
<a id="schemahbstates"></a>
<a id="schema_hbstates"></a>
<a id="tocShbstates"></a>
<a id="tocshbstates"></a>

```json
{
  "XNames": [
    "x0c1s2b0n3"
  ]
}

```

Heartbeat Status Query

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|XNames|[[XName.1.0.0](#schemaxname.1.0.0)]|false|none|List of component XNames to query for heartbeat status.|

<h2 id="tocS_hbstates_rsp">hbstates_rsp</h2>
<!-- backwards compatibility -->
<a id="schemahbstates_rsp"></a>
<a id="schema_hbstates_rsp"></a>
<a id="tocShbstates_rsp"></a>
<a id="tocshbstates_rsp"></a>

```json
{
  "HBStates": [
    {
      "XName": "x0c0s0b0n0",
      "Heartbeating": true
    }
  ]
}

```

Heartbeat Status Query Response

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|HBStates|[[hbstates_single_rsp](#schemahbstates_single_rsp)]|false|none|List of components' heartbeat status.|

<h2 id="tocS_hbstates_single_rsp">hbstates_single_rsp</h2>
<!-- backwards compatibility -->
<a id="schemahbstates_single_rsp"></a>
<a id="schema_hbstates_single_rsp"></a>
<a id="tocShbstates_single_rsp"></a>
<a id="tocshbstates_single_rsp"></a>

```json
{
  "XName": "x0c0s0b0n0",
  "Heartbeating": true
}

```

Heartbeat Status for a Component

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|XName|string|false|none|XName of a component|
|Heartbeating|boolean|false|none|Signifies if a component is actively heartbeating.|

<h2 id="tocS_params">params</h2>
<!-- backwards compatibility -->
<a id="schemaparams"></a>
<a id="schema_params"></a>
<a id="tocSparams"></a>
<a id="tocsparams"></a>

```json
{
  "Debug": "0",
  "Errtime": "10",
  "Warntime": "5",
  "Kv_url": "http://cray-hbtd-etcd-client:2379",
  "Interval": "5",
  "Nosm": "0",
  "Port": "8080",
  "Sm_retries": "3",
  "Sm_timeout": "5",
  "Sm_url": "http://cray-smd/v1/State/Components",
  "Telemetry_host": "10.2.3.4:9092:heartbeat_notifications",
  "Use_telemetry": "1"
}

```

Operational Parameters Message

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|Debug|string|false|none|This is the debug level of the heartbeat service. Debug parameter increases the verbosity of the logging.|
|Errtime|string|false|none|This is the timeout interval resulting in a missing heartbeat error. Allows you to change the max time elapsed since the last heatbeat received by a component before sending an ALERT to the HSM.|
|Warntime|string|false|none|This is the timeout interval resulting in a missing heartbeat warning. Allows you to change the max time elapsed since last heartbeat received by a component before sending a WARNING to the State Manager.|
|Kv_url|string|false|none|This is the URL of a Key/Value store service.|
|Interval|string|false|none|This is the time interval between heartbeat checks (in seconds).|
|Nosm|string|false|none|This enables/disables actual State Manager interaction.|
|Port|string|false|read-only|This is the port the heartbeat service listens on.|
|Sm_retries|string|false|none|This is the number of times to retry failed State Manager interactions.|
|Sm_timeout|string|false|none|This is max time (in seconds) to wait for a response from the HSM in any given interaction.|
|Sm_url|string|false|none|This is the State Manager URL|
|Telemetry_host|string|false|none|Telemetry bus host description (host:port:topic)|
|Use_telemetry|string|false|none|Turn on or off the ability to dump notifications of heartbeat state changes to the telemetry bus. If non-zero dump heartbeat change notifications onto the telemetry bus.|

<h2 id="tocS_XName.1.0.0">XName.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaxname.1.0.0"></a>
<a id="schema_XName.1.0.0"></a>
<a id="tocSxname.1.0.0"></a>
<a id="tocsxname.1.0.0"></a>

```json
"x0c1s2b0n3"

```

Identifies sender by xname. This is the physical, location-based name of a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Identifies sender by xname. This is the physical, location-based name of a component.|

<h2 id="tocS_Hostname.1.0.0">Hostname.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemahostname.1.0.0"></a>
<a id="schema_Hostname.1.0.0"></a>
<a id="tocShostname.1.0.0"></a>
<a id="tocshostname.1.0.0"></a>

```json
"x0c1s2b0n3.us.cray.com"

```

Identifies sender by hostname. This is the host name of a component.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Identifies sender by hostname. This is the host name of a component.|

<h2 id="tocS_NID.1.0.0">NID.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemanid.1.0.0"></a>
<a id="schema_NID.1.0.0"></a>
<a id="tocSnid.1.0.0"></a>
<a id="tocsnid.1.0.0"></a>

```json
"83"

```

Identifies sender by Numeric ID (NID). This is the Numeric ID of a compute node.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Identifies sender by Numeric ID (NID). This is the Numeric ID of a compute node.|

<h2 id="tocS_TimeStamp.1.0.0">TimeStamp.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schematimestamp.1.0.0"></a>
<a id="schema_TimeStamp.1.0.0"></a>
<a id="tocStimestamp.1.0.0"></a>
<a id="tocstimestamp.1.0.0"></a>

```json
"2018-07-06T12:34:56.012345-5Z"

```

When heartbeat was sent. This is an ISO8601 formatted time stamp.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|When heartbeat was sent. This is an ISO8601 formatted time stamp.|

<h2 id="tocS_HeartbeatStatus.1.0.0">HeartbeatStatus.1.0.0</h2>
<!-- backwards compatibility -->
<a id="schemaheartbeatstatus.1.0.0"></a>
<a id="schema_HeartbeatStatus.1.0.0"></a>
<a id="tocSheartbeatstatus.1.0.0"></a>
<a id="tocsheartbeatstatus.1.0.0"></a>

```json
"Kernel Oops"

```

Special status field for specific failure modes.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|*anonymous*|string|false|none|Special status field for specific failure modes.|

<h2 id="tocS_Error">Error</h2>
<!-- backwards compatibility -->
<a id="schemaerror"></a>
<a id="schema_Error"></a>
<a id="tocSerror"></a>
<a id="tocserror"></a>

```json
{
  "type": "string",
  "detail": "string",
  "instance": "string",
  "status": "string",
  "title": "string"
}

```

RFC 7807 compliant error payload.  All fields are optional except the 'type' field.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string|true|none|none|
|detail|string|false|none|none|
|instance|string|false|none|none|
|status|string|false|none|none|
|title|string|false|none|none|

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
  "status": 400,
  "title": "Description of HTTP Status code, e.g. 400"
}

```

RFC 7807 compliant error payload.  All fields are optional except the 'type' field.

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|type|string|true|none|none|
|detail|string|false|none|none|
|instance|string|false|none|none|
|status|number(int32)|false|none|none|
|title|string|false|none|none|

